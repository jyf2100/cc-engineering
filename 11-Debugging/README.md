# 第 17 讲：明察秋毫 · Claude Code 调试技巧与问题排查

> 当 Claude 的行为不如预期时，系统化的调试方法帮你快速定位问题根源

---

## Q1: Claude Code 有哪些常见问题类型？

### 问题分类

| 类型 | 描述 | 典型表现 |
|------|------|----------|
| **配置问题** | CLAUDE.md、settings.json 配置错误 | 命令不触发、Agent 不加载 |
| **权限问题** | 工具权限不足或过度 | 操作被拒绝、敏感操作未拦截 |
| **上下文问题** | 上下文过长或缺失 | Claude "忘记"信息、重复提问 |
| **行为问题** | Claude 行为不符合预期 | 输出格式错误、任务未完成 |
| **性能问题** | 响应慢、Token 消耗高 | 等待时间长、成本超预期 |
| **集成问题** | MCP、Hooks、SDK 集成失败 | 工具不可用、事件不触发 |

### 问题诊断流程

```
发现问题
    │
    ▼
┌─────────────────┐
│ 1. 确认问题类型  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
配置/权限   行为/性能
    │         │
    ▼         ▼
检查配置    检查上下文
    │         │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│ 2. 使用调试工具  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. 定位根因      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. 应用修复      │
└─────────────────┘
```

---

## Q2: 如何使用内置调试命令？

### /debug 命令

```
/debug
```

显示当前会话的详细调试信息：
- 加载的配置文件
- 激活的 Agent/Skill/Command
- Hook 配置状态
- MCP 服务器状态

### /hooks 命令

```
/hooks
```

显示当前配置的所有 Hooks：
- Hook 事件类型
- Matcher 规则
- 关联的脚本路径

### /mcp 命令

```
/mcp
```

显示 MCP 服务器状态：
- 已连接的服务器
- 可用的工具列表
- 连接错误信息

### /context 命令

```
/context
```

显示当前上下文信息：
- 上下文大小（Token 数）
- 加载的 CLAUDE.md 内容
- 激活的 Skill 内容

---

## Q3: 如何调试 Hook 问题？

### Hook 不触发的排查步骤

1. **检查配置文件位置**
   ```bash
   # 项目级配置
   ls -la .claude/settings.json

   # 用户级配置
   ls -la ~/.claude/settings.json
   ```

2. **验证 JSON 格式**
   ```bash
   # 使用 jq 验证
   cat .claude/settings.json | jq .
   ```

3. **检查 Matcher 规则**
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",  // 确保工具名称正确
           "hooks": [...]
         }
       ]
     }
   }
   ```

4. **测试 Hook 脚本**
   ```bash
   # 模拟输入测试
   echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | \
     .claude/hooks/pre-bash.sh

   # 检查退出码
   echo $?
   ```

### 常见 Hook 问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Hook 不触发 | matcher 不匹配 | 检查工具名称，使用正则 |
| 脚本执行失败 | 权限不足 | `chmod +x script.sh` |
| 超时 | 执行时间过长 | 增加 timeout 参数 |
| JSON 解析错误 | 输出格式错误 | 验证 jq 输出 |

### Hook 调试脚本

```bash
#!/bin/bash
# debug-hook.sh - Hook 调试脚本

# 记录所有输入
INPUT=$(cat)
echo "[$(date)] Input: $INPUT" >> /tmp/hook-debug.log

# 记录退出码
trap 'echo "[$(date)] Exit code: $?" >> /tmp/hook-debug.log' EXIT

# 你的 Hook 逻辑
# ...
```

---

## Q4: 如何调试 MCP 问题？

### MCP 连接问题排查

1. **检查 MCP 配置**
   ```bash
   # 查看 .mcp.json
   cat .mcp.json | jq .

   # 验证服务器配置
   claude mcp list
   ```

2. **测试 MCP 服务器连接**
   ```bash
   # 获取服务器详情
   claude mcp get <server-name>
   ```

3. **检查 stdio 服务器**
   ```bash
   # 手动启动测试
   npx -y @anthropic-ai/mcp-server-sqlite --db-path ./test.db

   # 检查环境变量
   echo $DATABASE_URL
   ```

### MCP 工具调试

在 Claude Code 内：

```
/mcp
```

查看：
- ✅ 已连接的服务器
- ❌ 连接失败的服务器
- 可用的工具列表

### 常见 MCP 问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 连接超时 | 网络问题 | 检查 URL、代理设置 |
| 认证失败 | Token 过期 | 更新 Authorization header |
| 工具不存在 | 服务器未启动 | 检查 command/args 配置 |
| stdio 错误 | 命令路径错误 | 使用绝对路径或 npx |

---

## Q5: 如何调试上下文问题？

### 上下文过长

**症状**：
- Claude "忘记" 之前的信息
- 响应变慢
- Token 消耗异常

**诊断**：
```
/context
```

查看当前上下文大小。

**解决方案**：

1. **精简 CLAUDE.md**
   ```markdown
   # 避免：冗长的文档
   ## 详细说明（500行）...

   # 推荐：简洁的要点
   ## 核心规范
   - 使用 TypeScript
   - 测试覆盖率 > 80%
   ```

2. **使用渐进式披露**
   ```
   skills/
   └── my-skill/
       ├── SKILL.md      # 目录页（简洁）
       ├── DETAILS.md    # 详细内容（按需加载）
       └── examples/     # 示例（按需加载）
   ```

3. **分阶段处理**
   ```
   用户：任务太复杂，分阶段处理
   Claude：好的，我们先处理第一阶段...
   ```

### 上下文缺失

**症状**：
- Claude 不知道项目规范
- 重复询问已知信息

**诊断**：
1. 检查 CLAUDE.md 是否存在
2. 检查文件编码（应为 UTF-8）
3. 检查是否有语法错误

**解决方案**：
```bash
# 确认文件存在
ls -la CLAUDE.md

# 检查内容
head -20 CLAUDE.md
```

---

## Q6: 如何调试 Agent 行为问题？

### Agent 不按预期工作

1. **检查 Agent 定义**
   ```bash
   cat .claude/agents/my-agent.md
   ```

2. **验证工具权限**
   ```markdown
   ---
   name: my-agent
   tools: Read, Grep, Glob  # 确保权限正确
   ---
   ```

3. **检查模型选择**
   ```markdown
   ---
   model: sonnet  # 复杂任务用 sonnet
   ---
   ```

### Agent 调试技巧

1. **简化 Prompt 测试**
   ```
   用户：让 my-agent 执行简单任务测试
   ```

2. **检查输出日志**
   - Agent 的输出会在 transcript 中显示
   - 查看是否有错误信息

3. **逐步增加复杂度**
   - 先测试基本功能
   - 再测试复杂场景

### 常见 Agent 问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Agent 不响应 | 名称不匹配 | 检查调用方式 |
| 权限不足 | tools 配置错误 | 添加需要的工具 |
| 输出不符 | Prompt 不清晰 | 优化 System Prompt |
| 响应太慢 | 模型选择不当 | 考虑用 haiku |

---

## Q7: 如何调试 Skill 问题？

### Skill 不触发

1. **检查 description 写法**
   ```markdown
   ---
   description: 当用户提到 "财务分析" 或 "成本" 时使用此技能
   ---
   ```

2. **验证文件位置**
   ```
   .claude/skills/
   └── my-skill/
       └── SKILL.md  # 必须是这个文件名
   ```

3. **检查语法错误**
   ```bash
   # 验证 frontmatter
   head -10 .claude/skills/my-skill/SKILL.md
   ```

### Skill 内容问题

1. **内容未加载**
   - 检查 SKILL.md 是否为空
   - 确认编码为 UTF-8

2. **引用文件不存在**
   ```markdown
   # 检查引用路径
   See [examples](./examples.md)  # 确保文件存在
   ```

### Skill 调试清单

- [ ] SKILL.md 文件存在
- [ ] frontmatter 格式正确
- [ ] description 清晰描述触发条件
- [ ] 引用的文件都存在
- [ ] 没有语法错误

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-error-tracker** | 错误追踪器 | Hook/MCP 问题诊断 |
| **02-log-analyzer** | 日志分析器 | 上下文和性能分析 |

---

## 参考资源

- [Claude Code 故障排除](https://docs.anthropic.com/en/docs/claude-code/troubleshooting)
- [Hooks 调试指南](https://docs.anthropic.com/en/docs/claude-code/hooks#debugging)

---

## 总结

| 问题 | 答案 |
|------|------|
| 问题有哪些类型？ | 配置、权限、上下文、行为、性能、集成 |
| 内置调试命令？ | /debug、/hooks、/mcp、/context |
| 如何调试 Hook？ | 检查配置、验证 JSON、测试脚本 |
| 如何调试 MCP？ | 检查连接、验证配置、测试服务器 |
| 如何调试上下文？ | 检查大小、精简内容、分阶段处理 |
| 如何调试 Agent？ | 检查定义、验证权限、简化测试 |
| 如何调试 Skill？ | 检查 description、验证路径、检查引用 |
