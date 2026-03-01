# 第 22 讲：众志成城 · 团队协作最佳实践

> 让 Claude Code 成为团队的统一助手——规范共享、知识沉淀、协作流程的工程化实践

---

## Q1: 团队使用 Claude Code 有哪些挑战？

### 常见问题

| 挑战 | 描述 | 影响 |
|------|------|------|
| **配置不一致** | 每人配置不同 | 行为不统一 |
| **知识碎片化** | 经验分散在个人 | 难以复用 |
| **规范难执行** | 依赖口头传达 | 执行打折扣 |
| **审查效率低** | 人工审查慢 | 发布周期长 |
| **新人上手慢** | 缺乏文档 | 培训成本高 |

### 解决思路

```
问题                     解决方案
─────────────────────────────────────
配置不一致     →    项目级 CLAUDE.md（Git 共享）
知识碎片化     →    团队 Skills（能力沉淀）
规范难执行     →    Hooks 自动检查（强制执行）
审查效率低     →    Agent 自动审查（提效）
新人上手慢     →    文档 + Agent 引导（加速）
```

### 团队协作架构

```
┌─────────────────────────────────┐
│        团队 Git 仓库             │
│  ┌─────────────────────────┐   │
│  │ CLAUDE.md               │   │  ← 团队共享规范
│  │ .claude/                │   │
│  │   ├── agents/           │   │  ← 团队 Agent
│  │   ├── skills/           │   │  ← 团队 Skill
│  │   ├── commands/         │   │  ← 团队 Command
│  │   └── settings.json     │   │  ← 团队 Hook
│  └─────────────────────────┘   │
└─────────────────────────────────┘
           ↑
    ┌──────┴──────┐
    │             │
┌───▼───┐    ┌───▼───┐
│ 开发A │    │ 开发B │
└───────┘    └───────┘
  同步配置     同步配置
```

---

## Q2: 如何共享团队配置？

### 项目级 CLAUDE.md

```markdown
# 团队项目规范

## 技术栈
- 框架：Next.js 14 + TypeScript
- 样式：Tailwind CSS
- 测试：Vitest + Testing Library
- 数据库：PostgreSQL + Prisma

## 目录结构
```
src/
├── app/           # Next.js App Router
├── components/    # React 组件
├── lib/           # 工具函数
└── types/         # TypeScript 类型
```

## 编码规范
### 命名
- 组件：PascalCase（Button.tsx）
- 函数：camelCase（getUserById）
- 常量：UPPER_SNAKE（MAX_RETRY）

### 注释
- 公共函数必须有 JSDoc
- 复杂逻辑必须解释原因

## 禁止
- ❌ 使用 any 类型
- ❌ 内联样式（用 Tailwind）
- ❌ 直接调用 API（用 lib/api）

## Git 规范
- 分支：feature/xxx, fix/xxx
- Commit：feat/fix/docs/style/refactor
```

### 团队 settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/team-security-check.sh"
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
            "command": ".claude/hooks/team-format-check.sh"
          }
        ]
      }
    ]
  }
}
```

### .gitignore 配置

```gitignore
# 共享配置（提交到 Git）
!.claude/
!.claude/agents/
!.claude/skills/
!.claude/commands/
!.claude/settings.json

# 本地配置（不提交）
.claude/settings.local.json
```

---

## Q3: 如何沉淀团队知识？

### 团队 Skill 示例

```markdown
# .claude/skills/team-api/SKILL.md
---
description: 当创建或修改 API 端点时使用此技能
---

## API 设计规范

### RESTful 约定
| 方法 | 用途 | 示例 |
|------|------|------|
| GET | 获取资源 | GET /users |
| POST | 创建资源 | POST /users |
| PUT | 全量更新 | PUT /users/1 |
| PATCH | 部分更新 | PATCH /users/1 |
| DELETE | 删除资源 | DELETE /users/1 |

### 响应格式
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "total": 100
  }
}
```

### 错误处理
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "参数验证失败",
    "details": [...]
  }
}
```

### 命名约定
- 路由：kebab-case（/user-profiles）
- 字段：camelCase（firstName）
- 枚举：UPPER_SNAKE（USER_STATUS_ACTIVE）

## 参考
- 详细规范：docs/api-spec.md
- 示例代码：examples/api/
```

### 知识库结构

```
.claude/
├── skills/
│   ├── team-api/          # API 规范
│   │   └── SKILL.md
│   ├── team-frontend/     # 前端规范
│   │   └── SKILL.md
│   └── team-database/     # 数据库规范
│       └── SKILL.md
├── commands/
│   ├── review.md          # 代码审查
│   ├── deploy.md          # 部署命令
│   └── new-feature.md     # 新功能模板
└── agents/
    ├── reviewer.md        # 审查 Agent
    └── deployer.md        # 部署 Agent
```

### 最佳实践文档

```markdown
# docs/best-practices/README.md

## 团队最佳实践

### 代码相关
- [API 设计规范](./api-design.md)
- [前端组件规范](./frontend-components.md)
- [数据库设计规范](./database-design.md)

### 流程相关
- [代码审查流程](./code-review.md)
- [发布流程](./release.md)
- [Bug 修复流程](./bug-fix.md)

### 工具相关
- [Claude Code 使用指南](./claude-code-guide.md)
- [Git 工作流](./git-workflow.md)
```

---

## Q4: 如何自动化代码审查？

### 审查 Agent

```markdown
# .claude/agents/team-reviewer.md
---
name: team-reviewer
description: 团队标准代码审查
tools: Read, Grep, Glob, Bash(git diff*)
model: sonnet
---

## 审查清单

### 必查项
- [ ] 代码风格符合规范
- [ ] 无 TypeScript 错误
- [ ] 有足够的测试
- [ ] 无安全漏洞

### 加分项
- [ ] 代码有注释
- [ ] 有性能考虑
- [ ] 错误处理完善

## 输出格式
### 审查结果
| 类别 | 状态 | 说明 |
|------|------|------|
| 代码风格 | ✅/❌ | ... |
| 类型安全 | ✅/❌ | ... |
| 测试覆盖 | ✅/❌ | ... |
| 安全检查 | ✅/❌ | ... |

### 建议
1. ...
2. ...

### 结论
- 是否可以合并：是/否
- 需要修改：[文件列表]
```

### 审查 Command

```markdown
# .claude/commands/review.md
---
description: 审查当前分支的代码变更
allowed-tools: Read,Grep,Glob,Bash(git diff*)
---

审查当前分支相对于 main 的所有代码变更。

## 审查维度
1. 代码风格
2. 类型安全
3. 测试覆盖
4. 安全问题
5. 性能影响

## 输出
- 问题列表（按严重程度）
- 改进建议
- 是否建议合并
```

### CI 集成

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

      - name: Claude Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "审查这个 PR 的代码变更" \
            --allowedTools "Read,Grep,Glob,Bash(git diff*)" \
            --output-format json > review.json

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = JSON.parse(fs.readFileSync('review.json'));
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: review.result
            });
```

---

## Q5: 如何加速新人上手？

### 新人引导 Agent

```markdown
# .claude/agents/onboarding-guide.md
---
name: onboarding-guide
description: 帮助新成员了解项目
tools: Read, Glob
model: haiku
---

## 引导流程

### 第 1 天：了解项目
1. 项目背景和目标
2. 技术栈介绍
3. 目录结构说明
4. 开发环境搭建

### 第 2-3 天：熟悉代码
1. 核心模块讲解
2. 关键文件导读
3. 运行第一个功能

### 第 4-5 天：开始贡献
1. 领取简单任务
2. 代码规范检查
3. 提交第一个 PR

## 回答原则
- 耐心解释，不假设背景知识
- 提供代码示例
- 指向相关文档
- 鼓励提问
```

### 新人 Command

```markdown
# .claude/commands/onboarding.md
---
description: 新人入职引导
---

帮助新成员了解项目。

## 根据用户的问题提供：
1. 项目概览
2. 技术栈说明
3. 代码结构介绍
4. 开发流程指导
5. 常见问题解答

## 参考文档
- README.md
- docs/architecture.md
- docs/development.md
```

### 入职文档模板

```markdown
# docs/onboarding.md

## 欢迎加入团队！

### 第一步：环境准备
1. 安装 Node.js 18+
2. 克隆仓库：git clone ...
3. 安装依赖：npm install
4. 复制环境变量：cp .env.example .env
5. 启动开发：npm run dev

### 第二步：了解项目
- [ ] 阅读 README.md
- [ ] 阅读 docs/architecture.md
- [ ] 运行测试：npm test
- [ ] 启动项目，访问 localhost:3000

### 第三步：领取任务
1. 查看 "Good First Issue" 标签
2. 在 Issue 下留言认领
3. 创建分支开始开发

### 遇到问题？
- 使用 /onboarding 命令询问 Claude
- 在 Slack #dev 频道提问
- 查看团队 Wiki
```

---

## Q6: 如何建立知识共享机制？

### 知识共享 Skill

```markdown
# .claude/skills/knowledge-sharing/SKILL.md
---
description: 当需要记录或查找团队知识时使用
---

## 知识库结构

### 按类型
- 技术决策：docs/decisions/
- 问题解决：docs/troubleshooting/
- 最佳实践：docs/best-practices/
- 会议记录：docs/meetings/

### 按模块
- 用户模块：docs/modules/user/
- 订单模块：docs/modules/order/
- 支付模块：docs/modules/payment/

## 贡献指南
1. 解决问题后记录到 docs/troubleshooting/
2. 新功能开发后更新 docs/modules/
3. 技术决策记录到 docs/decisions/

## 格式模板
（提供各类文档的模板）
```

### 代码注释规范

```markdown
# CLAUDE.md

## 代码注释要求

### 复杂逻辑
```typescript
// 为什么这样做：
// 历史原因：旧 API 返回格式不一致
// 解决方案：在这里做兼容处理
// TODO：API 升级后移除此逻辑
function normalizeResponse(data) {
  // ...
}
```

### 业务规则
```typescript
/**
 * 计算用户等级
 *
 * 规则来源：产品文档 v2.1
 * - 消费满 1000 元升级银卡
 * - 消费满 5000 元升级金卡
 * - 消费满 10000 元升级钻石
 *
 * @see docs/business/user-level.md
 */
function calculateUserLevel(totalSpent: number): Level {
  // ...
}
```
```

### 定期知识整理

```markdown
# 使用 Claude 整理知识

用户：帮我整理这个月的 Bug 修复，生成知识库文档

Claude：
1. 分析本月的 Git commit
2. 提取 Bug 修复相关内容
3. 生成 docs/troubleshooting/bug-fixes-YYYY-MM.md
```

---

## Q7: 如何度量团队使用效果？

### 度量指标

| 指标 | 描述 | 目标 |
|------|------|------|
| **代码审查覆盖率** | AI 审查的 PR 比例 | > 80% |
| **问题发现率** | AI 发现的问题/总问题 | > 50% |
| **新人上手时间** | 从入职到首个 PR | < 5 天 |
| **规范遵守率** | 通过 Hook 检查的比例 | > 95% |
| **文档更新频率** | 知识库更新次数 | > 10/月 |

### 数据收集 Hook

```bash
#!/bin/bash
# team-metrics.sh - 收集团队使用数据

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')
USER=$(git config user.email || echo "unknown")
DATE=$(date +%Y-%m-%d)

# 记录到日志
echo "$DATE,$USER,$EVENT" >> .claude/metrics/usage.csv
```

### 周报生成

```markdown
# .claude/commands/weekly-report.md
---
description: 生成本周团队使用报告
---

分析本周的团队活动，生成报告。

## 报告内容
1. 代码审查次数
2. 主要修改的模块
3. 发现的问题统计
4. 文档更新情况
5. 改进建议

## 数据来源
- Git commit 历史
- 代码审查记录
- Hook 日志
```

### 效果评估

```markdown
# 团队使用效果评估（月度）

## 量化指标
| 指标 | 上月 | 本月 | 变化 |
|------|------|------|------|
| 代码审查覆盖率 | 60% | 85% | +25% |
| 平均审查时间 | 4h | 1h | -75% |
| 新人上手时间 | 10天 | 4天 | -60% |

## 定性反馈
- 开发者满意度：4.2/5
- 主要优点：快速、一致、可追溯
- 待改进：复杂场景处理

## 下月计划
1. 扩展 Skill 覆盖范围
2. 优化 Hook 响应时间
3. 增加更多团队命令
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-team-standards** | 团队规范 | 共享配置、知识沉淀 |
| **02-code-review-flow** | 代码审查流程 | 自动审查、CI 集成 |

---

## 参考资源

- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [代码审查最佳实践](https://google.github.io/eng-practices/review/)

---

## 总结

| 问题 | 答案 |
|------|------|
| 团队挑战有哪些？ | 配置不一致、知识碎片化、规范难执行 |
| 如何共享配置？ | 项目级 CLAUDE.md、settings.json |
| 如何沉淀知识？ | 团队 Skill、知识库结构、最佳实践文档 |
| 如何自动审查？ | 审查 Agent、审查 Command、CI 集成 |
| 如何加速上手？ | 引导 Agent、入职 Command、入职文档 |
| 如何共享知识？ | 知识 Skill、代码注释、定期整理 |
| 如何度量效果？ | 使用指标、数据收集、周报生成 |
