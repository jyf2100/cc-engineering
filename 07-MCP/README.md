# 第 7 讲：海纳百川 · MCP 协议与外部工具连接

> 通过 Model Context Protocol，把数据库、API、第三方服务变成 Claude 可调用的工具

---

## Q1: MCP 是什么？

### MCP 的定义

**MCP (Model Context Protocol)** 是 Anthropic 推出的开放协议，让 Claude 能够连接外部工具和数据源。Claude Code 内置 MCP 客户端，可以调用任何 MCP 服务器提供的工具。

### 核心价值

```
没有 MCP：
  Claude 只能操作文件系统 → 能力有限

有了 MCP：
  Claude → GitHub MCP → 创建 PR、管理 Issue
  Claude → 数据库 MCP → 查询数据、执行 SQL
  Claude → Sentry MCP → 查看错误、分析崩溃
```

### 在 Claude Code 技术栈中的位置

```
Claude Code 技术栈
├── Plugins（顶层容器）
│   ├── Slash Commands（用户手动触发）
│   ├── Skills（Claude 自动推理触发）
│   ├── MCP Servers（外部工具连接）  ← 这里：无限扩展能力
│   └── Hooks（事件驱动）
├── CLAUDE.md（记忆系统）
├── Sub-Agents（子代理）
└── Agent SDK（编程接口）
```

### MCP 架构

```
┌─────────────────┐
│   Claude Code   │  MCP Client
└────────┬────────┘
         │ MCP Protocol
         │
    ┌────┴────┬────────────┬────────────┐
    │         │            │            │
    ▼         ▼            ▼            ▼
┌───────┐ ┌───────┐  ┌───────┐  ┌───────┐
│GitHub │ │Sentry │  │  DB   │  │Custom │
│  MCP  │ │  MCP  │  │  MCP  │  │  MCP  │
└───────┘ └───────┘  └───────┘  └───────┘
```

---

## Q2: 有哪些传输类型？

### 三种传输类型

| 类型 | 适用场景 | 启动方式 | 示例 |
|------|----------|----------|------|
| **HTTP** | 云端服务（推荐） | URL 连接 | GitHub、Notion、Sentry |
| **SSE** | Server-Sent Events | URL 连接 | Asana、实时推送服务 |
| **stdio** | 本地进程 | 命令启动 | SQLite、PostgreSQL、自定义服务 |

### HTTP 传输

最常用的方式，连接云端 MCP 服务：

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

### stdio 传输

启动本地进程作为 MCP 服务器：

```bash
# SQLite 数据库
claude mcp add --transport stdio sqlite -- npx -y @anthropic-ai/mcp-server-sqlite --db-path ./data.db

# PostgreSQL
claude mcp add --transport stdio postgres -- npx -y @anthropic-ai/mcp-server-postgres "postgresql://user:pass@localhost/db"
```

### 选择建议

| 场景 | 推荐类型 | 理由 |
|------|----------|------|
| 云端 API | HTTP | 直接连接，无需本地配置 |
| 本地数据库 | stdio | 直接访问本地资源 |
| 需要实时推送 | SSE | 支持服务器主动推送 |
| 自定义服务 | stdio | 灵活控制 |

---

## Q3: 配置 Scope 有什么区别？

### 三种 Scope

| Scope | 存储位置 | 共享范围 | 用途 |
|-------|----------|----------|------|
| **local** | 项目级、不提交 | 仅自己 | 个人实验配置 |
| **project** | `.mcp.json` | 团队共享 | 团队标准工具 |
| **user** | `~/.claude.json` | 跨项目 | 个人常用工具 |

### Scope 示意图

```
~/.claude.json (user scope)
├── GitHub MCP      ← 所有项目可用
└── Notion MCP      ← 所有项目可用

项目 A/.mcp.json (project scope)
├── 项目 A 的 DB    ← 团队共享
└── 项目 A 的 API   ← 团队共享

项目 A/.claude.json (local scope)
└── 个人测试 MCP    ← 仅自己可见
```

### CLI 指定 Scope

```bash
# 项目级（团队共享）
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/

# 用户级（跨项目）
claude mcp add --scope user --transport http notion https://mcp.notion.com/mcp

# 本地级（默认）
claude mcp add --transport stdio sqlite -- npx -y mcp-server-sqlite
```

---

## Q4: 如何使用 CLI 管理 MCP？

### 核心命令

```bash
# 添加 MCP 服务器
claude mcp add --transport <type> <name> <url-or-command>

# 列出所有服务器
claude mcp list

# 查看详情
claude mcp get <name>

# 移除服务器
claude mcp remove <name>
```

### 添加示例

```bash
# HTTP 类型
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# 带认证头
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp \
  --header "Authorization: Bearer your-token"

# stdio 类型（本地数据库）
claude mcp add --transport stdio sqlite -- \
  npx -y @anthropic-ai/mcp-server-sqlite --db-path ./database.db

# 带环境变量
claude mcp add --transport stdio postgres -- \
  npx -y @anthropic-ai/mcp-server-postgres \
  --connection-string "$DATABASE_URL"
```

### 在 Claude Code 内查看

```
/mcp
```

显示当前加载的所有 MCP 服务器及其工具。

---

## Q5: .mcp.json 配置格式是什么？

### 基本结构

```json
{
  "mcpServers": {
    "<server-name>": {
      "type": "http",
      "url": "https://api.example.com/mcp"
    }
  }
}
```

### HTTP 服务器配置

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp",
      "headers": {
        "Authorization": "Bearer ${SENTRY_TOKEN}"
      }
    }
  }
}
```

### stdio 服务器配置

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-sqlite", "--db-path", "./data.db"]
    },
    "postgres": {
      "command": "uvx",
      "args": ["mcp-server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

### 环境变量扩展

支持在配置中使用环境变量：

| 语法 | 描述 |
|------|------|
| `${VAR}` | 展开为环境变量值 |
| `${VAR:-default}` | 带默认值 |

```json
{
  "mcpServers": {
    "api": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

---

## Q6: 有哪些热门 MCP 服务器？

### 官方推荐

| 服务器 | 功能 | 传输类型 | 安装命令 |
|--------|------|----------|----------|
| **GitHub** | PR/Issue/仓库操作 | HTTP | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| **Notion** | 文档和数据库 | HTTP | `claude mcp add --transport http notion https://mcp.notion.com/mcp` |
| **Sentry** | 错误监控 | HTTP | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| **SQLite** | 本地数据库 | stdio | `claude mcp add --transport stdio sqlite -- npx -y mcp-server-sqlite` |
| **PostgreSQL** | 数据库查询 | stdio | `claude mcp add --transport stdio postgres -- uvx mcp-server-postgres` |
| **Filesystem** | 文件系统扩展 | stdio | `claude mcp add --transport stdio fs -- npx -y @anthropic-ai/mcp-server-filesystem` |

### 按用途分类

#### 开发工具

| MCP 服务器 | 提供的能力 |
|------------|-----------|
| GitHub | 创建/更新 PR、管理 Issue、查看代码 |
| GitLab | MR 操作、Issue 管理 |
| Bitbucket | 仓库操作 |

#### 数据存储

| MCP 服务器 | 提供的能力 |
|------------|-----------|
| SQLite | 执行 SQL、查询数据 |
| PostgreSQL | 数据库操作 |
| MySQL | 数据库操作 |
| Redis | 缓存操作 |

#### 监控与日志

| MCP 服务器 | 提供的能力 |
|------------|-----------|
| Sentry | 查看错误、分析堆栈 |
| Datadog | 查看指标、日志 |
| Logflare | 日志查询 |

#### 协作工具

| MCP 服务器 | 提供的能力 |
|------------|-----------|
| Notion | 读取/创建文档 |
| Slack | 发送消息、读取频道 |
| Jira | 管理 Issue |

---

## Q7: 实战应用场景有哪些？

### 场景 1：数据库查询

```bash
# 配置 SQLite MCP
claude mcp add --transport stdio sqlite -- \
  npx -y @anthropic-ai/mcp-server-sqlite --db-path ./app.db
```

```
用户：查询上个月的销售额
Claude：[调用 sqlite MCP 执行 SQL] 上个月销售额为 ¥128,500
```

### 场景 2：GitHub 自动化

```bash
# 配置 GitHub MCP
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

```
用户：帮我看一下 my-org/my-repo 的最新 Issue
Claude：[调用 github MCP] 最新 Issue #123: 登录页面加载缓慢
```

### 场景 3：错误分析

```bash
# 配置 Sentry MCP
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp \
  --header "Authorization: Bearer ${SENTRY_TOKEN}"
```

```
用户：分析最近 24 小时的错误
Claude：[调用 sentry MCP] 发现 15 个错误，最严重的是 NullPointer 在 UserService.java:45
```

### 场景 4：文档管理

```bash
# 配置 Notion MCP
claude mcp add --transport http notion https://mcp.notion.com/mcp
```

```
用户：把 API 设计文档同步到 Notion
Claude：[调用 notion MCP] 已创建页面：API 设计文档 v2.0
```

---

## 项目概览

| 项目 | 主题 | 学习目标 |
|------|------|----------|
| **01-database-mcp** | 数据库助手 | SQLite/PostgreSQL MCP 配置与使用 |
| **02-dev-tools-mcp** | 开发工具链 | GitHub/Sentry MCP 集成 |
| **03-custom-mcp** | 自定义 MCP Server | 从零开发 MCP 服务器 |

---

## 参考资源

- [MCP 官方文档](https://docs.anthropic.com/en/docs/claude-code/mcp)
- [MCP 协议规范](https://modelcontextprotocol.io/)
- [Awesome MCP Servers](https://github.com/punkpeye/awesome-mcp-servers)

---

## 总结

| 问题 | 答案 |
|------|------|
| MCP 是什么？ | Model Context Protocol，连接外部工具的开放协议 |
| 有哪些传输类型？ | HTTP（云端）、SSE（实时）、stdio（本地） |
| Scope 有什么区别？ | local（个人）、project（团队）、user（跨项目） |
| 如何配置？ | CLI 命令或 `.mcp.json` 文件 |
| 有哪些热门服务器？ | GitHub、Sentry、SQLite、PostgreSQL、Notion |
