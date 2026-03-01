# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是极客时间专栏《Claude Code 工程化实战》的配套代码仓库，包含课程所有示例项目和练习代码。

## 目录结构

```
XX-ChapterName/
├── README.md        # 章节说明（详细讲解参见极客时间课程）
└── projects/        # 实战示例项目
    ├── 01-basic/    # 基础示例
    └── 02-advanced/ # 进阶示例
```

### 章节内容

| 章节 | 主题 | 状态 |
|------|------|------|
| 02-Memory | CLAUDE.md 记忆系统 | 已发布 |
| 03-SubAgents | 子代理与任务分发 | 已发布 |
| 04-Skills | Agent Skills 能力包 | 已发布 |
| 05-Commands | 自定义斜杠命令 | 已发布 |
| 06-Hooks | 钩子与自动化控制 | 即将上线 |
| 07-MCP | 外部工具集成协议 | 即将上线 |
| 08-Headless | CI/CD 与自动化 | 即将上线 |
| 09-Agent-SDK | 编程式 Agent 开发 | 即将上线 |
| 10-Plugins | 插件打包与分发 | 即将上线 |

## 核心概念关系

```
                    ┌──────────────┐
                    │   Plugins    │  容器
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Commands   │  │    Skills    │  │     MCP      │
│  用户触发     │  │  自动发现    │  │  外部工具     │
└──────────────┘  └──────────────┘  └──────────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    Hooks     │  控制所有工具执行
                    └──────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  SubAgents   │  │   Memory     │  │  Headless    │
│  任务分发     │  │  上下文持久   │  │  非交互执行   │
└──────────────┘  └──────────────┘  └──────────────┘
```

## 配置文件位置

| 类型 | 位置 | 用途 |
|------|------|------|
| 子代理 | `.claude/agents/*.md` | 定义专职角色的能力和边界 |
| Skills | `.claude/skills/*/SKILL.md` | 定义自动发现的能力包 |
| Commands | `.claude/commands/*.md` | 定义斜杠命令 |
| 项目记忆 | `CLAUDE.md` | 项目级上下文（团队共享） |

## 示例项目说明

### SubAgents 章节 (03-SubAgents)

- **01-code-reviewer**: 只读型代码审查器，演示最小权限原则
- **02-test-runner**: 测试运行器，演示高噪声任务处理
- **03-log-analyzer**: 日志分析器，演示日志消化和结论提炼
- **04-parallel-explore**: 多代理并行探索 api/auth/db 模块
- **05-bugfix-pipeline**: Bug 修复流水线（定位→分析→修复→验证）
- **06-agent-teams-bug-hunt**: 多代理团队协作找 Bug

### Skills 章节 (04-Skills)

- **01-basic-skill**: 基础 Skill 结构
- **02-progressive-skill**: 渐进式披露架构（目录页→章节→附录）
- **03-financial-skill**: 财务分析 Skill（带 reference 和 templates）
- **04-api-generator**: API 生成器（结合模板、脚本）
- **05-agent-skill-combo**: Agent + Skill 组合模式
- **08-skill-pipeline**: 多 Stage 流水线 Skill

## 技术栈

- Node.js 18+（示例项目）
- Python 3.10+（Agent SDK 示例）
- Claude Code CLI

## 注意事项

- 示例代码中的安全问题（如硬编码密钥）是**故意设计的**，用于演示审查能力
- 各项目的 `.claude/` 目录包含 Agent/Skill/Command 定义，是学习的重点
- 部分章节（06-10）内容即将上线，目前只有 README.md
