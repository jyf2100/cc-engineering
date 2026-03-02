# MCP 使用示例

本文档包含 GitHub 和 Sentry MCP 的常见使用场景。

## GitHub 操作示例

### 查看 Issue

```
用户：帮我看看 my-org/my-repo 最新的 5 个 Issue
Claude：[调用 github MCP]
       最近的 5 个 Issue：
       #123: 登录页面加载缓慢 - open
       #122: 用户无法修改密码 - open
       #121: API 返回 500 错误 - in progress
```

### 创建分支

```
用户：给 Issue #123 创建一个修复分支
Claude：[调用 github MCP]
       已创建分支 fix/login-performance，基于 main。
```

### 提交 PR

```
用户：帮我创建一个 PR，标题是"修复登录性能问题"
Claude：[调用 github MCP]
       已创建 PR #124：修复登录性能问题
       https://github.com/my-org/my-repo/pull/124
```

## Sentry 操作示例

### 查看错误

```
用户：分析最近 24 小时的错误
Claude：[调用 sentry MCP]
       最近 24 小时有 15 个错误：
       - NullPointerError in UserService.java:45 (8 次)
       - TimeoutError in APIConnector.js:120 (5 次)
       - ValidationError in auth.py:89 (2 次)
```

### 分析堆栈

```
用户：帮我分析 NullPointerError 的原因
Claude：[调用 sentry MCP 获取堆栈]
       这个错误发生在 UserService.getUserById() 方法中，
       当 userId 为 null 时会触发。建议添加参数验证...
```

## 组合使用

### Issue → 修复 → PR

```
用户：帮我处理 Issue #123:
1. 查看问题描述
2. 分析错误日志（Sentry）
3. 创建修复分支
4. 实现修复
5. 创建 PR

Claude：[组合使用 GitHub 和 Sentry MCP]
       正在处理...
       1. Issue #123: 登录页面加载缓慢
       2. 发现 TimeoutError 在 /api/login 端点
       3. 已创建分支 fix/issue-123
       4. 已优化数据库查询
       5. 已创建 PR #125
```
