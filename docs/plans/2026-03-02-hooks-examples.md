# 计划：为 06-Hooks 项目添加代码示例

## 背景

06-Hooks 项目的 01-security-hooks 和 02-quality-gates 缺少 README 中描述的示例代码文件。

## 任务列表

### Task 1: 01-security-hooks 添加 src 目录

**Files**:
- Create: `06-Hooks/projects/01-security-hooks/src/app.js`
- Create: `06-Hooks/projects/01-security-hooks/src/config.js`

**Step 1**: 创建 src 目录和示例文件
```bash
mkdir -p 06-Hooks/projects/01-security-hooks/src
```

**Step 2**: 创建 app.js - 一个简单的 Express 应用示例
**Step 3**: 创建 config.js - 配置文件示例（故意包含一些敏感信息模式用于演示）

### Task 2: 01-security-hooks 添加 test-cases 目录

**Files**:
- Create: `06-Hooks/projects/01-security-hooks/test-cases/dangerous-operations.md`

**Step 1**: 创建 test-cases 目录
```bash
mkdir -p 06-Hooks/projects/01-security-hooks/test-cases
```

**Step 2**: 创建测试用例文档，列出应该被阻止和允许的操作

### Task 3: 02-quality-gates 添加 src 目录

**Files**:
- Create: `06-Hooks/projects/02-quality-gates/src/index.js`
- Create: `06-Hooks/projects/02-quality-gates/src/utils.js`

**Step 1**: 创建 src 目录
```bash
mkdir -p 06-Hooks/projects/02-quality-gates/src
```

**Step 2**: 创建 index.js - 带有一些故意的不规范代码（用于演示格式化）
**Step 3**: 创建 utils.js - 工具函数

### Task 4: 02-quality-gates 添加 tests 目录

**Files**:
- Create: `06-Hooks/projects/02-quality-gates/tests/index.test.js`

**Step 1**: 创建 tests 目录
```bash
mkdir -p 06-Hooks/projects/02-quality-gates/tests
```

**Step 2**: 创建 Jest 测试文件

### Task 5: 02-quality-gates 添加 package.json

**Files**:
- Create: `06-Hooks/projects/02-quality-gates/package.json`

**Step 1**: 创建 package.json，包含必要的依赖和脚本

## 验证

```bash
# 检查文件结构
tree 06-Hooks/projects/01-security-hooks
tree 06-Hooks/projects/02-quality-gates
```

## 风险

- 无重大风险，这是纯添加操作
