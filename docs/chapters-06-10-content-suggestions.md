# Claude Code 工程化实战 · 06-10 章内容建议

> **研究日期**: 2026-03-01
> **基于**: Claude Code 最新功能、社区最佳实践、前 5 章风格延续

---

## 目录

1. [第 6 讲：Hooks 钩子系统](#第-6-讲未雨绸缪--hooks-事件驱动自动化)
2. [第 7 讲：MCP 协议](#第-7-讲海纳百川--mcp-协议与外部工具连接)
3. [第 8 讲：Headless 模式](#第-8-讲无人值守--headless-模式与-cicd-集成)
4. [第 9 讲：Agent SDK](#第-9-讲庖丁解牛--agent-sdk-基础与高级应用)
5. [第 10 讲：Plugins 插件系统](#第-10-讲化零为整--plugins-插件打包与分发)
6. [综合建议与优先级](#综合建议与优先级)

---

## 第 6 讲：未雨绸缪 · Hooks 事件驱动自动化

### 6.1 章节定位

> **核心价值**: 让 Claude Code 从"被动执行"变成"主动管控"——在关键节点插入安全检查、自动格式化、审计日志等。

### 6.2 知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **6.1 Hooks 概述** | 7 种 Hook 类型、生命周期、执行顺序 | ⭐ |
| **6.2 控制型 Hook** | PreToolUse 拦截、exit code 2 阻断 | ⭐⭐ |
| **6.3 处理型 Hook** | PostToolUse 自动化、结果处理 | ⭐⭐ |
| **6.4 Hook 编写模式** | 安全检查、自动格式化、审计日志 | ⭐⭐⭐ |
| **6.5 实战：安全钩子** | 敏感命令拦截、SQL 注入防护 | ⭐⭐⭐ |
| **6.6 实战：质量钩子** | 自动 lint、测试触发、PR 检查 | ⭐⭐⭐ |

### 6.3 实战项目建议

#### 项目 1：安全卫士 Hook（06-security-hooks）

**场景**: 在 Claude 执行敏感操作前进行安全审查

**目录结构**:
```
06-security-hooks/
├── README.md
├── .claude/
│   ├── settings.json           # Hook 配置
│   └── hooks/
│       ├── block-dangerous-commands.sh
│       ├── sql-injection-check.sh
│       ├── secrets-scanner.sh
│       └── audit-logger.sh
└── test-scenarios/
    └── dangerous-operations.md  # 测试用例
```

**Hook 示例**:
```bash
#!/bin/bash
# block-dangerous-commands.sh
# PreToolUse Hook - 拦截危险命令

TOOL_INPUT="$1"

# 危险命令黑名单
DANGEROUS_PATTERNS=(
    "rm -rf /"
    "DROP TABLE"
    "TRUNCATE"
    "DELETE FROM"
    ":(){ :|:& };:"  # Fork bomb
    "chmod 777"
    "curl .* | bash"
    "wget .* | sh"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$TOOL_INPUT" =~ $pattern ]]; then
        echo "🚫 BLOCKED: Dangerous operation detected: $pattern"
        echo "Reason: This operation could cause irreversible damage."
        exit 2  # Exit code 2 = 阻止执行
    fi
done

exit 0  # 允许执行
```

**settings.json 配置**:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": ["./.claude/hooks/block-dangerous-commands.sh"]
      },
      {
        "matcher": "Edit|Write",
        "hooks": ["./.claude/hooks/secrets-scanner.sh"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash(git commit:*)",
        "hooks": ["./.claude/hooks/audit-logger.sh"]
      }
    ]
  }
}
```

#### 项目 2：质量门禁 Hook（06-quality-gates）

**场景**: 代码修改后自动执行质量检查

```
06-quality-gates/
├── README.md
├── .claude/
│   └── hooks/
│       ├── auto-lint.sh         # 自动格式化
│       ├── auto-test.sh         # 触发相关测试
│       ├── complexity-check.sh  # 复杂度检查
│       └── todo-scanner.sh      # TODO 扫描
└── sample-project/
    └── src/                     # 示例项目
```

**自动测试 Hook**:
```bash
#!/bin/bash
# auto-test.sh
# PostToolUse Hook - 修改代码后运行相关测试

FILE_PATH="$1"

# 判断是否是代码文件
if [[ "$FILE_PATH" =~ \.(js|ts|py|go)$ ]]; then
    echo "🧪 Running tests related to: $FILE_PATH"

    # 查找相关测试文件
    TEST_FILE="${FILE_PATH%.*}.test.${FILE_PATH##*.}"

    if [[ -f "$TEST_FILE" ]]; then
        npm test -- "$TEST_FILE"
        if [[ $? -ne 0 ]]; then
            echo "⚠️ Tests failed. Please review your changes."
        fi
    fi
fi
```

### 6.4 高级主题

| 主题 | 内容 |
|------|------|
| **Hook 链** | 多个 Hook 的执行顺序和依赖 |
| **条件触发** | matcher 正则、路径过滤 |
| **性能优化** | 避免过度 Hook 导致延迟 |
| **调试技巧** | Hook 日志、错误排查 |
| **安全漏洞** | CVE-2025-59356 解析与防护 |

### 6.5 与前章节衔接

- **与 Commands 结合**: Command 中定义 Hook（如 safe-deploy.md 已展示）
- **与 Skills 结合**: Skill 触发时的 Hook 控制
- **与 SubAgents 结合**: 子代理执行时的 Hook 继承

---

## 第 7 讲：海纳百川 · MCP 协议与外部工具连接

### 7.1 章节定位

> **核心价值**: 让 Claude Code 突破内置工具的限制，连接数据库、API、云服务、浏览器等任意外部系统。

### 7.2 知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **7.1 MCP 协议概述** | 架构设计、Client-Server 模型、传输层 | ⭐ |
| **7.2 内置 MCP 工具** | 官方 MCP 服务器介绍 | ⭐ |
| **7.3 配置 MCP Server** | settings.json 配置、环境变量 | ⭐⭐ |
| **7.4 使用第三方 MCP** | 热门 MCP 工具安装与使用 | ⭐⭐ |
| **7.5 开发自定义 MCP** | Python/TypeScript MCP Server 开发 | ⭐⭐⭐ |
| **7.6 实战：数据库 MCP** | SQLite/PostgreSQL 连接实战 | ⭐⭐⭐ |
| **7.7 实战：浏览器 MCP** | Playwright 自动化实战 | ⭐⭐⭐ |

### 7.3 实战项目建议

#### 项目 1：数据库助手 MCP（07-database-mcp）

**场景**: 让 Claude 直接查询和操作数据库

```
07-database-mcp/
├── README.md
├── .claude/
│   └── settings.json           # MCP 配置
├── mcp-servers/
│   └── sqlite-server/
│       ├── package.json
│       └── index.js            # 自定义 MCP Server
├── database/
│   └── sample.db               # 示例数据库
└── queries/
    └── examples.md             # 查询示例
```

**settings.json MCP 配置**:
```json
{
  "mcpServers": {
    "sqlite": {
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "./database/sample.db"]
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

**MCP Server 开发示例 (Python)**:
```python
# mcp_servers/custom_query/server.py
from mcp.server import Server
from mcp.types import Tool, TextContent
import sqlite3

server = Server("custom-query-server")

@server.list_tools()
async def list_tools():
    return [
        Tool(
            name="query_database",
            description="Execute SQL query on the database",
            inputSchema={
                "type": "object",
                "properties": {
                    "sql": {"type": "string", "description": "SQL query"}
                },
                "required": ["sql"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "query_database":
        conn = sqlite3.connect("./database/sample.db")
        cursor = conn.execute(arguments["sql"])
        results = cursor.fetchall()
        conn.close()
        return [TextContent(type="text", text=str(results))]
```

#### 项目 2：浏览器自动化 MCP（07-browser-mcp）

**场景**: 使用 Playwright 让 Claude 操作浏览器

```
07-browser-mcp/
├── README.md
├── .claude/
│   └── settings.json
├── scripts/
│   ├── screenshot.py           # 截图脚本
│   ├── scrape.py               # 网页抓取
│   └── automate.py             # 自动化流程
└── examples/
    ├── login-flow.md           # 登录自动化示例
    └── price-monitor.md        # 价格监控示例
```

#### 项目 3：企业系统集成 MCP（07-enterprise-mcp）

**场景**: 连接企业内部 API 和服务

```
07-enterprise-mcp/
├── README.md
├── mcp-servers/
│   ├── jira-server/           # Jira 集成
│   ├── slack-server/          # Slack 集成
│   └── github-server/         # GitHub 集成
└── workflows/
    ├── issue-to-pr.md         # Issue 转 PR 流程
    └── notification-pipeline.md
```

### 7.4 热门 MCP 工具推荐（2026）

| MCP Server | 功能 | 安装命令 |
|------------|------|----------|
| **mcp-server-sqlite** | SQLite 数据库 | `uvx mcp-server-sqlite` |
| **mcp-server-postgres** | PostgreSQL | `npx @anthropic/mcp-server-postgres` |
| **playwright-mcp** | 浏览器自动化 | `npx @anthropic/playwright-mcp` |
| **context7** | 实时文档查询 | `npx context7-mcp` |
| **filesystem-mcp** | 文件系统扩展 | `npx @anthropic/filesystem-mcp` |
| **git-mcp** | Git 高级操作 | `npx @anthropic/git-mcp` |

### 7.5 高级主题

| 主题 | 内容 |
|------|------|
| **MCP 安全** | 权限控制、敏感数据处理 |
| **MCP 调试** | 日志、错误追踪 |
| **MCP 性能** | 连接池、缓存策略 |
| **多 MCP 协调** | 多个 MCP Server 协作 |

---

## 第 8 讲：无人值守 · Headless 模式与 CI/CD 集成

### 8.1 章节定位

> **核心价值**: 让 Claude Code 在 CI/CD 流水线中自动运行——代码审查、Bug 修复、PR 创建全自动。

### 8.2 知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **8.1 Headless 概述** | 非交互模式、适用场景 | ⭐ |
| **8.2 CLI 参数** | `-p` 模式、输出格式、超时控制 | ⭐ |
| **8.3 GitHub Actions 集成** | 官方 Action、工作流配置 | ⭐⭐ |
| **8.4 自动 PR 创建** | Issue 转 PR、自动修复 | ⭐⭐⭐ |
| **8.5 定时任务** | Nightly build、定期审查 | ⭐⭐⭐ |
| **8.6 安全最佳实践** | API Key 管理、权限控制 | ⭐⭐⭐ |

### 8.3 实战项目建议

#### 项目 1：自动代码审查 CI（08-auto-review-ci）

**场景**: PR 创建时自动触发 Claude 代码审查

```
08-auto-review-ci/
├── README.md
├── .github/
│   └── workflows/
│       ├── claude-review.yml      # PR 审查工作流
│       ├── claude-fix.yml         # 自动修复工作流
│       └── nightly-audit.yml      # 夜间审计
├── prompts/
│   ├── review-prompt.md           # 审查提示词
│   └── fix-prompt.md              # 修复提示词
└── scripts/
    └── apply-suggestions.sh       # 应用建议脚本
```

**GitHub Actions 工作流**:
```yaml
# .github/workflows/claude-review.yml
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
        id: changes
        run: |
          echo "files=$(git diff --name-only ${{ github.event.pull_request.base.sha }} ${{ github.sha }} | tr '\n' ' ')" >> $GITHUB_OUTPUT

      - name: Claude Code Review
        uses: anthropics/claude-code-action@v1
        with:
          api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Review the following changed files: ${{ steps.changes.outputs.files }}

            Focus on:
            1. Security vulnerabilities
            2. Performance issues
            3. Code quality and maintainability
            4. Test coverage

            Output as GitHub PR comment format.
          model: claude-sonnet-4-6

      - name: Post review comment
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: process.env.CLAUDE_OUTPUT
            })
```

#### 项目 2：Issue 自动修复（08-issue-fixer）

**场景**: 用户创建 Issue，Claude 自动分析并创建修复 PR

```
08-issue-fixer/
├── README.md
├── .github/
│   └── workflows/
│       └── issue-to-pr.yml        # Issue 转 PR
├── templates/
│   ├── fix-template.md            # 修复模板
│   └── pr-template.md             # PR 模板
└── safety/
    ├── allowed-files.txt          # 允许修改的文件
    └── test-requirements.txt      # 必须通过的测试
```

**Issue 转 PR 工作流**:
```yaml
# .github/workflows/issue-to-pr.yml
name: Issue to Fix PR

on:
  issues:
    types: [labeled]

jobs:
  auto-fix:
    if: github.event.label.name == 'auto-fix'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Claude Analyze and Fix
        uses: anthropics/claude-code-action@v1
        with:
          api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}

            Description:
            ${{ github.event.issue.body }}

            Analyze the codebase, identify the root cause, and implement a fix.
            Create a new branch and prepare a PR with:
            - Clear description of the fix
            - Test cases added
            - No breaking changes

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v6
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          branch: fix/issue-${{ github.event.issue.number }}
          title: "Fix: ${{ github.event.issue.title }}"
          body: |
            ## Fixes #${{ github.event.issue.number }}

            ## Changes
            ${{ env.CLAUDE_CHANGES }}

            ## Test Plan
            ${{ env.CLAUDE_TEST_PLAN }}
```

#### 项目 3：夜间安全审计（08-nightly-audit）

**场景**: 每天自动扫描代码库安全漏洞

```
08-nightly-audit/
├── README.md
├── .github/
│   └── workflows/
│       └── security-audit.yml
├── audit-rules/
│   ├── sql-injection.md
│   ├── xss-patterns.md
│   └── secrets-detection.md
└── reports/
    └── template.md
```

### 8.4 Headless CLI 命令参考

```bash
# 基础非交互模式
claude -p "Review the changes in src/"

# 流式 JSON 输出
claude -p "Analyze code quality" --output-format stream-json

# 带超时控制
claude -p "Fix the bug" --timeout 300000

# 指定模型
claude -p "Complex analysis" --model claude-opus-4-6

# 允许特定工具
claude -p "Deploy to staging" --allowed-tools "Bash(npm:*)"

# 从文件读取提示词
claude -p "$(cat prompts/review-prompt.md)"
```

### 8.5 安全最佳实践

| 风险 | 防护措施 |
|------|----------|
| API Key 泄露 | 使用 GitHub Secrets，禁止日志输出 |
| 无限循环 | 设置超时、限制迭代次数 |
| 恶意代码执行 | 限制 allowed-tools、沙箱环境 |
| 无权限操作 | 使用最小权限 Token |

---

## 第 9 讲：庖丁解牛 · Agent SDK 基础与高级应用

### 9.1 章节定位

> **核心价值**: 用 Python/TypeScript 代码驱动 Claude——构建生产级 AI Agent、集成到现有系统。

### 9.2 知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **9.1 SDK 概述** | 两种接口：query() vs ClaudeSDKClient | ⭐ |
| **9.2 快速开始** | 安装、认证、第一个程序 | ⭐ |
| **9.3 单次查询** | query() 函数、参数配置 | ⭐⭐ |
| **9.4 流式交互** | ClaudeSDKClient、async/await | ⭐⭐ |
| **9.5 自定义工具** | Tool 定义、输入输出 | ⭐⭐⭐ |
| **9.6 Hooks 集成** | SDK 中的 Hook 机制 | ⭐⭐⭐ |
| **9.7 会话管理** | 持久化、恢复、并发 | ⭐⭐⭐ |
| **9.8 实战：测试修复 Agent** | 完整的生产级 Agent | ⭐⭐⭐⭐ |

### 9.3 实战项目建议

#### 项目 1：自动化测试修复 Agent（09-test-fixer-agent）

**场景**: 自动检测失败的测试，分析原因，生成修复

```
09-test-fixer-agent/
├── README.md
├── src/
│   ├── agent/
│   │   ├── __init__.py
│   │   ├── test_analyzer.py     # 测试分析
│   │   ├── code_fixer.py        # 代码修复
│   │   └── validator.py         # 修复验证
│   ├── tools/
│   │   ├── run_tests.py         # 运行测试工具
│   │   ├── read_coverage.py     # 读取覆盖率
│   │   └── apply_fix.py         # 应用修复
│   └── main.py                  # 入口
├── config/
│   └── agent_config.yaml        # Agent 配置
├── tests/
│   └── test_agent.py            # Agent 测试
└── examples/
    └── sample-buggy-project/    # 示例项目
```

**Python SDK 示例**:
```python
# src/agent/test_analyzer.py
import asyncio
from claude_agent_sdk import ClaudeSDKClient, Tool, ClaudeAgentOptions

class TestFixerAgent:
    def __init__(self, api_key: str):
        self.client = ClaudeSDKClient(
            api_key=api_key,
            options=ClaudeAgentOptions(
                model="claude-sonnet-4-6",
                system_prompt=self._get_system_prompt()
            )
        )
        self._register_tools()

    def _get_system_prompt(self):
        return """你是一个测试修复专家。
        当测试失败时，你会：
        1. 分析测试输出，找出失败原因
        2. 定位相关代码
        3. 生成最小化修复
        4. 验证修复不破坏其他测试
        """

    def _register_tools(self):
        @self.client.tool("run_tests")
        async def run_tests(test_file: str = None):
            """运行测试并返回结果"""
            # 实现测试运行逻辑
            pass

        @self.client.tool("read_file")
        async def read_file(path: str):
            """读取文件内容"""
            with open(path, 'r') as f:
                return f.read()

        @self.client.tool("apply_fix")
        async def apply_fix(file_path: str, fix_content: str):
            """应用修复到文件"""
            # 实现修复应用逻辑
            pass

    async def fix_test(self, test_output: str):
        async with self.client as session:
            response = await session.send(
                f"测试失败了，请分析并修复：\n{test_output}"
            )
            return response

# 使用示例
async def main():
    agent = TestFixerAgent(api_key="your-api-key")
    result = await agent.fix_test("FAIL: test_login.py - AssertionError: Expected 200, got 401")
    print(result)

asyncio.run(main())
```

**TypeScript SDK 示例**:
```typescript
// src/agent/testAnalyzer.ts
import { ClaudeSDKClient, Tool, ClaudeAgentOptions } from '@anthropic/claude-agent-sdk';

interface TestResult {
  passed: boolean;
  testName: string;
  error?: string;
}

export class TestFixerAgent {
  private client: ClaudeSDKClient;

  constructor(apiKey: string) {
    const options: ClaudeAgentOptions = {
      model: 'claude-sonnet-4-6',
      systemPrompt: this.getSystemPrompt()
    };

    this.client = new ClaudeSDKClient({ apiKey, options });
    this.registerTools();
  }

  private getSystemPrompt(): string {
    return `你是一个测试修复专家。
    分析失败测试，定位问题代码，生成最小化修复。`;
  }

  private registerTools(): void {
    this.client.tool('run_tests', async (testFile?: string) => {
      // 运行测试逻辑
    });

    this.client.tool('read_file', async (path: string) => {
      return await Bun.file(path).text();
    });

    this.client.tool('apply_fix', async (filePath: string, content: string) => {
      await Bun.write(filePath, content);
    });
  }

  async fixTest(testOutput: string): Promise<string> {
    const response = await this.client.send(
      `测试失败了，请分析并修复：\n${testOutput}`
    );
    return response;
  }
}
```

#### 项目 2：多 Agent 协作系统（09-multi-agent-system）

**场景**: 多个专业 Agent 协作完成复杂任务

```
09-multi-agent-system/
├── README.md
├── src/
│   ├── agents/
│   │   ├── planner.py           # 规划 Agent
│   │   ├── coder.py             # 编码 Agent
│   │   ├── reviewer.py          # 审查 Agent
│   │   └── tester.py            # 测试 Agent
│   ├── orchestrator/
│   │   ├── task_queue.py        # 任务队列
│   │   ├── coordinator.py       # 协调器
│   │   └── communication.py     # Agent 通信
│   └── main.py
└── examples/
    └── feature-development.md   # 功能开发流程示例
```

#### 项目 3：CLI 工具包装器（09-cli-wrapper）

**场景**: 用 SDK 包装 Claude Code 功能为可复用 CLI 工具

```
09-cli-wrapper/
├── README.md
├── src/
│   ├── cli/
│   │   ├── commands/
│   │   │   ├── review.py
│   │   │   ├── fix.py
│   │   │   └── generate.py
│   │   └── main.py             # CLI 入口
│   └── core/
│       ├── config.py
│       └── output.py
├── pyproject.toml
└── tests/
```

### 9.4 SDK 核心 API 参考

```python
# 单次查询模式
from claude_agent_sdk import query, ClaudeAgentOptions

result = await query(
    "Analyze this code",
    options=ClaudeAgentOptions(
        model="claude-sonnet-4-6",
        allowed_tools=["Read", "Grep"],
        timeout_ms=300000
    )
)

# 流式会话模式
from claude_agent_sdk import ClaudeSDKClient

async with ClaudeSDKClient(options) as client:
    # 发送消息
    response = await client.send("Hello")

    # 流式接收
    async for chunk in client.stream("Long task..."):
        print(chunk)

    # 使用工具
    result = await client.send_with_tools(
        "Read the file",
        tools=[read_file_tool]
    )
```

### 9.5 高级主题

| 主题 | 内容 |
|------|------|
| **会话持久化** | 保存/恢复会话状态 |
| **并发控制** | 多请求、速率限制 |
| **错误处理** | 重试、超时、回退 |
| **成本控制** | Token 计数、预算限制 |
| **可观测性** | 日志、指标、追踪 |

---

## 第 10 讲：化零为整 · Plugins 插件打包与分发

### 10.1 章节定位

> **核心价值**: 把 Commands、Skills、Agents、Hooks、MCP 打包成可复用的插件——实现团队资产沉淀与共享。

### 10.2 知识点规划

| 模块 | 内容 | 难度 |
|------|------|------|
| **10.1 插件系统概述** | 架构设计、核心价值 | ⭐ |
| **10.2 plugin.json 结构** | 元数据、依赖、入口点 | ⭐ |
| **10.3 创建基础插件** | 单功能插件开发 | ⭐⭐ |
| **10.4 打包与发布** | 版本管理、发布流程 | ⭐⭐ |
| **10.5 插件安装与管理** | `/plugin` 命令、配置 | ⭐⭐ |
| **10.6 企业级插件** | 团队规范、私有仓库 | ⭐⭐⭐ |
| **10.7 实战：团队能力包** | 完整的团队插件开发 | ⭐⭐⭐⭐ |

### 10.3 实战项目建议

#### 项目 1：代码质量插件（10-code-quality-plugin）

**场景**: 打包代码审查、测试、格式化能力为团队共享插件

```
10-code-quality-plugin/
├── README.md
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── commands/
│   ├── review.md                # /code-quality:review
│   ├── lint.md                  # /code-quality:lint
│   └── test.md                  # /code-quality:test
├── agents/
│   └── quality-guard.md         # 质量守护 Agent
├── skills/
│   └── code-quality/
│       └── SKILL.md             # 质量检查 Skill
├── hooks/
│   └── pre-commit-check.sh      # 提交前检查
└── templates/
    ├── review-report.md
    └── quality-badge.md
```

**plugin.json 示例**:
```json
{
  "name": "code-quality",
  "version": "1.0.0",
  "description": "代码质量检查插件 - 包含审查、测试、格式化能力",
  "author": "your-team",
  "repository": "https://github.com/your-org/code-quality-plugin",
  "keywords": ["code-review", "lint", "test", "quality"],

  "provides": {
    "commands": ["review", "lint", "test"],
    "agents": ["quality-guard"],
    "skills": ["code-quality"],
    "hooks": ["pre-commit-check"]
  },

  "dependencies": {
    "claude-code": ">=2.0.0"
  },

  "configuration": {
    "defaultSeverity": "warning",
    "autoFix": true,
    "ignorePatterns": ["node_modules", "dist"]
  },

  "activationEvents": [
    "onCommand:code-quality:review",
    "onLanguage:javascript",
    "onLanguage:python"
  ]
}
```

#### 项目 2：DevOps 工具链插件（10-devops-plugin）

**场景**: 打包部署、监控、告警能力

```
10-devops-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── deploy.md                # /devops:deploy
│   ├── rollback.md              # /devops:rollback
│   ├── status.md                # /devops:status
│   └── logs.md                  # /devops:logs
├── agents/
│   ├── deployer.md              # 部署 Agent
│   └── monitor.md               # 监控 Agent
├── mcp/
│   └── kubernetes-mcp/          # K8s MCP 配置
├── hooks/
│   └── deployment-gate.sh       # 部署门禁
└── workflows/
    ├── staging-deploy.yml
    └── production-deploy.yml
```

#### 项目 3：团队规范插件（10-team-standards-plugin）

**场景**: 打包团队编码规范、Git 规范、API 规范

```
10-team-standards-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── check-style.md           # /team:check-style
│   ├── generate-docs.md         # /team:generate-docs
│   └── validate-pr.md           # /team:validate-pr
├── skills/
│   ├── api-conventions/
│   │   └── SKILL.md             # API 规范
│   ├── git-conventions/
│   │   └── SKILL.md             # Git 规范
│   └── coding-standards/
│       └── SKILL.md             # 编码规范
├── reference/
│   ├── api-design.md
│   ├── error-handling.md
│   └── naming-conventions.md
└── templates/
    ├── pr-template.md
    ├── commit-template.md
    └── api-doc-template.md
```

**plugin.json (团队规范)**:
```json
{
  "name": "team-standards",
  "version": "2.1.0",
  "description": "团队规范插件 - 统一编码、API、Git 规范",
  "author": "platform-team",
  "private": true,

  "provides": {
    "commands": ["check-style", "generate-docs", "validate-pr"],
    "skills": ["api-conventions", "git-conventions", "coding-standards"]
  },

  "configuration": {
    "company": "your-company",
    "defaultBranch": "main",
    "requirePRReviews": 2,
    "enforceConventionalCommits": true
  },

  "activationEvents": [
    "onStartup"
  ]
}
```

#### 项目 4：安全合规插件（10-security-compliance-plugin）

**场景**: 打包安全检查、合规审计能力

```
10-security-compliance-plugin/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── security-auditor.md      # 安全审计 Agent
│   └── compliance-checker.md    # 合规检查 Agent
├── skills/
│   ├── vulnerability-scan/
│   │   └── SKILL.md
│   └── secrets-detection/
│       └── SKILL.md
├── hooks/
│   ├── pre-commit-secret-scan.sh
│   └── pre-push-security-check.sh
├── rules/
│   ├── owasp-top-10.yaml
│   └── cve-patterns.yaml
└── reports/
    └── security-audit-template.md
```

### 10.4 插件生命周期

```
1. 开发阶段
   └─ 编写 plugin.json
   └─ 组织 commands/agents/skills/hooks
   └─ 本地测试

2. 打包阶段
   └─ 版本号管理
   └─ CHANGELOG 更新
   └─ 依赖检查

3. 发布阶段
   └─ 公开: npm / GitHub
   └─ 私有: 企业仓库

4. 安装阶段
   └─ /plugin install <name>
   └─ 配置初始化
   └─ 依赖安装

5. 使用阶段
   └─ 自动激活
   └─ 按需加载
   └─ 更新检查

6. 卸载阶段
   └─ /plugin uninstall <name>
   └─ 配置清理
```

### 10.5 插件管理命令

```bash
# 安装插件
/plugin install code-quality

# 从 Git 安装
/plugin install github:your-org/your-plugin

# 从本地路径安装
/plugin install ./path/to/plugin

# 列出已安装插件
/plugin list

# 更新插件
/plugin update code-quality

# 卸载插件
/plugin uninstall code-quality

# 查看插件信息
/plugin info code-quality
```

### 10.6 企业级实践

| 场景 | 建议方案 |
|------|----------|
| **私有仓库** | 搭建内部 npm 仓库或使用 GitHub Packages |
| **权限控制** | 插件签名验证、访问控制列表 |
| **版本策略** | 语义化版本、LTS 支持 |
| **文档规范** | 统一 README 模板、API 文档生成 |
| **测试要求** | 单元测试、集成测试、兼容性测试 |

---

## 综合建议与优先级

### 发布优先级

| 章节 | 优先级 | 理由 |
|------|--------|------|
| **06-Hooks** | 🔴 高 | 基础安全能力，与前 5 章紧密衔接 |
| **07-MCP** | 🔴 高 | 生态扩展核心，社区热度高 |
| **08-Headless** | 🟡 中 | CI/CD 需求强烈，但依赖前两章 |
| **09-Agent SDK** | 🟡 中 | 进阶内容，受众相对专业 |
| **10-Plugins** | 🟢 正常 | 集大成者，需要前面章节基础 |

### 每章项目数建议

| 章节 | 基础项目 | 进阶项目 | 总数 |
|------|----------|----------|------|
| 06-Hooks | 2 | 1 | 3 |
| 07-MCP | 2 | 2 | 4 |
| 08-Headless | 2 | 1 | 3 |
| 09-Agent SDK | 2 | 2 | 4 |
| 10-Plugins | 2 | 2 | 4 |

### 技术栈建议

| 章节 | 主要语言 | 依赖 |
|------|----------|------|
| 06-Hooks | Bash | Shell 工具 |
| 07-MCP | Python/Node.js | SQLite/Playwright |
| 08-Headless | YAML | GitHub Actions |
| 09-Agent SDK | Python/TypeScript | claude-agent-sdk |
| 10-Plugins | JSON/Markdown | 插件系统 |

### 与前章节衔接

```
02-Memory → 06-Hooks (CLAUDE.md 中的规则触发 Hooks)
03-SubAgents → 09-Agent SDK (子代理的编程式调用)
04-Skills → 10-Plugins (Skill 作为插件组件)
05-Commands → 10-Plugins (Command 作为插件组件)
07-MCP → 08-Headless (CI/CD 中使用 MCP)
09-Agent SDK → 08-Headless (编程式调用 CI/CD)
```

---

## 参考资源

### 官方文档
- [Claude Code 官方文档](https://code.claude.com/docs)
- [MCP 协议规范](https://modelcontextprotocol.io)
- [Agent SDK 文档](https://platform.claude.com/docs/en/agent-sdk/overview)

### 社区资源
- [Claude Code Hooks 详解 - CSDN](https://blog.csdn.net/zhangyifang_009/article/details/158510718)
- [MCP 工具推荐 - 掘金](https://juejin.cn/post/7597709339982708776)
- [Headless CI/CD 集成 - 极客邦](https://time.geekbang.org/column/article/934472)
- [Agent SDK 实战 - 掘金](https://juejin.cn/post/7606640585462956059)
- [插件开发指南 - 掘金](https://juejin.cn/post/7599630795805655086)

---

*建议生成时间: 2026-03-01*
*基于 Claude Code 最新功能和社区最佳实践*
