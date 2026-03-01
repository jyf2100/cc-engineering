# 第 20 讲：举重若轻 · 大型代码库处理技巧

> 当项目文件数以万计时，如何让 Claude 依然高效——索引、分片、增量处理的实战策略

---

## Q1: 大型代码库面临哪些挑战？

### 规模问题

| 指标 | 小型项目 | 大型项目 |
|------|----------|----------|
| 文件数 | < 100 | 10,000+ |
| 代码行数 | < 10,000 | 1,000,000+ |
| 目录层级 | 2-3 层 | 10+ 层 |
| Token 预算 | 充足 | 严重不足 |

### 核心挑战

```
挑战 1：上下文溢出
┌─────────────────────────────────┐
│ CLAUDE.md + 代码 > 200K Token   │ → Claude 无法全部加载
└─────────────────────────────────┘

挑战 2：探索效率低
┌─────────────────────────────────┐
│ Glob "*" → 10,000 文件          │ → 无法逐一分析
└─────────────────────────────────┘

挑战 3：成本过高
┌─────────────────────────────────┐
│ 全量分析 → $10+/次              │ → 预算爆炸
└─────────────────────────────────┘

挑战 4：响应缓慢
┌─────────────────────────────────┐
│ 处理大量文件 → 等待 5 分钟       │ → 效率低下
└─────────────────────────────────┘
```

### 典型场景

- **Monorepo**：多个项目在一个仓库
- **微服务架构**：几十个独立服务
- **遗留系统**：10 年累积的代码
- **开源项目**：数千贡献者的代码

---

## Q2: 如何建立代码库索引？

### CLAUDE.md 作为索引

```markdown
# 项目索引

## 架构概览
```
src/
├── modules/           # 业务模块（10 个）
│   ├── user/         # 用户模块
│   ├── order/        # 订单模块
│   └── payment/      # 支付模块
├── shared/           # 共享组件
├── infrastructure/   # 基础设施
└── tests/            # 测试代码
```

## 入口点
- 主入口：`src/index.ts`
- API：`src/api/routes/`
- 后台任务：`src/workers/`

## 关键文件（优先阅读）
- 架构文档：`docs/architecture.md`
- API 规范：`docs/api-spec.md`
- 配置说明：`docs/config.md`
```

### 索引 Skill

```markdown
# .claude/skills/codebase-index/SKILL.md
---
description: 当用户需要了解代码库结构或查找特定功能时使用
---

## 代码库索引

### 模块清单
| 模块 | 路径 | 职责 |
|------|------|------|
| 用户 | src/modules/user | 用户注册、登录、权限 |
| 订单 | src/modules/order | 订单创建、查询、状态管理 |
| 支付 | src/modules/payment | 支付处理、退款 |

### 快速定位
- 认证逻辑 → `src/modules/user/auth/`
- 数据库模型 → `src/infrastructure/database/models/`
- API 路由 → `src/api/routes/`

### 依赖关系
```
user ← order ← payment
  ↓
notification
```
```

### 目录页模式

```markdown
# SKILL.md（目录页，< 500 Token）
---
description: 大型项目导航
---

## 快速导航
- [用户模块](./modules/user.md)
- [订单模块](./modules/order.md)
- [支付模块](./modules/payment.md）

## 当前焦点
<!-- 只在需要时加载详细内容 -->
```

---

## Q3: 如何实现增量分析？

### 策略：只分析变更

```bash
# 获取最近修改的文件
git diff --name-only HEAD~10 HEAD

# 只分析变更文件
claude -p "分析这些文件的变更影响：$(git diff --name-only HEAD~10 HEAD | tr '\n' ' ')" \
  --allowedTools "Read,Grep"
```

### Git 集成 Hook

```bash
#!/bin/bash
# incremental-analyze.sh - 增量分析

# 获取本次变更的文件
CHANGED_FILES=$(git diff --name-only main...HEAD -- '*.ts' '*.js')

if [[ -z "$CHANGED_FILES" ]]; then
    echo "没有代码变更"
    exit 0
fi

# 只分析变更文件
claude -p "审查这些变更的代码质量：$CHANGED_FILES" \
    --allowedTools "Read,Grep,Glob" \
    --max-turns 5
```

### 变更影响分析

```markdown
# .claude/agents/impact-analyzer.md
---
name: impact-analyzer
description: 分析代码变更的影响范围
tools: Read, Grep, Glob, Bash(git *)
---

当文件被修改时，分析：
1. 直接依赖：哪些文件 import 了这个文件
2. 间接依赖：依赖链上的其他文件
3. 测试覆盖：哪些测试需要更新
4. 文档影响：哪些文档需要同步

输出格式：
- 影响范围：小/中/大
- 需要关注的文件列表
- 建议的测试重点
```

---

## Q4: 如何使用分片处理？

### 模块化探索

```markdown
# .claude/agents/module-explorer.md
---
name: module-explorer
tools: Read, Grep, Glob
---

只探索指定的模块，不越界。
```

**并行探索多个模块**：

```
用户：让 user-explorer、order-explorer、payment-explorer 并行分析各自模块

（3 个 Agent 同时工作，各自只看自己的模块）
```

### 分片规则

```markdown
# CLAUDE.md

## 分析规则

### 分片策略
当处理大型任务时：
1. 先按模块分片
2. 每个分片独立处理
3. 最后汇总结果

### 禁止
- 不要一次性 glob 所有文件
- 不要加载整个 node_modules
- 不要分析 minified 文件
```

### 分片 Skill

```markdown
# .claude/skills/sharding/SKILL.md
---
description: 当任务涉及多个模块或大量文件时自动使用
---

## 分片处理策略

### 识别分片
1. 按模块分片：`src/modules/*/`
2. 按类型分片：`*.test.ts`, `*.ts`
3. 按时间分片：最近 7 天修改的文件

### 处理流程
1. 列出分片
2. 选择相关分片
3. 逐个处理
4. 汇总结果

### 示例
用户：分析所有 API 路由
执行：只看 src/api/routes/*.ts（50 个文件），不看其他
```

---

## Q5: 如何优化文件搜索？

### 精确的 Glob 模式

```bash
# 不推荐：太宽泛
Glob "**/*.ts"  # 匹配 5000+ 文件

# 推荐：精确限定
Glob "src/modules/user/**/*.ts"  # 只匹配用户模块
Glob "src/api/routes/*.ts"       # 只匹配路由
```

### 排除无关目录

```markdown
# CLAUDE.md

## 排除目录
分析时自动排除：
- node_modules/
- dist/
- build/
- .git/
- coverage/
- *.min.js
```

### Grep 优先于 Glob

```
# 不推荐：先找所有文件再读
Glob "**/*.ts" → Read 每个文件

# 推荐：直接搜索内容
Grep "function authenticate" src/
```

### 懒加载策略

```
# 不推荐：一次性加载所有
用户：列出所有 API
Claude：（读取 100 个文件）

# 推荐：按需加载
用户：列出用户相关 API
Claude：（只读取 user 模块的 10 个文件）
```

---

## Q6: 如何处理 Monorepo？

### Monorepo 结构

```
packages/
├── core/           # 核心库
├── api/            # API 服务
├── web/            # 前端应用
├── mobile/         # 移动应用
└── shared/         # 共享代码
```

### Package 级别的 CLAUDE.md

```
packages/
├── core/
│   └── CLAUDE.md     # core 包的规范
├── api/
│   └── CLAUDE.md     # api 包的规范
└── web/
    └── CLAUDE.md     # web 包的规范
```

### Monorepo 根 CLAUDE.md

```markdown
# Monorepo 根配置

## 包概览
| 包 | 职责 | 技术栈 |
|----|------|--------|
| core | 核心业务逻辑 | TypeScript |
| api | REST API | Node.js + Express |
| web | 前端应用 | Next.js |
| mobile | 移动应用 | React Native |

## 工作流
1. 先在 core 中实现核心逻辑
2. 在 api 中暴露接口
3. 在 web/mobile 中调用

## 跨包依赖
- api → core
- web → core
- mobile → core
```

### 单包工作模式

```
用户：只在 api 包中工作，添加用户注册功能

Claude：（只关注 packages/api/ 目录）
```

---

## Q7: 如何控制成本和响应时间？

### 成本控制策略

| 策略 | 方法 | 效果 |
|------|------|------|
| **增量分析** | 只分析变更文件 | 减少 90%+ Token |
| **精确搜索** | 使用精确 Glob | 减少 80% 文件 |
| **模块隔离** | Agent 只看指定模块 | 减少上下文 |
| **模型选择** | 简单任务用 Haiku | 减少 90% 成本 |

### 响应时间优化

```markdown
## 响应时间指南

### 快速响应（< 30s）
- 单模块分析
- 单文件修改
- 简单查询

### 中等响应（30s - 2min）
- 跨模块分析
- 多文件修改
- 复杂重构

### 长时间任务（> 2min）
- 全量代码审查
- 架构分析
- 大规模重构
```

### 超时保护

```bash
# 设置超时
claude -p "分析代码库" \
  --max-turns 10 \
  --timeout 120000  # 2 分钟超时
```

### 进度反馈

```
用户：分析整个代码库的依赖关系

Claude：好的，我将分阶段分析：
✅ 阶段 1/4：分析 core 模块（完成）
🔄 阶段 2/4：分析 api 模块（进行中）
⏳ 阶段 3/4：分析 web 模块（待开始）
⏳ 阶段 4/4：汇总依赖图（待开始）
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-codebase-indexer** | 代码库索引 | 建立索引、快速定位 |
| **02-incremental-analyzer** | 增量分析 | 只分析变更、影响评估 |

---

## 参考资源

- [Claude Code 大型项目指南](https://docs.anthropic.com/en/docs/claude-code/large-projects)
- [Monorepo 最佳实践](https://monorepo.tools/)

---

## 总结

| 问题 | 答案 |
|------|------|
| 挑战有哪些？ | 上下文溢出、探索效率低、成本过高、响应缓慢 |
| 如何建立索引？ | CLAUDE.md 索引、索引 Skill、目录页模式 |
| 如何增量分析？ | Git 集成、变更检测、影响分析 |
| 如何分片处理？ | 模块化探索、分片规则、按需加载 |
| 如何优化搜索？ | 精确 Glob、排除目录、Grep 优先 |
| 如何处理 Monorepo？ | Package 级 CLAUDE.md、跨包依赖、单包模式 |
| 如何控制成本？ | 增量分析、精确搜索、模型选择、超时保护 |
