# Code Review Workflow

使用 GitHub MCP 进行代码审查的流程。

## 步骤

### 1. 获取 PR 信息

```
让 Claude 查看 PR #xxx 的变更
```

### 2. 审查代码质量

```
让 Claude 审查 PR #xxx 的代码质量
```

### 3. 检查安全问题

```
让 Claude 检查 PR #xxx 是否有安全风险
```

### 4. 发布审查评论

```
让 Claude 在 PR #xxx 上发布审查结果
```

## 示例 Prompt

```
帮我审查 PR #123：
1. 查看变更的文件
2. 检查代码质量
3. 识别潜在问题
4. 提供改进建议
```

## GitHub MCP 工具

| 工具 | 描述 |
|------|------|
| `github.get_pr` | 获取 PR 信息 |
| `github.get_pr_diff` | 获取 PR diff |
| `github.create_review` | 创建审查评论 |
| `github.list_pr_files` | 列出变更文件 |
