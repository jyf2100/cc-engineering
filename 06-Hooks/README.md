# 第 11 讲：未雨绸缪 · Hooks 事件驱动自动化

> 在 Claude 执行操作的前后，插入你的"安全守卫"和"质量门禁"

---

## Q1: Claude Code 中的 Hooks 是什么？

### Hooks 的定义

**Hooks** 是 Claude Code 的"事件响应机制"——在特定事件发生时，自动执行你预定义的脚本或命令。

### 核心价值

```
没有 Hooks：
  Claude 想执行 rm -rf / → 直接执行 → 灾难 💥

有了 Hooks：
  Claude 想执行 rm -rf / → PreToolUse Hook 拦截 → 阻止执行 ✅
```

### 在 Claude Code 技术栈中的位置

```
Claude Code 技术栈
├── Plugins（顶层容器）
│   ├── Slash Commands（用户手动触发）
│   ├── Skills（Claude 自动推理触发）
│   ├── MCP Servers（外部工具连接）
│   └── Hooks（事件驱动）  ← 这里：监听一切，控制执行
├── CLAUDE.md（记忆系统）
├── Sub-Agents（子代理）
└── Agent SDK（编程接口）
```

### Hooks 的三个核心能力

| 能力 | 描述 | 示例 |
|------|------|------|
| **拦截** | 阻止不安全的操作 | 禁止 `rm -rf /` |
| **增强** | 在操作前后添加逻辑 | 写入后自动格式化 |
| **监控** | 记录所有操作 | 审计日志 |

---

## Q2: 有哪些 Hook 事件类型？

### 10 种 Hook 事件

Claude Code 提供 10 种 Hook 事件，覆盖完整的生命周期：

| Hook 事件 | 触发时机 | 可阻断 | 典型用途 |
|-----------|----------|--------|----------|
| **PreToolUse** | 工具执行前 | ✅ | 安全检查、权限控制 |
| **PostToolUse** | 工具执行后 | ❌ | 自动格式化、触发测试 |
| **Stop** | 主 Agent 完成响应时 | ✅ | 清理任务、继续任务 |
| **UserPromptSubmit** | 用户提交 prompt 后 | ✅ | 预处理输入、注入上下文 |
| **Notification** | Claude 发送通知时 | ❌ | 自定义通知处理 |
| **SubagentStop** | 子代理完成时 | ✅ | 处理子代理结果 |
| **PreCompact** | 上下文压缩前 | ❌ | 自定义压缩规则 |
| **SessionStart** | 会话开始时 | ❌ | 加载开发上下文 |
| **SessionEnd** | 会话结束时 | ❌ | 清理、保存状态 |
| **PermissionRequest** | 权限对话框出现时 | ✅ | 自动审批/拒绝 |

### 事件流程图

```
用户输入
    │
    ▼
┌─────────────────┐
│ UserPromptSubmit│ ← 可以修改/阻止用户输入
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SessionStart   │ ← 会话开始（仅首次）
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ Claude  │
    │ 处理中   │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│   PreToolUse    │ ← 每个工具执行前（可阻断）
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ 工具执行 │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│  PostToolUse    │ ← 工具执行后
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ 继续?   │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
  继续      Stop
             │
             ▼
    ┌─────────────────┐
    │      Stop       │ ← 响应完成（可阻断继续）
    └─────────────────┘
```

---

## Q3: Hook 如何配置？

### 配置文件位置

```
用户级（全局）
└── ~/.claude/settings.json

项目级（团队共享）
└── .claude/settings.json

本地项目级（不提交）
└── .claude/settings.local.json
```

### 配置结构

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

### Matcher 规则

| Matcher | 匹配目标 | 示例 |
|---------|----------|------|
| 精确匹配 | 单个工具 | `Write` |
| 正则表达式 | 多个工具 | `Edit\|Write` |
| 通配符 | 所有工具 | `*` |
| MCP 工具 | 特定 MCP | `mcp__github__*` |
| 空字符串 | 所有工具 | `""` 或留空 |

### 环境变量

| 变量 | 描述 |
|------|------|
| `$CLAUDE_PROJECT_DIR` | 项目根目录 |
| `$FILE_PATH` | 当前文件路径（Edit/Write） |
| `$TOOL_NAME` | 工具名称 |
| `$TOOL_INPUT` | 工具输入（JSON） |

---

## Q4: Exit Code 的含义是什么？

### 三种 Exit Code

Hook 脚本的退出码决定了 Claude 的行为：

| Exit Code | 含义 | 行为 |
|-----------|------|------|
| **0** | 成功 | stdout 显示给用户（transcript 模式） |
| **2** | 阻断 | stderr 反馈给 Claude，Claude 会自动调整 |
| **其他** | 非阻断错误 | stderr 显示给用户，继续执行 |

### Exit Code 2 的阻断行为

| Hook 事件 | Exit Code 2 的行为 |
|-----------|-------------------|
| PreToolUse | 阻止工具调用，stderr 给 Claude |
| PostToolUse | stderr 给 Claude（工具已执行，无法撤销） |
| UserPromptSubmit | 阻止 prompt 处理，清空 prompt |
| Stop/SubagentStop | 阻止停止，stderr 给 Claude |

### 关键区别

```bash
# Exit 0: 成功，允许继续
exit 0

# Exit 2: 阻断，告诉 Claude 为什么
echo "不允许删除生产环境文件" >&2
exit 2

# Exit 1: 错误，但继续执行（显示给用户）
echo "Hook 脚本出错" >&2
exit 1
```

---

## Q5: Hook 如何输出 JSON 控制行为？

### JSON 输出格式

Hook 可以通过 stdout 输出 JSON 来精细控制 Claude 的行为：

```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "禁止执行危险命令",
  "continue": true
}
```

### permissionDecision 值

| 值 | 行为 |
|----|------|
| `"allow"` | 绕过权限系统，直接执行 |
| `"deny"` | 阻止工具调用 |
| `"ask"` | 要求用户确认 |

### 各事件的 JSON 字段

#### PreToolUse

```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "原因说明",
  "continue": true
}
```

#### PostToolUse

```json
{
  "decision": "approve",
  "reason": "变更符合规范"
}
```

#### Stop

```json
{
  "decision": "continue",
  "reason": "还有未完成的任务"
}
```

#### SessionStart

```json
{
  "hookSpecificOutput": {
    "additionalContext": "## 项目上下文\n\n这是注入的上下文信息..."
  }
}
```

---

## Q6: Hook 接收什么输入？

### stdin JSON 格式

Hook 脚本通过 stdin 接收 JSON 格式的输入：

#### PreToolUse Input

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

#### PostToolUse Input

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/src/index.js",
    "content": "..."
  },
  "tool_output": {
    "success": true,
    "message": "File written"
  }
}
```

#### UserPromptSubmit Input

```json
{
  "session_id": "abc123",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "用户输入的 prompt"
}
```

### 读取输入的脚本示例

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
```

---

## Q7: 实际应用场景有哪些？

### 场景 1：安全防护

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/security-check.sh"
          }
        ]
      }
    ]
  }
}
```

**阻止的操作**：
- `rm -rf /` 或 `rm -rf /*`
- `curl ... | bash` 远程执行
- `DROP DATABASE` 等危险 SQL
- 访问敏感文件（.env, credentials）

### 场景 2：自动格式化

```json
{
  "hooks": {
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

### 场景 3：自动测试

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --findRelatedTests \"$FILE_PATH\""
          }
        ]
      }
    ]
  }
}
```

### 场景 4：会话上下文注入

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/load-context.sh"
          }
        ]
      }
    ]
  }
}
```

### 场景 5：阻止过早停止

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/check-completion.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Q8: 如何调试 Hooks？

### 使用 /hooks 命令

```
/hooks
```

显示当前加载的所有 Hooks 配置。

### 查看 Hook 执行日志

Hook 的 stdout/stderr 会显示在 transcript 中。

### 测试单个 Hook

```bash
# 模拟 PreToolUse 输入
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | .claude/hooks/pre-bash.sh
echo $?
```

### 常见问题排查

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| Hook 不触发 | matcher 不匹配 | 检查工具名称 |
| 权限被拒绝 | 脚本不可执行 | `chmod +x script.sh` |
| 超时 | 脚本执行太慢 | 增加 timeout 或优化脚本 |
| JSON 解析失败 | 输出格式错误 | 验证 JSON 格式 |

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-security-hooks** | 安全守卫 | PreToolUse 拦截危险操作 |
| **02-quality-gates** | 质量门禁 | PostToolUse 自动格式化/测试 |
| **03-context-loader** | 上下文加载 | SessionStart/Stop 上下文管理 |

---

## 参考资源

- [Hooks 官方文档](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Claude Code 最佳实践](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Awesome Claude Code Hooks](https://github.com/topics/claude-code-hooks)

---

## 总结

| 问题 | 答案 |
|------|------|
| Hooks 是什么？ | 事件响应机制，在特定事件时自动执行脚本 |
| 有多少种事件？ | 10 种，覆盖完整生命周期 |
| 如何阻断操作？ | Exit Code 2 或 JSON `permissionDecision: "deny"` |
| 如何注入上下文？ | SessionStart + `additionalContext` |
| 如何调试？ | `/hooks` 命令 + 查看 transcript |
