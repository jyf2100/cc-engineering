# Error Debug Workflow

使用 Sentry MCP 调试错误的流程。

## 步骤

### 1. 获取错误列表

```
让 Claude 查看最近 24 小时的错误
```

### 2. 分析具体错误

```
让 Claude 分析 [错误ID] 的堆栈信息
```

### 3. 定位问题代码

```
让 Claude 找到导致错误的代码位置
```

### 4. 提出修复方案

```
让 Claude 提出修复建议
```

## 示例 Prompt

```
帮我调试最近的生产错误：
1. 列出最近 24 小时最严重的 5 个错误
2. 分析每个错误的可能原因
3. 标注需要优先处理的问题
```

## Sentry MCP 工具

| 工具 | 描述 |
|------|------|
| `sentry.list_errors` | 列出错误 |
| `sentry.get_error` | 获取错误详情 |
| `sentry.get_stacktrace` | 获取堆栈信息 |
