# Claude Code 工程化实战 · 06-10 章内容建议（官方文档对齐版）

> **研究日期**: 2026-03-01
> **基于**: Claude Code 官方文档 (docs.anthropic.com/code.claude.com)
> **参考**: 仓库前 5 章风格延续

---

## 官方文档参考链接

| 章节 | 官方文档 |
|------|----------|
| Hooks | https://docs.anthropic.com/en/docs/claude-code/hooks |
| MCP | https://docs.anthropic.com/en/docs/claude-code/mcp |
| Headless | https://docs.anthropic.com/en/docs/claude-code/headless |
| Agent SDK | https://docs.anthropic.com/en/docs/claude-code/sdk |
| Plugins | https://docs.anthropic.com/en/docs/claude-code/plugins |

---

## 第 6 讲：未雨绸缪 · Hooks 事件驱动自动化

### 6.1 官方文档核心要点

**10 种 Hook 事件**（按使用频率排序）：

| Hook 事件 | 触发时机 | 核心用途 | 可阻断 |
|-----------|----------|----------|--------|
| **PreToolUse** | 工具执行前 | 拦截/修改工具调用 | ✅ exit code 2 |
| **PostToolUse** | 工具执行后 | 后处理、日志、验证 | ❌ |
| **Stop** | 主 Agent 完成响应时 | 清理任务、继续任务 | ✅ |
| **UserPromptSubmit** | 用户提交 prompt 后 | 预处理用户输入 | ✅ |
| **Notification** | Claude 发送通知时 | 自定义通知处理 | ❌ |
| **SubagentStop** | 子代理完成时 | 处理子代理结果 | ✅ |
| **PreCompact** | 上下文压缩前 | 自定义压缩规则 | ❌ |
| **SessionStart** | 会话开始时 | 加载开发上下文 | ❌ |
| **SessionEnd** | 会话结束时 | 清理、保存状态 | ❌ |
| **PermissionRequest** | 权限对话框出现时 | 自动审批/拒绝 | ✅ |

### 6.2 官方配置结构

**配置文件位置**：
```
~/.claude/settings.json      # 用户级
.claude/settings.json        # 项目级
.claude/settings.local.json  # 本地项目级（不提交）
```

**settings.json 结构**：
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-bash.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$FILE_PATH\""
          }
        ]
      }
    ]
  }
}
```

**Matcher 规则**：
- 精确匹配：`Write` 匹配 Write 工具
- 正则表达式：`Edit|Write` 或 `Notebook.*`
- 通配符：`*` 匹配所有工具
- 空字符串或留空也匹配所有

### 6.3 Exit Code 语义（官方）

| Exit Code | 含义 | 行为 |
|-----------|------|------|
| **0** | 成功 | stdout 显示给用户（transcript 模式） |
| **2** | 阻断 | stderr 反馈给 Claude 自动处理 |
| **其他** | 非阻断错误 | stderr 显示给用户，继续执行 |

**Exit Code 2 的阻断行为**：

| Hook 事件 | 行为 |
|-----------|------|
| PreToolUse | 阻止工具调用，stderr 给 Claude |
| PostToolUse | stderr 给 Claude（工具已执行） |
| UserPromptSubmit | 阻止 prompt 处理，清空 prompt |
| Stop/SubagentStop | 阻止停止，stderr 给 Claude |
| 其他事件 | N/A，仅显示给用户 |

### 6.4 Hook Input/Output（官方 JSON Schema）

**PreToolUse Input**：
```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /",
    "description": "删除根目录"
  }
}
```

**PreToolUse Output (JSON 格式)**：
```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "禁止执行危险命令：删除根目录",
  "continue": true
}
```

**permissionDecision 值**：
- `"allow"` - 绕过权限系统
- `"deny"` - 阻止工具调用
- `"ask"` - 要求用户确认

### 6.5 实战项目建议

#### 项目 1：安全卫士 Hook（06-security-hooks）

```
06-security-hooks/
├── README.md
├── .claude/
│   └── settings.json           # Hook 配置
├── hooks/
│   ├── pre-bash-security.sh    # Bash 命令安全检查
│   ├── pre-edit-protect.sh     # 敏感文件保护
│   ├── post-write-lint.sh      # 写入后自动格式化
│   └── stop-continue.sh        # 阻止过早停止
└── test-cases/
    └── dangerous-operations.md
```

**pre-bash-security.sh 示例**：
```bash
#!/bin/bash
# 读取 stdin JSON
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# 危险命令模式
DANGEROUS_PATTERNS=(
    "rm -rf /"
    "rm -rf /*"
    "mkfs"
    "dd if=.*of=/dev/"
    ":(){ :|:& };:"
    "curl .* | bash"
    "wget .* | sh"
    "chmod -R 777 /"
    "DROP DATABASE"
    "TRUNCATE TABLE"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        # 输出 JSON 格式的阻断响应
        jq -n \
            --arg reason "🚫 安全策略：禁止执行危险命令 - $pattern" \
            '{permissionDecision: "deny", permissionDecisionReason: $reason}'
        exit 0  # JSON 输出时，exit code 被忽略
    fi
done

# 允许执行
exit 0
```

#### 项目 2：质量门禁 Hook（06-quality-gates）

```
06-quality-gates/
├── README.md
├── .claude/
│   └── settings.json
├── hooks/
│   ├── post-edit-prettier.sh   # 自动格式化
│   ├── post-write-test.sh      # 触发相关测试
│   ├── user-prompt-context.sh  # 自动添加上下文
│   └── session-start-context.sh # 启动时加载上下文
└── sample-project/
```

**session-start-context.sh 示例**（加载最近的 Git 变更）：
```bash
#!/bin/bash
# SessionStart Hook - 加载开发上下文

# 获取最近的提交和变更
RECENT_CHANGES=$(git log --oneline -5 2>/dev/null || echo "Not a git repo")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# 输出 JSON 格式的附加上下文
jq -n \
    --arg changes "$RECENT_CHANGES" \
    --arg branch "$CURRENT_BRANCH" \
    '{
        hookSpecificOutput: {
            additionalContext: "## 开发上下文\n\n当前分支: \($branch)\n\n最近提交:\n\($changes)"
        }
    }'
```

#### 项目 3：MCP 工具 Hook（06-mcp-hooks）

```
06-mcp-hooks/
├── README.md
├── .claude/
│   └── settings.json           # MCP 工具匹配
└── hooks/
    ├── pre-mcp-github.sh       # GitHub MCP 控制
    └── pre-mcp-database.sh     # 数据库 MCP 控制
```

**MCP 工具 Matcher 规则**：
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__github__*",
        "hooks": [{ "type": "command", "command": "..."}]
      },
      {
        "matcher": "mcp__database__write*",
        "hooks": [{ "type": "command", "command": "..."}]
      }
    ]
  }
}
```

### 6.6 章节知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **6.1 Hooks 概述** | 10 种 Hook 类型、生命周期、执行顺序 | ⭐ |
| **6.2 Exit Code 语义** | 0/2/其他的含义、阻断行为 | ⭐⭐ |
| **6.3 JSON 输出格式** | permissionDecision、decision、continue | ⭐⭐⭐ |
| **6.4 Matcher 规则** | 精确匹配、正则、MCP 工具 | ⭐⭐ |
| **6.5 实战：安全钩子** | PreToolUse 拦截危险命令 | ⭐⭐⭐ |
| **6.6 实战：质量钩子** | PostToolUse 自动格式化、测试 | ⭐⭐⭐ |
| **6.7 调试技巧** | `/hooks` 命令、`--debug` 模式 | ⭐⭐ |

---

## 第 7 讲：海纳百川 · MCP 协议与外部工具连接

### 7.1 官方文档核心要点

**三种传输类型**：

| 类型 | 适用场景 | 命令示例 |
|------|----------|----------|
| **HTTP** | 云端服务（推荐） | `claude mcp add --transport http notion https://mcp.notion.com/mcp` |
| **SSE** | Server-Sent Events | `claude mcp add --transport sse asana https://mcp.asana.com/sse` |
| **stdio** | 本地进程 | `claude mcp add --transport stdio db -- npx -y @bytebase/dbhub --dsn "..."` |

**三种配置 Scope**：

| Scope | 存储位置 | 共享范围 |
|-------|----------|----------|
| **local** | `~/.claude.json` (项目路径下) | 仅当前项目、仅自己 |
| **project** | `.mcp.json` (项目根目录) | 团队共享（提交到 git） |
| **user** | `~/.claude.json` | 跨项目、仅自己 |

### 7.2 官方 CLI 命令

```bash
# 添加 MCP 服务器
claude mcp add --transport http <name> <url>
claude mcp add --transport sse <name> <url>
claude mcp add --transport stdio <name> -- <command> [args...]

# 带 scope
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/

# 带认证
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"

# 管理
claude mcp list                  # 列出所有服务器
claude mcp get <name>            # 查看详情
claude mcp remove <name>         # 移除
/mcp                             # 在 Claude Code 内查看状态
```

### 7.3 .mcp.json 配置格式

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    },
    "database": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub"],
      "env": {
        "DB_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

**环境变量扩展**：
- `${VAR}` - 展开为环境变量值
- `${VAR:-default}` - 带默认值

```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

### 7.4 热门 MCP 服务器（官方推荐）

| 服务器 | 功能 | 传输类型 |
|--------|------|----------|
| **GitHub** | PR/Issue/仓库操作 | HTTP |
| **Notion** | 文档和数据库 | HTTP |
| **Sentry** | 错误监控 | HTTP |
| **PostgreSQL** | 数据库查询 | stdio |
| **SQLite** | 本地数据库 | stdio |
| **Filesystem** | 文件系统扩展 | stdio |

### 7.5 实战项目建议

#### 项目 1：数据库助手 MCP（07-database-mcp）

```
07-database-mcp/
├── README.md
├── .mcp.json                    # 项目级 MCP 配置
├── database/
│   └── sample.db
├── queries/
│   └── examples.md
└── scripts/
    └── setup-db.sh
```

**.mcp.json 示例**：
```json
{
  "mcpServers": {
    "sqlite": {
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "${CLAUDE_PROJECT_DIR}/database/sample.db"]
    }
  }
}
```

#### 项目 2：开发工具链 MCP（07-dev-tools-mcp）

```
07-dev-tools-mcp/
├── README.md
├── .mcp.json
├── workflows/
│   ├── issue-to-pr.md
│   ├── error-debug.md
│   └── code-review.md
└── examples/
```

**.mcp.json 示例**：
```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    }
  }
}
```

#### 项目 3：自定义 MCP Server（07-custom-mcp）

```
07-custom-mcp/
├── README.md
├── my-mcp-server/
│   ├── package.json
│   ├── index.js
│   └── tools/
│       ├── query.js
│       └── analyze.js
├── .mcp.json
└── examples/
```

### 7.6 章节知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **7.1 MCP 概述** | 协议设计、Client-Server 模型 | ⭐ |
| **7.2 三种传输类型** | HTTP/SSE/stdio 区别与选择 | ⭐ |
| **7.3 配置 Scope** | local/project/user 层级 | ⭐⭐ |
| **7.4 CLI 命令** | add/list/remove/get | ⭐ |
| **7.5 .mcp.json 格式** | 配置结构、环境变量 | ⭐⭐ |
| **7.6 实战：数据库** | SQLite/PostgreSQL 连接 | ⭐⭐⭐ |
| **7.7 实战：云服务** | GitHub/Sentry 集成 | ⭐⭐⭐ |
| **7.8 企业配置** | allowlist/denylist 控制 | ⭐⭐⭐ |

---

## 第 8 讲：无人值守 · Headless 模式与 CI/CD 集成

### 8.1 官方文档核心要点

**基础 CLI 命令**：
```bash
# 非交互模式
claude -p "Find and fix the bug in auth.py"

# 带工具授权
claude -p "Run tests and fix failures" --allowedTools "Bash,Read,Edit"

# 带输出格式
claude -p "Summarize this project" --output-format json

# 流式输出
claude -p "Explain recursion" --output-format stream-json --verbose
```

### 8.2 输出格式（官方）

| 格式 | 描述 | 用途 |
|------|------|------|
| `text` | 纯文本（默认） | 简单查询 |
| `json` | 结构化 JSON | 程序化处理 |
| `stream-json` | 逐行 JSON 流 | 实时处理 |

**JSON 输出格式**：
```json
{
  "result": "响应文本",
  "session_id": "abc123",
  "cost_usd": 0.05,
  "duration_ms": 3000,
  "is_error": false,
  "structured_output": {}
}
```

**stream-json 格式**：
```json
{"type": "init", "session_id": "abc123"}
{"type": "user", "content": "..."}
{"type": "assistant", "content": "..."}
{"type": "result", "result": "...", "cost_usd": 0.05}
```

### 8.3 核心 CLI 选项（官方）

| Flag | 描述 | 示例 |
|------|------|------|
| `-p, --print` | 非交互模式 | `claude -p "query"` |
| `--output-format` | 输出格式 | `--output-format json` |
| `--json-schema` | JSON Schema 约束 | `--json-schema '{"type":"object"}'` |
| `--allowedTools` | 预授权工具 | `--allowedTools "Bash(git *),Read"` |
| `--disallowedTools` | 禁止工具 | `--disallowedTools "Write"` |
| `--continue, -c` | 继续最近对话 | `claude -c` |
| `--resume, -r` | 恢复指定会话 | `--resume abc123` |
| `--max-turns` | 限制迭代轮次 | `--max-turns 5` |
| `--system-prompt` | 覆盖系统提示 | `--system-prompt "..."` |
| `--append-system-prompt` | 追加系统提示 | `--append-system-prompt "..."` |
| `--mcp-config` | 加载 MCP 配置 | `--mcp-config servers.json` |

### 8.4 allowedTools 语法（官方）

```bash
# 空格分隔
--allowedTools "Bash Read Edit"

# 逗号分隔
--allowedTools "Bash(npm install),Bash(git commit)"

# 前缀匹配（注意空格）
--allowedTools "Bash(git diff *)"   # 匹配 "git diff" 开头的命令
--allowedTools "Bash(git diff*)"    # 也匹配 "git diff-index"
```

### 8.5 实战项目建议

#### 项目 1：自动代码审查 CI（08-auto-review-ci）

```
08-auto-review-ci/
├── README.md
├── .github/
│   └── workflows/
│       ├── claude-review.yml      # PR 审查
│       └── claude-security.yml    # 安全审查
├── prompts/
│   ├── review-prompt.md
│   └── security-prompt.md
└── scripts/
    └── apply-suggestions.sh
```

**GitHub Actions 工作流**：
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

      - name: Get changed files
        run: |
          echo "CHANGED_FILES=$(git diff --name-only ${{ github.event.pull_request.base.sha }} ${{ github.sha }} | tr '\n' ' ')" >> $GITHUB_ENV

      - name: Claude Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review these changed files for security and quality: $CHANGED_FILES" \
            --allowedTools "Read,Grep,Glob" \
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

#### 项目 2：Issue 自动修复（08-issue-fixer）

```
08-issue-fixer/
├── README.md
├── .github/
│   └── workflows/
│       └── issue-to-pr.yml
├── prompts/
│   └── fix-prompt.md
└── safety/
    └── allowed-files.txt
```

#### 项目 3：夜间安全审计（08-nightly-audit）

```
08-nightly-audit/
├── README.md
├── .github/
│   └── workflows/
│       └── security-audit.yml
└── reports/
    └── template.md
```

### 8.6 章节知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **8.1 Headless 概述** | 非交互模式、适用场景 | ⭐ |
| **8.2 CLI 选项** | `-p`、`--output-format` 等 | ⭐ |
| **8.3 输出格式** | text/json/stream-json | ⭐⭐ |
| **8.4 工具授权** | `--allowedTools` 语法 | ⭐⭐ |
| **8.5 会话管理** | `--continue`、`--resume` | ⭐⭐ |
| **8.6 GitHub Actions** | 官方 Action 集成 | ⭐⭐⭐ |
| **8.7 安全实践** | API Key 管理、权限控制 | ⭐⭐⭐ |

---

## 第 9 讲：庖丁解牛 · Agent SDK 基础与高级应用

### 9.1 官方文档核心要点

**SDK 包**：
- **Python**: `pip install claude-code-sdk`（需 Python 3.10+）
- **TypeScript**: `npm install @anthropic-ai/claude-code`（需 Node.js 18+）

**两种使用方式**：
1. **CLI 方式**: `claude -p "..."` （已在第 8 讲覆盖）
2. **编程方式**: Python/TypeScript 包（本讲重点）

### 9.2 Python SDK 示例

```python
import asyncio
from claude_code_sdk import query, ClaudeCodeOptions

async def main():
    # 单次查询
    result = await query(
        "Analyze the auth.py file for security issues",
        options=ClaudeCodeOptions(
            allowed_tools=["Read", "Grep"],
            output_format="json"
        )
    )
    print(result)

asyncio.run(main())
```

### 9.3 TypeScript SDK 示例

```typescript
import { query, ClaudeCodeOptions } from '@anthropic-ai/claude-code';

async function main() {
  const result = await query(
    "Review the codebase structure",
    {
      allowedTools: ["Read", "Glob", "Grep"],
      outputFormat: "json"
    }
  );
  console.log(result);
}

main();
```

### 9.4 核心 SDK 选项

| 选项 | 类型 | 描述 |
|------|------|------|
| `allowedTools` | string[] | 预授权工具 |
| `disallowedTools` | string[] | 禁止工具 |
| `outputFormat` | string | text/json/stream-json |
| `systemPrompt` | string | 覆盖系统提示 |
| `appendSystemPrompt` | string | 追加系统提示 |
| `mcpConfig` | string | MCP 配置文件路径 |
| `maxTurns` | number | 最大迭代轮次 |
| `resume` | string | 恢复会话 ID |
| `continue` | boolean | 继续最近会话 |

### 9.5 消息 Schema（官方）

```typescript
interface Message {
  type: "user" | "assistant" | "system";
  content: string | ContentBlock[];
  role: "user" | "assistant";
}

interface ContentBlock {
  type: "text" | "tool_use" | "tool_result";
  text?: string;
  name?: string;
  input?: any;
  content?: string;
}
```

### 9.6 实战项目建议

#### 项目 1：测试修复 Agent（09-test-fixer-agent）

```
09-test-fixer-agent/
├── README.md
├── src/
│   ├── agent/
│   │   ├── __init__.py
│   │   ├── test_analyzer.py
│   │   └── code_fixer.py
│   └── main.py
├── pyproject.toml
└── examples/
    └── sample-failing-tests/
```

#### 项目 2：代码审查 Bot（09-review-bot）

```
09-review-bot/
├── README.md
├── src/
│   ├── bot/
│   │   ├── github_client.py
│   │   ├── reviewer.py
│   │   └── commenter.py
│   └── main.py
├── config/
│   └── review_rules.yaml
└── tests/
```

### 9.7 章节知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **9.1 SDK 概述** | CLI vs 编程方式 | ⭐ |
| **9.2 Python SDK** | 安装、query() 函数 | ⭐⭐ |
| **9.3 TypeScript SDK** | 安装、类型定义 | ⭐⭐ |
| **9.4 SDK 选项** | allowedTools、outputFormat 等 | ⭐⭐ |
| **9.5 消息 Schema** | Message、ContentBlock 类型 | ⭐⭐⭐ |
| **9.6 实战：测试修复** | 完整 Agent 实现 | ⭐⭐⭐⭐ |
| **9.7 最佳实践** | 错误处理、超时、成本控制 | ⭐⭐⭐ |

---

## 第 10 讲：化零为整 · Plugins 插件打包与分发

### 10.1 官方文档核心要点

**Plugin 结构**：
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # 插件清单（必需）
├── commands/                 # 斜杠命令（可选）
│   └── hello.md
├── agents/                   # 子代理（可选）
│   └── helper.md
├── skills/                   # Skills（可选）
│   └── my-skill/
│       └── SKILL.md
├── hooks/                    # Hooks（可选）
│   └── hooks.json
└── .mcp.json                 # MCP 服务器（可选）
```

### 10.2 plugin.json 结构

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "插件描述",
  "author": "your-name",
  "repository": "https://github.com/your-org/my-plugin",
  "keywords": ["code-review", "automation"],

  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

**环境变量**：
- `${CLAUDE_PLUGIN_ROOT}` - 插件根目录路径

### 10.3 Plugin CLI 命令

```bash
# 打开插件管理界面
/plugin

# 安装插件
/plugin install plugin-name@marketplace-name

# 从 Git 安装
/plugin install github:your-org/your-plugin

# 启用/禁用
/plugin enable plugin-name@marketplace-name
/plugin disable plugin-name@marketplace-name

# 卸载
/plugin uninstall plugin-name@marketplace-name

# 添加 marketplace
/plugin marketplace add your-org/claude-plugins
```

### 10.4 团队 Plugin 配置

**.claude/settings.json（项目级）**：
```json
{
  "plugins": {
    "marketplaces": [
      "your-org/claude-plugins"
    ],
    "enabled": [
      "formatter@your-org",
      "reviewer@your-org"
    ]
  }
}
```

### 10.5 实战项目建议

#### 项目 1：代码质量 Plugin（10-code-quality-plugin）

```
10-code-quality-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── review.md
│   ├── lint.md
│   └── test.md
├── agents/
│   └── quality-guard.md
├── skills/
│   └── code-quality/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
└── README.md
```

#### 项目 2：团队规范 Plugin（10-team-standards-plugin）

```
10-team-standards-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── check-style.md
│   ├── generate-docs.md
│   └── validate-pr.md
├── skills/
│   ├── api-conventions/
│   │   └── SKILL.md
│   └── git-conventions/
│       └── SKILL.md
└── reference/
    ├── api-design.md
    └── naming-conventions.md
```

#### 项目 3：DevOps Plugin（10-devops-plugin）

```
10-devops-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── deploy.md
│   ├── rollback.md
│   └── status.md
├── agents/
│   ├── deployer.md
│   └── monitor.md
├── .mcp.json
└── workflows/
    ├── staging.yml
    └── production.yml
```

### 10.6 章节知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **10.1 插件系统概述** | 核心价值、组件类型 | ⭐ |
| **10.2 plugin.json** | 元数据、MCP 服务器配置 | ⭐⭐ |
| **10.3 目录结构** | commands/agents/skills/hooks | ⭐⭐ |
| **10.4 CLI 命令** | install/enable/disable | ⭐ |
| **10.5 Marketplace** | 创建、管理、分发 | ⭐⭐⭐ |
| **10.6 团队配置** | 项目级插件、自动安装 | ⭐⭐⭐ |
| **10.7 实战：质量 Plugin** | 完整插件开发 | ⭐⭐⭐⭐ |
| **10.8 实战：团队 Plugin** | 企业级插件 | ⭐⭐⭐⭐ |

---

## 综合建议

### 发布优先级

| 章节 | 优先级 | 理由 |
|------|--------|------|
| **06-Hooks** | 🔴 高 | 基础安全能力，官方文档完善 |
| **07-MCP** | 🔴 高 | 生态扩展核心，三种传输类型 |
| **08-Headless** | 🟡 中 | CI/CD 需求强烈，依赖前两章 |
| **09-Agent SDK** | 🟡 中 | 进阶内容，Python/TS SDK |
| **10-Plugins** | 🟢 正常 | 集大成者，需要前面章节基础 |

### 每章项目数建议

| 章节 | 基础项目 | 进阶项目 | 总数 |
|------|----------|----------|------|
| 06-Hooks | 2 | 1 | 3 |
| 07-MCP | 2 | 1 | 3 |
| 08-Headless | 2 | 1 | 3 |
| 09-Agent SDK | 1 | 1 | 2 |
| 10-Plugins | 2 | 1 | 3 |

### 官方文档一致性检查

| 章节 | 官方文档对齐项 |
|------|----------------|
| 06-Hooks | ✅ 10 种 Hook 事件、Exit Code 语义、JSON Output 格式 |
| 07-MCP | ✅ 三种传输类型、三种 Scope、.mcp.json 格式 |
| 08-Headless | ✅ CLI 选项、输出格式、allowedTools 语法 |
| 09-Agent SDK | ✅ Python/TypeScript SDK、消息 Schema |
| 10-Plugins | ✅ plugin.json 结构、CLI 命令、Marketplace |

---

## 参考资源

### 官方文档
- [Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [MCP Documentation](https://docs.anthropic.com/en/docs/claude-code/mcp)
- [Headless/CLI](https://docs.anthropic.com/en/docs/claude-code/headless)
- [Agent SDK](https://docs.anthropic.com/en/docs/claude-code/sdk)
- [Plugins](https://docs.anthropic.com/en/docs/claude-code/plugins)

### 社区资源
- [LobeHub - Hooks System](https://lobehub.com/zh/skills/madappgang-claude-code-hooks-system)
- [Claude Code Hooks Mastery - GitCode](https://gitcode.com/GitHub_Trending/cl/claude-code-hooks-mastery)

---

*文档生成时间: 2026-03-01*
*基于 Claude Code 官方文档最新版本*
