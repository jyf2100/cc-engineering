# 第 18 讲：精打细算 · Token 优化与成本控制

> 在享受 Claude 强大能力的同时，掌握成本优化的艺术——让每一分钱都花在刀刃上

---

## Q1: Claude Code 的计费模型是什么？

### 计费基础

Claude Code 的成本基于 **Token 消耗**：

| 类型 | 描述 | 计费 |
|------|------|------|
| **输入 Token** | 发送给 Claude 的内容 | 较低 |
| **输出 Token** | Claude 生成的响应 | 较高 |
| **缓存读取** | 使用缓存的内容 | 极低（约 10%） |

### Token 估算

```
经验法则：
- 1 Token ≈ 4 个英文字符 ≈ 0.75 个英文单词
- 1 Token ≈ 1-2 个中文字符
```

### 成本示例

| 模型 | 输入价格 | 输出价格 | 缓存读取 |
|------|----------|----------|----------|
| Claude Haiku | $0.25/1M | $1.25/1M | $0.03/1M |
| Claude Sonnet | $3.00/1M | $15.00/1M | $0.30/1M |
| Claude Opus | $15.00/1M | $75.00/1M | $1.50/1M |

> 价格仅供参考，以官方最新定价为准

---

## Q2: 如何查看和监控成本？

### 实时查看

在 Claude Code 中：

```
/cost
```

显示当前会话的：
- 输入 Token 数
- 输出 Token 数
- 预估成本

### JSON 输出中的成本

Headless 模式下：

```bash
claude -p "分析代码" --output-format json | jq '.cost_usd'
```

输出：
```json
{
  "cost_usd": 0.0523,
  "input_tokens": 15000,
  "output_tokens": 2000
}
```

### 流式监控

```bash
claude -p "任务" --output-format stream-json --verbose | \
  jq -r 'select(.type=="result") | "Cost: $\(.cost_usd)"'
```

### 成本日志

创建 Hook 记录每次操作成本：

```bash
#!/bin/bash
# post-tool-cost.sh - 记录成本

INPUT=$(cat)
COST=$(echo "$INPUT" | jq -r '.cost_usd // 0')
SESSION=$(echo "$INPUT" | jq -r '.session_id')

echo "$(date),$SESSION,$COST" >> ~/.claude/cost-log.csv
```

---

## Q3: 如何优化 CLAUDE.md 以减少 Token？

### 问题：CLAUDE.md 过长

```markdown
# 不好的做法（2000+ Token）

## 项目概述
这是一个详细的电商平台项目，包含用户管理、商品管理、订单管理、
支付系统、物流跟踪、数据分析、营销活动、客服系统等模块...
（继续 500 行）
```

### 解决方案 1：精简核心信息

```markdown
# 好的做法（200 Token）

# 项目核心

## 技术栈
- Next.js 14 + TypeScript
- PostgreSQL + Prisma
- Tailwind CSS

## 关键规范
- 组件放在 `src/components/`
- API 路由放在 `src/app/api/`
- 测试覆盖率 > 80%

## 禁止
- 禁止使用 any 类型
- 禁止硬编码密钥
```

### 解决方案 2：分层文档

```
CLAUDE.md          # 核心规范（< 500 Token）
.claude/rules/     # 详细规则（按需加载）
  ├── api.md
  ├── frontend.md
  └── database.md
```

### 解决方案 3：使用引用

```markdown
# 不推荐：直接写所有内容
## API 规范
（500 行详细规范）

# 推荐：引用外部文档
## API 规范
详见 [API 设计规范](./docs/api-spec.md)
```

---

## Q4: 如何选择合适的模型？

### 模型选择策略

| 任务类型 | 推荐模型 | 理由 |
|----------|----------|------|
| 简单查询 | Haiku | 快速、便宜 |
| 代码审查 | Haiku/Sonnet | 平衡成本和质量 |
| 复杂重构 | Sonnet | 需要更强理解力 |
| 架构设计 | Opus | 需要深度思考 |
| 大规模探索 | Haiku + 并行 Agent | 分散任务降成本 |

### Agent 模型配置

```markdown
# .claude/agents/code-reviewer.md
---
name: code-reviewer
model: haiku  # 审查任务用 haiku 足够
tools: Read, Grep, Glob
---
```

```markdown
# .claude/agents/architect.md
---
name: architect
model: opus  # 架构决策需要深度思考
tools: Read, Glob
---
```

### 动态模型选择

```
用户：简单检查代码风格
Claude：（使用 Haiku，快速低成本）

用户：设计微服务架构方案
Claude：（使用 Opus，深度分析）
```

---

## Q5: 如何利用缓存降低成本？

### Prompt 缓存机制

Claude 支持 **Prompt 缓存**：
- 重复的输入内容会被缓存
- 缓存命中时成本降低约 90%

### 利用缓存的技巧

1. **保持 System Prompt 稳定**
   ```
   # 缓存友好：固定的系统提示
   你是一个代码审查专家...

   # 缓存不友好：每次都变化的提示
   当前时间是 2024-01-15 10:30:25...
   ```

2. **结构化重复内容**
   ```markdown
   # CLAUDE.md 保持稳定，会被缓存
   ## 项目规范
   ...（固定内容）
   ```

3. **使用 CLAUDE.md 而非每次重复**
   ```
   # 不推荐：每次都说明
   用户：按照 TypeScript 最佳实践，使用函数式组件...

   # 推荐：在 CLAUDE.md 中定义
   用户：审查这个组件
   ```

### 缓存命中率监控

```bash
# 查看缓存效果
claude -p "分析代码" --output-format json | \
  jq '.cache_read_input_tokens, .cache_creation_input_tokens'
```

---

## Q6: 如何优化任务执行策略？

### 策略 1：任务分解

```
# 高成本：一次性大任务
用户：重构整个用户模块，包括认证、权限、配置

# 低成本：分阶段执行
用户：第一阶段：分析用户模块结构
      第二阶段：重构认证部分
      第三阶段：重构权限部分
```

### 策略 2：并行 Agent

```markdown
# 使用多个低成本 Agent 并行
用户：让 api-explorer、db-explorer、auth-explorer 并行分析各模块
```

成本对比：
- 单个 Opus Agent：$0.50
- 3 个并行 Haiku Agent：$0.15

### 策略 3：增量处理

```
# 高成本：全量分析
用户：分析所有 500 个文件

# 低成本：增量分析
用户：只分析最近修改的 10 个文件
```

### 策略 4：提前终止

```bash
# 限制迭代次数
claude -p "修复 bug" --max-turns 5
```

---

## Q7: 如何设置成本预算和告警？

### 设置预算限制

```bash
# 使用 Hooks 检查成本
# .claude/settings.json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/check-budget.sh"
          }
        ]
      }
    ]
  }
}
```

### 成本检查脚本

```bash
#!/bin/bash
# check-budget.sh - 成本预算检查

DAILY_BUDGET=5.00  # 每日预算 $5
COST_FILE="$HOME/.claude/daily-cost"

# 获取今日成本
TODAY=$(date +%Y-%m-%d)
CURRENT_COST=$(grep "^$TODAY" "$COST_FILE" 2>/dev/null | cut -d',' -f2 || echo "0")

if (( $(echo "$CURRENT_COST > $DAILY_BUDGET" | bc -l) )); then
  jq -n '{decision: "continue", reason: "⚠️ 今日成本已超预算: $'"$CURRENT_COST"'"}'
fi

exit 0
```

### 成本告警 Hook

```bash
#!/bin/bash
# cost-alert.sh - 成本告警

INPUT=$(cat)
COST=$(echo "$INPUT" | jq -r '.cost_usd // 0')

# 单次操作超过 $0.50 告警
if (( $(echo "$COST > 0.50" | bc -l) )); then
  echo "⚠️ 本次操作成本较高: \$$COST" >&2
fi
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-token-optimizer** | Token 优化器 | 分析和优化 CLAUDE.md |
| **02-cost-monitor** | 成本监控器 | 实时监控和预算告警 |

---

## 参考资源

- [Claude 定价](https://www.anthropic.com/pricing)
- [Prompt 缓存](https://docs.anthropic.com/claude/docs/prompt-caching)

---

## 总结

| 问题 | 答案 |
|------|------|
| 计费模型？ | 按输入/输出 Token 计费，缓存读取成本极低 |
| 如何监控成本？ | /cost 命令、JSON 输出、Hook 日志 |
| 如何优化 CLAUDE.md？ | 精简核心、分层文档、使用引用 |
| 如何选择模型？ | 简单任务 Haiku、复杂任务 Sonnet/Opus |
| 如何利用缓存？ | 保持 Prompt 稳定、使用 CLAUDE.md |
| 执行策略？ | 任务分解、并行 Agent、增量处理、提前终止 |
| 如何设置预算？ | Hook 检查、成本告警脚本 |
