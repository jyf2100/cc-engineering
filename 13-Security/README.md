# 第 19 讲：固若金汤 · Claude Code 安全最佳实践

> 在让 Claude 成为你的得力助手之前，先确保它不会成为安全漏洞的入口

---

## Q1: Claude Code 有哪些安全风险？

### 风险分类

| 风险类型 | 描述 | 严重程度 |
|----------|------|----------|
| **敏感数据泄露** | Claude 看到或输出密钥、密码 | 🔴 高 |
| **命令注入** | Claude 执行恶意命令 | 🔴 高 |
| **文件访问越权** | 访问不该访问的文件 | 🟡 中 |
| **权限过度** | 给 Claude 过多权限 | 🟡 中 |
| **供应链风险** | 恶意 MCP 服务器 | 🟡 中 |
| **日志泄露** | 敏感信息进入日志 | 🟢 低 |

### 攻击向量

```
用户输入
    │
    ▼
┌─────────────────┐
│   Prompt 注入   │ ← 恶意指令嵌入
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  工具调用滥用   │ ← 执行危险操作
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  敏感数据外泄   │ ← 输出包含密钥
└─────────────────┘
```

### 安全边界

```
┌─────────────────────────────────┐
│         Claude Code             │
│  ┌─────────────────────────┐   │
│  │   允许访问区域           │   │
│  │   - src/                │   │
│  │   - tests/              │   │
│  │   - docs/               │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │   禁止访问区域           │   │
│  │   - .env                │   │
│  │   - credentials/        │   │
│  │   - ~/.ssh/             │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## Q2: 如何保护敏感数据？

### 敏感文件识别

**常见敏感文件**：
```
.env                    # 环境变量
.env.local              # 本地环境变量
.env.production         # 生产环境变量
credentials.json        # 凭证文件
secrets.yaml            # 密钥配置
~/.ssh/id_rsa           # SSH 私钥
*.pem                   # 证书文件
*.key                   # 密钥文件
```

### 使用 Hooks 保护

```bash
#!/bin/bash
# pre-edit-protect.sh - 保护敏感文件

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 敏感文件模式
PROTECTED_PATTERNS=(
    "\.env$"
    "\.env\."
    "credentials"
    "\.pem$"
    "\.key$"
    "id_rsa"
    "secrets?\."
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" =~ $pattern ]]; then
        jq -n \
            --arg path "$FILE_PATH" \
            '{
                permissionDecision: "deny",
                permissionDecisionReason: "🔒 禁止修改敏感文件: \($path)"
            }'
        exit 0
    fi
done

exit 0
```

### CLAUDE.md 中的安全提醒

```markdown
# 安全规范

## 敏感文件（禁止访问）
- `.env*` 文件
- `credentials/` 目录
- `*.pem`, `*.key` 文件

## 代码中的敏感信息
- 不要硬编码 API Key
- 不要提交密码到 Git
- 使用环境变量存储密钥
```

### 输出过滤

```bash
#!/bin/bash
# post-tool-filter.sh - 过滤敏感输出

INPUT=$(cat)
OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""')

# 检测敏感模式
if echo "$OUTPUT" | grep -qE "(sk-ant-|AKIA|ghp_|xoxb-)"; then
    jq -n '{decision: "approve", reason: "检测到敏感信息，已过滤"}'
    # 实际实现中应该过滤敏感内容
fi

exit 0
```

---

## Q3: 如何限制 Claude 的权限？

### 最小权限原则

```
# 错误：给所有权限
用户：帮我做任何事情

# 正确：明确权限范围
用户：只读模式审查 src/ 目录的代码
```

### Agent 权限配置

```markdown
# 只读审查 Agent
---
name: security-reviewer
tools: Read, Grep, Glob  # 只给读权限
# 注意：没有 Edit, Write, Bash
---

你是一个安全审查专家，只负责发现问题，不负责修复。
```

```markdown
# 受限的 Bash 权限
---
name: test-runner
tools: Read, Bash(npm test), Bash(npm run *)
---

只能运行测试相关命令。
```

### Headless 权限控制

```bash
# 只读模式
claude -p "审查代码" \
  --allowedTools "Read,Grep,Glob" \
  --disallowedTools "Write,Edit,Bash"

# 受限写入模式
claude -p "修复 bug" \
  --allowedTools "Read,Edit,Bash(npm test)" \
  --max-turns 10
```

---

## Q4: 如何防止命令注入？

### 危险命令模式

```bash
# 危险命令列表
DANGEROUS_PATTERNS=(
    "rm -rf /"           # 删除根目录
    "rm -rf /*"          # 删除所有
    "curl .*|.*bash"     # 远程执行
    "wget .*|.*sh"       # 远程执行
    "eval "              # 动态执行
    "\$(.*)"             # 命令替换
    "DROP DATABASE"      # SQL 注入
    ":(){ :|:& };:"      # Fork 炸弹
)
```

### PreToolUse Hook 防护

```bash
#!/bin/bash
# pre-bash-security.sh - Bash 命令安全检查

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# 危险命令检测
DANGEROUS_PATTERNS=(
    "rm -rf /"
    "rm -rf /*"
    "rm -rf ~"
    "curl .*|.*bash"
    "wget .*|.*sh"
    "mkfs"
    "dd if=.*of=/dev/"
    "DROP DATABASE"
    "TRUNCATE TABLE"
    "chmod -R 777 /"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        jq -n \
            --arg cmd "$COMMAND" \
            --arg pattern "$pattern" \
            '{
                permissionDecision: "deny",
                permissionDecisionReason: "🚫 禁止执行危险命令，匹配模式: \($pattern)"
            }'
        exit 0
    fi
done

# 检查是否在允许的目录内
ALLOWED_DIRS=("/home/user/project" "/workspace")
for dir in "${ALLOWED_DIRS[@]}"; do
    if [[ "$COMMAND" == *"$dir"* ]]; then
        exit 0  # 允许
    fi
done

# 不在允许目录
jq -n '{
    permissionDecision: "deny",
    permissionDecisionReason": "不允许在当前目录执行命令"
}'
```

### 白名单策略

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/whitelist-check.sh"
          }
        ]
      }
    ]
  }
}
```

```bash
#!/bin/bash
# whitelist-check.sh - 白名单检查

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# 允许的命令白名单
ALLOWED_PATTERNS=(
    "^git status"
    "^git diff"
    "^git log"
    "^npm test"
    "^npm run"
    "^ls"
    "^cat"
    "^node"
)

for pattern in "${ALLOWED_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        exit 0  # 允许
    fi
done

# 不在白名单
jq -n '{
    permissionDecision: "deny",
    permissionDecisionReason": "命令不在白名单中"
}'
```

---

## Q5: 如何安全使用 MCP？

### MCP 安全风险

| 风险 | 描述 | 防护措施 |
|------|------|----------|
| 恶意服务器 | 执行危险操作 | 只安装可信来源 |
| 数据泄露 | 服务器收集敏感信息 | 审查服务器代码 |
| 权限过度 | 服务器权限过大 | 限制访问范围 |

### MCP 安全实践

1. **使用官方/可信服务器**
   ```bash
   # 推荐：官方服务器
   claude mcp add --transport http github https://api.githubcopilot.com/mcp/

   # 谨慎：第三方服务器
   # 先审查代码再安装
   ```

2. **审查服务器权限**
   ```json
   {
     "mcpServers": {
       "database": {
         "command": "uvx",
         "args": ["mcp-server-postgres"],
         "env": {
           "DATABASE_URL": "${READONLY_DB_URL}"  // 使用只读连接
         }
       }
     }
   }
   ```

3. **隔离敏感数据**
   ```json
   {
     "mcpServers": {
       "api": {
         "type": "http",
         "url": "https://api.example.com/mcp",
         "headers": {
           "Authorization": "Bearer ${API_KEY}"  // 使用环境变量
         }
       }
     }
   }
   ```

### MCP Hook 监控

```bash
#!/bin/bash
# pre-mcp-monitor.sh - MCP 调用监控

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# 记录 MCP 调用
echo "$(date) - MCP Call: $TOOL_NAME" >> ~/.claude/mcp-audit.log

# 检查是否是敏感 MCP 工具
if [[ "$TOOL_NAME" == mcp__database__write* ]]; then
    jq -n '{
        permissionDecision: "ask",
        permissionDecisionReason": "数据库写入操作需要确认"
    }'
fi

exit 0
```

---

## Q6: 如何安全处理日志？

### 日志脱敏

```bash
#!/bin/bash
# log-sanitizer.sh - 日志脱敏

sanitize() {
    local text="$1"
    # 替换 API Key
    text=$(echo "$text" | sed -E 's/sk-ant-[a-zA-Z0-9]{20,}/sk-ant-****/g')
    # 替换密码
    text=$(echo "$text" | sed -E 's/password["\s:=]+["\x27]?[^"\s\x27]+/password=****/gi')
    echo "$text"
}

# 使用
LOG=$(cat)
sanitize "$LOG" >> /var/log/claude-safe.log
```

### 避免敏感信息进入日志

1. **不在 Prompt 中包含敏感信息**
   ```
   # 危险
   用户：用密码 mySecretPass123 连接数据库

   # 安全
   用户：用环境变量 DB_PASSWORD 连接数据库
   ```

2. **配置日志级别**
   ```json
   {
     "logging": {
       "level": "warn",  // 只记录警告和错误
       "redact": ["password", "token", "key"]
     }
   }
   ```

---

## Q7: 如何建立安全审计流程？

### 审计清单

- [ ] **敏感文件保护**：Hooks 禁止访问 `.env` 等文件
- [ ] **命令白名单**：只允许安全的 Bash 命令
- [ ] **最小权限**：Agent 只有所需的最小权限
- [ ] **MCP 审查**：只安装可信的 MCP 服务器
- [ ] **日志脱敏**：敏感信息不出现在日志中
- [ ] **定期审计**：定期检查 Claude 的操作记录

### 安全审查 Agent

```markdown
# .claude/agents/security-auditor.md
---
name: security-auditor
description: 审查代码和配置的安全问题
tools: Read, Grep, Glob
model: sonnet
---

你是一个安全审查专家。检查以下内容：

1. **硬编码敏感信息**
   - API Key、密码、Token
   - 私钥文件内容

2. **危险配置**
   - 过度的权限设置
   - 不安全的 Hook 配置

3. **代码安全问题**
   - SQL 注入风险
   - XSS 漏洞
   - 不安全的依赖

输出格式：
- 严重程度：高/中/低
- 问题描述
- 修复建议
```

### 定期安全扫描

```yaml
# .github/workflows/security-scan.yml
name: Claude Security Scan

on:
  schedule:
    - cron: '0 0 * * 0'  # 每周日

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Security Audit
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "对项目进行安全审计，检查敏感信息泄露、危险配置、代码漏洞" \
            --allowedTools "Read,Grep,Glob" \
            --output-format json > security-report.json

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: security-report
          path: security-report.json
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-security-audit** | 安全审计 | 敏感数据检测、漏洞扫描 |
| **02-data-protection** | 数据保护 | Hooks 防护、权限控制 |

---

## 参考资源

- [Claude Code 安全指南](https://docs.anthropic.com/en/docs/claude-code/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Prompt Injection Defense](https://www.anthropic.com/research/prompt-injection-defense)

---

## 总结

| 问题 | 答案 |
|------|------|
| 安全风险有哪些？ | 数据泄露、命令注入、越权访问、供应链风险 |
| 如何保护敏感数据？ | Hooks 拦截、CLAUDE.md 提醒、输出过滤 |
| 如何限制权限？ | 最小权限原则、Agent 权限配置、Headless 控制 |
| 如何防止命令注入？ | 危险命令检测、白名单策略 |
| 如何安全使用 MCP？ | 可信来源、权限审查、环境变量 |
| 如何处理日志？ | 日志脱敏、避免敏感信息、配置日志级别 |
| 如何建立审计？ | 审计清单、安全 Agent、定期扫描 |
