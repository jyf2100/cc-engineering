# Issue to PR 工作流

## 概述

这个工作流演示如何使用 GitHub MCP 自动化处理 Issue 并生成 PR。

## 前提条件

- GitHub MCP 已配置
- 对目标仓库有写权限

## 步骤

### 1. 分析 Issue

```
用户：查看 my-org/my-repo 的 Issue #123
Claude：[调用 github.getIssue]
       Issue #123: 登录页面加载缓慢
       描述：用户反馈登录页面加载时间超过 5 秒
       标签：bug, performance
```

### 2. 创建修复分支

```
用户：为这个 Issue 创建一个修复分支
Claude：[调用 github.createBranch]
       已创建分支 fix/login-performance，基于 main
```

### 3. 实现修复

```
用户：根据 Issue 描述修复登录页面性能问题
Claude：[分析代码，修改文件]
       已修改以下文件：
       - src/pages/Login.jsx: 添加懒加载
       - src/utils/auth.js: 优化验证逻辑
```

### 4. 创建 PR

```
用户：创建 PR 并关联 Issue
Claude：[调用 github.createPullRequest]
       已创建 PR #124: Fix login page performance
       关联 Issue: #123
       URL: https://github.com/my-org/my-repo/pull/124
```

## 一键执行

```
帮我处理 Issue #123：
1. 查看问题详情
2. 创建修复分支 fix/issue-123
3. 实现修复
4. 创建 PR 并关联 Issue
```

## 注意事项

- 确保 Claude 有适当的权限
- 复杂 Issue 可能需要人工介入
- 建议先在测试环境验证
