# 项目 2：开发工具链 MCP

> 集成 GitHub 和 Sentry，让 Claude 直接操作开发工具

---

## 场景说明

通过 MCP 连接开发工具链：
- **GitHub**: 查看 Issue、创建 PR、审查代码
- **Sentry**: 查看错误、分析崩溃、追踪问题

---

## 项目结构

```
02-dev-tools-mcp/
├── README.md
├── .mcp.json              # MCP 配置
├── workflows/
│   ├── issue-to-pr.md     # Issue 转 PR 工作流
│   ├── error-debug.md     # 错误调试工作流
│   └── code-review.md     # 代码审查工作流
└── examples/
    └── usage.md           # 使用示例
```

---

## MCP 配置

### .mcp.json

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
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

### 环境变量设置

```bash
# 在 .env 或 shell 中设置
export GITHUB_TOKEN="ghp_xxxxx"
export SENTRY_TOKEN="sntrys_xxxxx"
```

---

## 示例对话

### GitHub 操作

```
用户：帮我看看 my-org/my-repo 最新的 5 个 Issue
Claude：[调用 github MCP]
       最近的 5 个 Issue：
       #123: 登录页面加载缓慢 - open
       #122: 用户无法修改密码 - open
       #121: API 返回 500 错误 - in progress
       ...

用户：给 Issue #123 创建一个修复分支
Claude：[调用 github MCP]
       已创建分支 fix/login-performance，基于 main。
```

### Sentry 错误分析

```
用户：分析最近 24 小时的错误
Claude：[调用 sentry MCP]
       最近 24 小时有 15 个错误：
       - NullPointerError in UserService.java:45 (8 次)
       - TimeoutError in APIConnector.js:120 (5 次)
       - ValidationError in auth.py:89 (2 次)

用户：帮我分析 NullPointerError 的原因
Claude：[调用 sentry MCP 获取堆栈]
       这个错误发生在 UserService.getUserById() 方法中，
       当 userId 为 null 时会触发。建议添加参数验证...
```

---

## 工作流文档

### workflows/issue-to-pr.md

```markdown
# Issue to PR 工作流

## 步骤

1. **分析 Issue**
   ```
   让 Claude 查看 Issue #xxx 的详情
   ```

2. **创建分支**
   ```
   让 Claude 创建修复分支
   ```

3. **实现修复**
   ```
   让 Claude 根据 Issue 描述修改代码
   ```

4. **创建 PR**
   ```
   让 Claude 创建 PR 并关联 Issue
   ```

## 示例 Prompt

```
帮我处理 Issue #123:
1. 查看问题描述
2. 创建修复分支 fix/issue-123
3. 实现修复
4. 创建 PR 并关联 Issue
```
```

---

## 学习要点

1. **HTTP MCP 需要认证**
   - 使用 `headers` 配置
   - 通过环境变量注入 Token

2. **多个 MCP 可以组合使用**
   - GitHub + Sentry 形成完整开发工具链
   - Claude 自动选择合适的 MCP

3. **安全性**
   - Token 存储在环境变量中
   - 不要提交到 Git
