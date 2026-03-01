# 第 9 讲：庖丁解牛 · Agent SDK 基础与高级应用

> 用 Python/TypeScript 编程驱动 Claude 执行任务，构建生产级 AI Agent

---

## Q1: Agent SDK 是什么？

### SDK 的定义

**Agent SDK** 是 Claude Code 的编程接口，让你可以用 Python 或 TypeScript 代码调用 Claude Code 的能力。相比 CLI 方式，SDK 提供：
- 更精细的控制
- 更好的可编程性
- 与现有系统集成

### 两种使用方式对比

```
CLI 方式（第 8 讲）：
  Shell 脚本 → claude -p "..." → 输出结果

SDK 方式（本讲）：
  Python/TS 代码 → query() → Claude Code → 返回结果对象
```

### 在 Claude Code 技术栈中的位置

```
Claude Code 使用方式
├── 交互模式（Interactive）
│   └── 终端中对话式使用
│
├── Headless 模式（CLI）
│   └── claude -p "..." 脚本调用
│
└── Agent SDK（编程）  ← 这里：完全编程控制
    ├── Python SDK
    └── TypeScript SDK
```

### 什么时候用 SDK？

| 场景 | 推荐方式 |
|------|----------|
| 简单脚本 | CLI |
| CI/CD 流水线 | CLI |
| 需要复杂逻辑 | SDK |
| 需要状态管理 | SDK |
| 集成到应用 | SDK |
| 自定义工具 | SDK |

---

## Q2: 如何使用 Python SDK？

### 安装

```bash
pip install claude-code-sdk
```

**要求**：Python 3.10+

### 基础用法

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

### 流式处理

```python
import asyncio
from claude_code_sdk import query_stream, ClaudeCodeOptions

async def main():
    # 流式处理
    async for event in query_stream(
        "Explain the codebase structure",
        options=ClaudeCodeOptions(
            allowed_tools=["Read", "Glob", "Grep"]
        )
    ):
        if event["type"] == "assistant":
            print(event["content"], end="")
        elif event["type"] == "result":
            print(f"\n\nCost: ${event['cost_usd']:.4f}")

asyncio.run(main())
```

### 完整示例：代码审查

```python
import asyncio
import json
from claude_code_sdk import query, ClaudeCodeOptions

async def review_code(file_path: str) -> dict:
    """审查代码文件"""
    prompt = f"""
    Review the file {file_path} for:
    1. Security vulnerabilities
    2. Code quality issues
    3. Performance concerns

    Return findings in JSON format.
    """

    result = await query(
        prompt,
        options=ClaudeCodeOptions(
            allowed_tools=["Read", "Grep"],
            output_format="json",
            max_turns=5
        )
    )

    return json.loads(result["result"])

# 使用
asyncio.run(review_code("src/auth.py"))
```

---

## Q3: 如何使用 TypeScript SDK？

### 安装

```bash
npm install @anthropic-ai/claude-code
```

**要求**：Node.js 18+

### 基础用法

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

### 流式处理

```typescript
import { queryStream, ClaudeCodeOptions } from '@anthropic-ai/claude-code';

async function main() {
  for await (const event of queryStream("Explain the architecture", {
    allowedTools: ["Read", "Glob"]
  })) {
    if (event.type === "assistant") {
      process.stdout.write(event.content);
    } else if (event.type === "result") {
      console.log(`\n\nCost: $${event.cost_usd.toFixed(4)}`);
    }
  }
}

main();
```

### 完整示例：测试修复

```typescript
import { query, ClaudeCodeOptions } from '@anthropic-ai/claude-code';

interface TestResult {
  passed: boolean;
  failures: string[];
}

async function fixFailingTests(testResult: TestResult): Promise<string> {
  const prompt = `
    The following tests are failing:
    ${testResult.failures.join('\n')}

    Please analyze and fix the issues.
  `;

  const result = await query(prompt, {
    allowedTools: ["Read", "Edit", "Write", "Bash(npm test*)"],
    maxTurns: 10,
    systemPrompt: "You are a test fixer. Always run tests after making changes."
  });

  return result.result;
}

// 使用
const result = await fixFailingTests({
  passed: false,
  failures: ["auth.test.js: login should work", "user.test.js: registration should validate email"]
});
```

---

## Q4: 核心 SDK 选项有哪些？

### ClaudeCodeOptions 接口

```typescript
interface ClaudeCodeOptions {
  // 工具权限
  allowedTools?: string[];
  disallowedTools?: string[];

  // 输出控制
  outputFormat?: "text" | "json" | "stream-json";

  // 系统提示
  systemPrompt?: string;
  appendSystemPrompt?: string;

  // MCP 配置
  mcpConfig?: string;

  // 执行控制
  maxTurns?: number;
  timeout?: number;

  // 会话管理
  resume?: string;
  continue?: boolean;
}
```

### 选项详解

| 选项 | 类型 | 描述 |
|------|------|------|
| `allowedTools` | string[] | 预授权工具列表 |
| `disallowedTools` | string[] | 禁止使用的工具 |
| `outputFormat` | string | 输出格式：text/json/stream-json |
| `systemPrompt` | string | 覆盖默认系统提示 |
| `appendSystemPrompt` | string | 追加到系统提示末尾 |
| `mcpConfig` | string | MCP 配置文件路径 |
| `maxTurns` | number | 最大迭代轮次 |
| `timeout` | number | 超时时间（毫秒） |
| `resume` | string | 恢复的会话 ID |
| `continue` | boolean | 继续最近会话 |

### Python vs TypeScript 命名差异

| Python | TypeScript |
|--------|------------|
| `allowed_tools` | `allowedTools` |
| `disallowed_tools` | `disallowedTools` |
| `output_format` | `outputFormat` |
| `system_prompt` | `systemPrompt` |
| `append_system_prompt` | `appendSystemPrompt` |
| `mcp_config` | `mcpConfig` |
| `max_turns` | `maxTurns` |

---

## Q5: 消息 Schema 是什么？

### 消息类型

```typescript
interface Message {
  type: "user" | "assistant" | "system";
  content: string | ContentBlock[];
  role: "user" | "assistant";
}
```

### 内容块类型

```typescript
interface ContentBlock {
  type: "text" | "tool_use" | "tool_result";
  text?: string;
  name?: string;      // 工具名称
  input?: any;        // 工具输入
  content?: string;   // 工具输出
}
```

### 事件类型（流式）

```typescript
// 初始化事件
interface InitEvent {
  type: "init";
  session_id: string;
}

// 用户消息
interface UserEvent {
  type: "user";
  content: string;
}

// 助手响应
interface AssistantEvent {
  type: "assistant";
  content: string;
}

// 工具使用
interface ToolUseEvent {
  type: "tool_use";
  name: string;
  input: object;
}

// 工具结果
interface ToolResultEvent {
  type: "tool_result";
  output: string;
}

// 最终结果
interface ResultEvent {
  type: "result";
  result: string;
  cost_usd: number;
  duration_ms: number;
  is_error: boolean;
}
```

### 处理流式事件

```python
# Python
async for event in query_stream("..."):
    match event["type"]:
        case "init":
            print(f"Session: {event['session_id']}")
        case "assistant":
            print(event["content"], end="")
        case "tool_use":
            print(f"\n[Using {event['name']}]")
        case "result":
            print(f"\n\nDone. Cost: ${event['cost_usd']:.4f}")
```

---

## Q6: 实战应用场景有哪些？

### 场景 1：自动化测试修复

```python
# test_fixer.py
import asyncio
from claude_code_sdk import query, ClaudeCodeOptions

async def fix_tests(test_output: str) -> str:
    result = await query(
        f"Fix these failing tests:\n{test_output}",
        options=ClaudeCodeOptions(
            allowed_tools=["Read", "Edit", "Bash(npm test*)"],
            max_turns=15,
            system_prompt="Fix tests one by one. Run tests after each fix."
        )
    )
    return result["result"]

# 在 CI 中使用
if __name__ == "__main__":
    import sys
    test_output = sys.stdin.read()
    asyncio.run(fix_tests(test_output))
```

### 场景 2：代码审查 Bot

```typescript
// review-bot.ts
import { query, ClaudeCodeOptions } from '@anthropic-ai/claude-code';
import { Octokit } from '@octokit/rest';

async function reviewPR(owner: string, repo: string, prNumber: number) {
  const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

  // 获取 PR diff
  const { data: pr } = await octokit.pulls.get({
    owner, repo, pull_number: prNumber
  });

  // 使用 Claude 审查
  const result = await query(
    `Review this PR for security and quality:\n${pr.body}`,
    {
      allowedTools: ["Read", "Grep", "Bash(git diff*)"],
      outputFormat: "json"
    }
  );

  // 发布评论
  await octokit.issues.createComment({
    owner, repo,
    issue_number: prNumber,
    body: result.result
  });
}
```

### 场景 3：文档生成

```python
# doc_generator.py
import asyncio
from claude_code_sdk import query_stream, ClaudeCodeOptions

async def generate_docs(source_dir: str, output_file: str):
    prompt = f"""
    Analyze the code in {source_dir} and generate:
    1. API documentation
    2. Usage examples
    3. Architecture overview

    Write the documentation to {output_file}
    """

    async for event in query_stream(
        prompt,
        options=ClaudeCodeOptions(
            allowed_tools=["Read", "Glob", "Grep", "Write"],
            max_turns=20
        )
    ):
        if event["type"] == "assistant":
            print(event["content"], end="")

    print("\nDocumentation generated!")
```

### 场景 4：安全扫描

```typescript
// security-scanner.ts
import { query, ClaudeCodeOptions } from '@anthropic-ai/claude-code';

interface SecurityFinding {
  severity: 'high' | 'medium' | 'low';
  file: string;
  line: number;
  description: string;
}

async function scanSecurity(): Promise<SecurityFinding[]> {
  const result = await query(
    "Scan the codebase for security vulnerabilities",
    {
      allowedTools: ["Read", "Grep", "Glob"],
      outputFormat: "json",
      systemPrompt: "Return findings as JSON array with severity, file, line, description."
    }
  );

  return JSON.parse(result.result);
}
```

---

## Q7: 最佳实践有哪些？

### 1. 明确工具权限

```python
# 好的做法：只给需要的权限
options=ClaudeCodeOptions(
    allowed_tools=["Read", "Grep"]  # 只读
)

# 避免：给过多权限
options=ClaudeCodeOptions(
    allowed_tools=["*"]  # 危险！
)
```

### 2. 限制迭代次数

```python
# 防止无限循环
options=ClaudeCodeOptions(
    max_turns=10  # 限制 10 轮
)
```

### 3. 使用系统提示引导行为

```python
options=ClaudeCodeOptions(
    system_prompt="""
    You are a code reviewer. Focus on:
    - Security issues
    - Performance concerns
    - Code style

    Be concise and actionable.
    """
)
```

### 4. 处理错误

```python
async def safe_query(prompt: str, options: ClaudeCodeOptions):
    try:
        result = await query(prompt, options=options)
        if result.get("is_error"):
            raise Exception(result.get("error", "Unknown error"))
        return result
    except Exception as e:
        print(f"Query failed: {e}")
        return None
```

### 5. 监控成本

```python
async for event in query_stream("..."):
    if event["type"] == "result":
        cost = event["cost_usd"]
        if cost > 1.0:
            print(f"Warning: High cost ${cost:.2f}")
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-test-fixer-agent** | 测试修复 Agent | Python SDK + 自动测试修复 |
| **02-review-bot** | 代码审查 Bot | TypeScript SDK + GitHub 集成 |

---

## 参考资源

- [Agent SDK 官方文档](https://docs.anthropic.com/en/docs/claude-code/sdk)
- [Python SDK PyPI](https://pypi.org/project/claude-code-sdk/)
- [TypeScript SDK npm](https://www.npmjs.com/package/@anthropic-ai/claude-code)

---

## 总结

| 问题 | 答案 |
|------|------|
| Agent SDK 是什么？ | Claude Code 的编程接口，支持 Python 和 TypeScript |
| Python SDK 如何使用？ | `pip install claude-code-sdk`，使用 `query()` 函数 |
| TypeScript SDK 如何使用？ | `npm install @anthropic-ai/claude-code`，使用 `query()` 函数 |
| 核心 SDK 选项？ | allowedTools、outputFormat、systemPrompt、maxTurns 等 |
| 消息 Schema？ | Message、ContentBlock、事件类型（init/user/assistant/result） |
| 最佳实践？ | 明确权限、限制迭代、使用系统提示、错误处理、监控成本 |
