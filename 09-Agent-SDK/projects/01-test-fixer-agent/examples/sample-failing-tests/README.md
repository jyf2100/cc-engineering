# Sample Failing Tests

这个目录包含故意编写错误的代码和测试，用于演示 test-fixer-agent 的功能。

## 文件说明

- `calculator.js` - 包含 Bug 的计算器实现
- `calculator.test.js` - 测试文件（部分会失败）

## 运行测试

```bash
npm test calculator.test.js
```

## 预期输出

运行测试后，会看到以下失败：

```
FAIL calculator.test.js
  ● Calculator › add › should add two positive numbers
    expect(received).toBe(expected)
    Expected: 5
    Received: -1

  ● Calculator › multiply › should multiply two numbers
    expect(received).toBe(expected)
    Expected: 6
    Received: 5
```

## Bug 说明

1. `add(a, b)` 错误地返回 `a - b` 而不是 `a + b`
2. `multiply(a, b)` 错误地返回 `a + b` 而不是 `a * b`

## 使用 test-fixer-agent

```bash
# 将测试输出传递给 agent
npm test 2>&1 | test-fixer

# 或从文件读取
npm test > test-output.txt
test-fixer test-output.txt
```
