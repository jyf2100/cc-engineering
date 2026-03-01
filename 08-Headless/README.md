# 第 8 讲：无人值守 · Headless 模式与 CI/CD 集成

> 让 Claude Code 在 GitHub Actions 中静默运行——从交互式到全自动的工程化转型

---

## Q1: Headless 模式是什么？

### Headless 的定义

**Headless 模式**是 Claude Code 的非交互式运行方式，通过 `-p` 参数启动。在这种模式下：
- 不需要用户交互
- 输出可被程序解析
- 适合 CI/CD 流水线

### 核心价值

```
交互模式：
  用户 ↔ Claude Code ↔ 用户确认 → 执行

Headless 模式：
  CI 触发 → Claude Code → 自动执行 → 输出结果
```

### 在 Claude Code 技术栈中的位置

```
Claude Code 使用方式
├── 交互模式（Interactive）
│   └── 终端中对话式使用
│
└── Headless 模式（非交互）  ← 这里：自动化场景
    ├── CI/CD 流水线
    ├── 定时任务
    ├── Webhook 触发
    └── 脚本调用
```

### 典型应用场景

| 场景 | 描述 |
|------|------|
| **PR 审查** | 自动审查代码变更，发表评论 |
| **Issue 处理** | 自动分析 Issue，生成修复 PR |
| **安全审计** | 定时扫描代码，发现安全问题 |
| **文档生成** | 代码变更后自动更新文档 |
| **测试修复** | 测试失败后自动尝试修复 |

---

## Q2: 核心 CLI 选项有哪些？

### 基础命令

```bash
# 非交互模式（必需）
claude -p "你的 prompt"

# 或使用长格式
claude --print "你的 prompt"
```

### 核心选项一览

| Flag | 描述 | 示例 |
|------|------|------|
| `-p, --print` | 非交互模式 | `claude -p "query"` |
| `--output-format` | 输出格式 | `--output-format json` |
| `--allowedTools` | 预授权工具 | `--allowedTools "Bash(git *),Read"` |
| `--disallowedTools` | 禁止工具 | `--disallowedTools "Write"` |
| `--json-schema` | JSON Schema 约束 | `--json-schema '{"type":"object"}'` |
| `--max-turns` | 限制迭代轮次 | `--max-turns 5` |
| `--continue, -c` | 继续最近对话 | `claude -c` |
| `--resume, -r` | 恢复指定会话 | `--resume abc123` |
| `--system-prompt` | 覆盖系统提示 | `--system-prompt "..."` |
| `--append-system-prompt` | 追加系统提示 | `--append-system-prompt "..."` |
| `--mcp-config` | 加载 MCP 配置 | `--mcp-config servers.json` |

### 组合示例

```bash
# 完整的 CI 审查命令
claude -p "Review the code changes for security issues" \
  --allowedTools "Read,Grep,Glob,Bash(git diff*)" \
  --output-format json \
  --max-turns 10

# 带自定义系统提示
claude -p "Fix the failing tests" \
  --system-prompt "You are a test fixer. Always run tests after making changes." \
  --allowedTools "Read,Edit,Write,Bash(npm test*)" \
  --max-turns 15
```

---

## Q3: 输出格式有哪些？

### 三种输出格式

| 格式 | 描述 | 用途 |
|------|------|------|
| `text` | 纯文本（默认） | 简单查询、日志查看 |
| `json` | 结构化 JSON | 程序化处理 |
| `stream-json` | 逐行 JSON 流 | 实时处理、进度显示 |

### text 格式

```bash
claude -p "Summarize this project"
```

输出就是纯文本，适合直接显示或记录日志。

### json 格式

```bash
claude -p "Summarize this project" --output-format json
```

输出结构：

```json
{
  "result": "这是一个 Node.js 项目...",
  "session_id": "abc123",
  "cost_usd": 0.05,
  "duration_ms": 3000,
  "is_error": false,
  "structured_output": {}
}
```

### stream-json 格式

```bash
claude -p "Explain the codebase" --output-format stream-json --verbose
```

逐行输出：

```json
{"type": "init", "session_id": "abc123"}
{"type": "user", "content": "Explain the codebase"}
{"type": "assistant", "content": "Let me explore..."}
{"type": "tool_use", "name": "Glob", "input": {...}}
{"type": "tool_result", "output": "..."}
{"type": "result", "result": "...", "cost_usd": 0.05}
```

### 解析 JSON 输出

```bash
# 提取结果
RESULT=$(claude -p "Review code" --output-format json | jq -r '.result')

# 检查是否出错
claude -p "Fix bug" --output-format json | jq -e '.is_error' && echo "Failed"

# 获取成本
claude -p "Analyze" --output-format json | jq '.cost_usd'
```

---

## Q4: allowedTools 语法是什么？

### 基本语法

```bash
# 空格分隔多个工具
--allowedTools "Bash Read Edit"

# 逗号分隔（也支持）
--allowedTools "Bash,Read,Edit"
```

### 带参数限制

```bash
# 限制 Bash 只能执行特定命令
--allowedTools "Bash(git status),Bash(git diff*),Bash(npm test)"

# 前缀匹配（注意空格）
--allowedTools "Bash(git diff *)"   # 匹配 "git diff" 开头
--allowedTools "Bash(git diff*)"    # 也匹配 "git diff-index"
```

### 常用工具组合

| 场景 | allowedTools |
|------|--------------|
| 只读分析 | `Read,Grep,Glob,Bash(git *)` |
| 代码修改 | `Read,Edit,Write,Grep,Glob` |
| 测试修复 | `Read,Edit,Bash(npm test*),Bash(npm run*)` |
| PR 审查 | `Read,Grep,Glob,Bash(git diff*)` |
| 安全审计 | `Read,Grep,Glob` |

### disallowedTools

```bash
# 禁止写入操作
--disallowedTools "Write"

# 组合使用：允许读取，禁止修改
--allowedTools "Read,Grep,Glob" --disallowedTools "Write,Edit"
```

---

## Q5: 如何管理会话？

### 继续最近会话

```bash
# 继续上一次对话
claude -c

# 或
claude --continue
```

### 恢复指定会话

```bash
# 通过 session_id 恢复
claude -r abc123

# 或
claude --resume abc123
```

### 会话 ID 获取

```bash
# 从 JSON 输出获取
SESSION_ID=$(claude -p "Analyze" --output-format json | jq -r '.session_id')

# 后续使用
claude -r "$SESSION_ID" -p "Continue analysis"
```

### 多阶段任务

```bash
# 阶段 1：分析
claude -p "Analyze the bug" --output-format json > analysis.json

# 阶段 2：基于分析结果修复
SESSION=$(jq -r '.session_id' analysis.json)
claude -r "$SESSION" -p "Now fix it based on your analysis"
```

---

## Q6: 如何集成 GitHub Actions？

### 基础工作流

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Claude Code
        run: |
          npm install -g @anthropic-ai/claude-code

      - name: Run Claude Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review this PR for security and quality issues" \
            --allowedTools "Read,Grep,Glob,Bash(git diff*)" \
            --output-format json > review_result.json

      - name: Post Comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const result = JSON.parse(fs.readFileSync('review_result.json', 'utf8'));
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: result.result
            });
```

### 安全最佳实践

```yaml
# 1. API Key 使用 Secrets
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

# 2. 限制工具权限
--allowedTools "Read,Grep,Glob"  # 只读
--disallowedTools "Write,Edit"   # 禁止修改

# 3. 限制迭代次数
--max-turns 5

# 4. 使用 JSON Schema 约束输出
--json-schema '{"type":"object","properties":{"issues":{"type":"array"}}}'
```

### 常见 CI 场景

| 场景 | 触发条件 | Prompt 示例 |
|------|----------|-------------|
| PR 审查 | pull_request | "Review this PR for security issues" |
| Issue 处理 | issues | "Analyze this issue and propose a solution" |
| 定时审计 | schedule | "Scan codebase for security vulnerabilities" |
| 测试修复 | workflow_call | "Fix the failing tests in the test report" |

---

## Q7: 安全实践有哪些？

### API Key 管理

```yaml
# 正确：使用 GitHub Secrets
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

# 错误：硬编码
env:
  ANTHROPIC_API_KEY: "sk-ant-xxxxx"  # ❌ 永远不要这样做
```

### 权限最小化

```bash
# 原则：只给完成任务所需的最小权限

# 审查任务：只读
--allowedTools "Read,Grep,Glob"

# 修复任务：允许修改，但限制范围
--allowedTools "Read,Edit,Bash(npm test)"

# 危险操作：永远禁止
--disallowedTools "Bash(rm*),Bash(git push --force)"
```

### 输出验证

```bash
# 验证 JSON 输出
RESULT=$(claude -p "..." --output-format json)

# 检查是否成功
if echo "$RESULT" | jq -e '.is_error == true' > /dev/null; then
  echo "Claude failed"
  exit 1
fi
```

### 成本控制

```bash
# 限制迭代次数
--max-turns 5

# 使用更便宜的模型（如果支持）
# 注意：Claude Code 默认使用配置的模型

# 监控成本
claude -p "..." --output-format json | jq '.cost_usd'
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-auto-review-ci** | 自动代码审查 | GitHub Actions + PR 审查 |
| **02-issue-fixer** | Issue 自动修复 | Issue 分析 + PR 生成 |

---

## 参考资源

- [Headless 官方文档](https://docs.anthropic.com/en/docs/claude-code/headless)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Claude Code 最佳实践](https://www.anthropic.com/engineering/claude-code-best-practices)

---

## 总结

| 问题 | 答案 |
|------|------|
| Headless 是什么？ | 非交互模式，适合 CI/CD 自动化 |
| 核心 CLI 选项？ | `-p`、`--output-format`、`--allowedTools`、`--max-turns` |
| 输出格式有哪些？ | text（纯文本）、json（结构化）、stream-json（流式） |
| allowedTools 语法？ | 空格/逗号分隔，支持参数限制如 `Bash(git *)` |
| 如何管理会话？ | `--continue` 继续、`--resume <id>` 恢复 |
| 安全实践？ | Secrets 管理、权限最小化、输出验证、成本控制 |
