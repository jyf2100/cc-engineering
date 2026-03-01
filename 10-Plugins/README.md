# 第 10 讲：化零为整 · Plugins 插件打包与分发

> 把 Commands、Skills、Agents、Hooks 组合成可复用的插件，实现团队资产沉淀与共享

---

## Q1: Plugins 是什么？

### Plugins 的定义

**Plugins** 是 Claude Code 的"能力容器"——将 Commands、Skills、Agents、Hooks、MCP 配置打包成一个可分发、可安装、可管理的单元。

### 核心价值

```
没有 Plugins：
  每个 Commands/Skills/Agents 分散管理 → 难以共享

有了 Plugins：
  打包成一个插件 → 一键安装、版本管理、团队共享
```

### 在 Claude Code 技术栈中的位置

```
Claude Code 技术栈
├── Plugins（顶层容器）  ← 这里：能力打包与分发
│   ├── Slash Commands（用户手动触发）
│   ├── Skills（Claude 自动推理触发）
│   ├── MCP Servers（外部工具连接）
│   └── Hooks（事件驱动）
├── CLAUDE.md（记忆系统）
├── Sub-Agents（子代理）
└── Agent SDK（编程接口）
```

### Plugin 包含的组件

| 组件 | 目录 | 描述 |
|------|------|------|
| **Commands** | `commands/` | 斜杠命令 |
| **Agents** | `agents/` | 子代理定义 |
| **Skills** | `skills/` | 能力包 |
| **Hooks** | `hooks/` | 事件钩子 |
| **MCP Servers** | `.mcp.json` | MCP 服务器配置 |

---

## Q2: plugin.json 结构是什么？

### 基本结构

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "插件描述",
  "author": "your-name",
  "repository": "https://github.com/your-org/my-plugin",
  "keywords": ["code-review", "automation"],
  "license": "MIT"
}
```

### 完整结构

```json
{
  "name": "team-standards-plugin",
  "version": "2.1.0",
  "description": "团队编码规范和质量检查插件",
  "author": "my-team",
  "repository": "https://github.com/my-org/claude-plugins",
  "keywords": ["standards", "quality", "lint"],
  "license": "MIT",

  "mcpServers": {
    "team-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"],
      "env": {
        "API_KEY": "${TEAM_API_KEY}"
      }
    }
  }
}
```

### 字段说明

| 字段 | 必需 | 描述 |
|------|------|------|
| `name` | ✅ | 插件名称（唯一标识） |
| `version` | ✅ | 语义化版本号 |
| `description` | ✅ | 插件描述 |
| `author` | ❌ | 作者/团队 |
| `repository` | ❌ | 代码仓库地址 |
| `keywords` | ❌ | 关键词（便于搜索） |
| `license` | ❌ | 许可证 |
| `mcpServers` | ❌ | 插件提供的 MCP 服务器 |

### 特殊环境变量

| 变量 | 描述 |
|------|------|
| `${CLAUDE_PLUGIN_ROOT}` | 插件根目录路径 |

---

## Q3: 目录结构规范是什么？

### 标准目录结构

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # 插件清单（必需）
│
├── commands/                 # 斜杠命令（可选）
│   ├── review.md
│   ├── lint.md
│   └── git/
│       ├── commit.md
│       └── push.md
│
├── agents/                   # 子代理（可选）
│   ├── code-reviewer.md
│   └── security-scanner.md
│
├── skills/                   # Skills（可选）
│   ├── code-quality/
│   │   └── SKILL.md
│   └── api-conventions/
│       └── SKILL.md
│
├── hooks/                    # Hooks（可选）
│   └── hooks.json
│
├── .mcp.json                 # MCP 服务器（可选）
│
├── servers/                  # MCP 服务器代码（可选）
│   └── api-server.js
│
└── README.md                 # 插件说明
```

### 组件目录详解

#### commands/

```markdown
# commands/review.md
---
description: Review code for quality and security
argument-hint: [file or directory]
allowed-tools: Read,Grep,Glob
---

Review the following code for quality and security issues: $ARGUMENTS
```

#### agents/

```markdown
# agents/code-reviewer.md
---
name: code-reviewer
description: Review code changes for quality, security, and best practices
tools: Read,Grep,Glob
model: sonnet
---

You are a code reviewer. Focus on:
- Security vulnerabilities
- Code quality
- Performance issues
- Best practices
```

#### skills/

```markdown
# skills/code-quality/SKILL.md
---
description: Code quality analysis and improvement suggestions
---

Analyze code quality and provide actionable improvement suggestions.
```

#### hooks/hooks.json

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

---

## Q4: 如何使用 Plugin CLI？

### 基本命令

```bash
# 打开插件管理界面
/plugin

# 查看已安装插件
/plugin list
```

### 安装插件

```bash
# 从 Marketplace 安装
/plugin install plugin-name@marketplace-name

# 从 Git 仓库安装
/plugin install github:your-org/your-plugin

# 从本地路径安装
/plugin install ./path/to/plugin
```

### 管理插件

```bash
# 启用插件
/plugin enable plugin-name@marketplace-name

# 禁用插件
/plugin disable plugin-name@marketplace-name

# 卸载插件
/plugin uninstall plugin-name@marketplace-name

# 更新插件
/plugin update plugin-name@marketplace-name
```

### Marketplace 管理

```bash
# 添加 Marketplace
/plugin marketplace add your-org/claude-plugins

# 列出 Marketplace
/plugin marketplace list

# 刷新 Marketplace
/plugin marketplace refresh
```

---

## Q5: 如何创建和分发 Plugin？

### 创建 Plugin 步骤

1. **创建目录结构**
   ```bash
   mkdir -p my-plugin/.claude-plugin
   mkdir -p my-plugin/commands
   mkdir -p my-plugin/agents
   mkdir -p my-plugin/skills
   ```

2. **创建 plugin.json**
   ```json
   {
     "name": "my-plugin",
     "version": "1.0.0",
     "description": "My awesome plugin"
   }
   ```

3. **添加组件**
   - 添加 Commands 到 `commands/`
   - 添加 Agents 到 `agents/`
   - 添加 Skills 到 `skills/`

4. **测试插件**
   ```bash
   # 本地安装测试
   /plugin install ./my-plugin
   ```

### 分发方式

#### 1. Git 仓库

```bash
# 创建仓库
git init
git add .
git commit -m "Initial release"
git push origin main

# 安装
/plugin install github:your-org/your-plugin
```

#### 2. Marketplace

创建 `marketplace.json`：

```json
{
  "name": "my-marketplace",
  "description": "My team's Claude plugins",
  "plugins": [
    {
      "name": "code-quality",
      "path": "plugins/code-quality",
      "version": "1.0.0"
    },
    {
      "name": "team-standards",
      "path": "plugins/team-standards",
      "version": "2.0.0"
    }
  ]
}
```

---

## Q6: 如何配置团队 Plugin？

### 项目级配置

在 `.claude/settings.json` 中配置：

```json
{
  "plugins": {
    "marketplaces": [
      "your-org/claude-plugins"
    ],
    "enabled": [
      "code-quality@your-org",
      "team-standards@your-org",
      "reviewer@your-org"
    ]
  }
}
```

### 自动安装

当团队成员克隆项目后，Claude Code 会自动：
1. 读取 `.claude/settings.json`
2. 添加配置的 Marketplaces
3. 安装并启用配置的插件

### Plugin 优先级

```
项目级 Plugin > 用户级 Plugin > 内置功能
```

同名命令/技能时，项目级优先。

---

## Q7: 实战应用场景有哪些？

### 场景 1：代码质量 Plugin

```json
{
  "name": "code-quality",
  "version": "1.0.0",
  "description": "代码质量检查和改进"
}
```

```
code-quality/
├── .claude-plugin/plugin.json
├── commands/
│   ├── review.md        # /review 代码审查
│   ├── lint.md          # /lint 代码检查
│   └── format.md        # /format 代码格式化
├── agents/
│   └── quality-guard.md # 质量守卫 Agent
└── skills/
    └── code-quality/
        └── SKILL.md
```

### 场景 2：团队规范 Plugin

```json
{
  "name": "team-standards",
  "version": "2.0.0",
  "description": "团队编码规范和最佳实践"
}
```

```
team-standards/
├── .claude-plugin/plugin.json
├── commands/
│   ├── check-style.md   # /check-style 检查风格
│   ├── generate-docs.md # /generate-docs 生成文档
│   └── validate-pr.md   # /validate-pr 验证 PR
├── skills/
│   ├── api-conventions/
│   │   └── SKILL.md
│   └── git-conventions/
│       └── SKILL.md
└── reference/
    ├── api-design.md
    └── naming-conventions.md
```

### 场景 3：DevOps Plugin

```json
{
  "name": "devops-tools",
  "version": "1.5.0",
  "description": "DevOps 工具集"
}
```

```
devops-tools/
├── .claude-plugin/plugin.json
├── commands/
│   ├── deploy.md        # /deploy 部署
│   ├── rollback.md      # /rollback 回滚
│   └── status.md        # /status 查看状态
├── agents/
│   ├── deployer.md      # 部署 Agent
│   └── monitor.md       # 监控 Agent
└── .mcp.json            # MCP 配置（Kubernetes API 等）
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-code-quality-plugin** | 代码质量 Plugin | 完整 Plugin 开发流程 |
| **02-team-standards-plugin** | 团队规范 Plugin | 团队级 Plugin 配置与分发 |

---

## 参考资源

- [Plugins 官方文档](https://docs.anthropic.com/en/docs/claude-code/plugins)
- [Awesome Claude Plugins](https://github.com/topics/claude-plugins)

---

## 总结

| 问题 | 答案 |
|------|------|
| Plugins 是什么？ | 能力容器，打包 Commands/Skills/Agents/Hooks/MCP |
| plugin.json 结构？ | name、version、description、mcpServers 等 |
| 目录结构规范？ | .claude-plugin/、commands/、agents/、skills/、hooks/ |
| 如何安装？ | `/plugin install` 从 Marketplace 或 Git 安装 |
| 如何分发？ | Git 仓库或 Marketplace |
| 如何团队配置？ | `.claude/settings.json` 中配置 marketplaces 和 enabled |
