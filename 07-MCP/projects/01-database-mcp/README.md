# 项目 1：数据库助手 MCP

> 通过 SQLite MCP 让 Claude 直接查询数据库

---

## 场景说明

当 Claude 需要查询数据库时，可以通过 MCP 直接执行 SQL：
- 查询数据进行分析
- 验证数据迁移结果
- 检查数据一致性

---

## 项目结构

```
01-database-mcp/
├── README.md
├── .mcp.json              # MCP 配置（项目级）
├── database/
│   └── sample.db          # 示例数据库
├── queries/
│   └── examples.md        # SQL 示例
└── scripts/
    └── setup-db.sh        # 数据库初始化脚本
```

---

## MCP 配置

### .mcp.json

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-sqlite", "--db-path", "${CLAUDE_PROJECT_DIR}/database/sample.db"]
    }
  }
}
```

### 使用说明

```bash
# 1. 进入项目目录
cd 07-MCP/projects/01-database-mcp

# 2. 初始化数据库
./scripts/setup-db.sh

# 3. 启动 Claude Code
claude

# 4. 查询数据库
# 用户：查询上个月的销售额
# Claude：[调用 sqlite MCP 执行 SQL]
```

---

## 示例对话

```
用户：查询所有用户的数量
Claude：[调用 sqlite.query]
       数据库中共有 1,234 个用户。

用户：最近 7 天注册的用户有多少？
Claude：[调用 sqlite.query]
       最近 7 天注册了 45 个用户。

用户：销售额最高的 5 个产品是什么？
Claude：[调用 sqlite.query]
       销售额最高的 5 个产品是：
       1. Pro 订阅 - ¥128,500
       2. Enterprise 许可 - ¥98,000
       3. ...
```

---

## 学习要点

1. **.mcp.json 放在项目根目录**
   - 自动被 Claude Code 识别
   - 团队共享配置

2. **使用环境变量**
   - `${CLAUDE_PROJECT_DIR}` 指向项目根目录
   - 避免硬编码路径

3. **SQLite MCP 工具**
   - `sqlite.query` - 执行 SQL 查询
   - `sqlite.list_tables` - 列出所有表
   - `sqlite.describe_table` - 查看表结构

---

## 扩展：PostgreSQL

```json
{
  "mcpServers": {
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
