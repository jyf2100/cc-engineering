# 项目 2：质量门禁 Hooks

> 用 PostToolUse 自动格式化、触发测试，确保代码质量

---

## 场景说明

当 Claude 修改代码后，我们希望：
- **自动格式化**：保持代码风格一致
- **自动测试**：确保修改不破坏现有功能
- **自动 lint**：检查代码质量

本项目演示如何用 PostToolUse Hooks 构建质量门禁。

---

## 项目结构

```
02-quality-gates/
├── README.md
├── .claude/
│   └── settings.json           # Hook 配置
├── hooks/
│   ├── post-edit-format.sh     # 自动格式化
│   ├── post-write-test.sh      # 触发相关测试
│   ├── post-edit-lint.sh       # 代码检查
│   └── session-start-context.sh # 会话启动加载上下文
├── src/
│   ├── index.js                # 示例代码
│   └── utils.js                # 工具函数
├── tests/
│   └── index.test.js           # 测试文件
└── package.json
```

---

## Hook 配置

### .claude/settings.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/session-start-context.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/post-edit-format.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/post-edit-lint.sh",
            "timeout": 15
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/post-write-test.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

## Hook 脚本详解

### 1. session-start-context.sh - 会话启动加载上下文

```bash
#!/bin/bash
# SessionStart Hook - 加载开发上下文

# 获取最近的提交和变更
RECENT_CHANGES=$(git log --oneline -5 2>/dev/null || echo "Not a git repo")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
CHANGED_FILES=$(git status --short 2>/dev/null || echo "")

# 构建上下文
CONTEXT="## 开发上下文

当前分支: $CURRENT_BRANCH

### 最近提交
$RECENT_CHANGES

### 未提交的变更
$CHANGED_FILES
"

# 输出 JSON 格式的附加上下文
jq -n \
    --arg ctx "$CONTEXT" \
    '{
        hookSpecificOutput: {
            additionalContext: $ctx
        }
    }'
```

### 2. post-edit-format.sh - 自动格式化

```bash
#!/bin/bash
# PostToolUse Hook - 自动格式化代码

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 检查文件是否存在
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# 根据文件扩展名选择格式化工具
case "$FILE_PATH" in
    *.js|*.jsx|*.ts|*.tsx)
        # 检查是否有 prettier
        if command -v prettier &> /dev/null; then
            prettier --write "$FILE_PATH" 2>/dev/null
            echo "✨ Prettier 格式化完成: $FILE_PATH"
        fi
        ;;
    *.py)
        # 检查是否有 black 或 autopep8
        if command -v black &> /dev/null; then
            black "$FILE_PATH" 2>/dev/null
            echo "✨ Black 格式化完成: $FILE_PATH"
        elif command -v autopep8 &> /dev/null; then
            autopep8 --in-place "$FILE_PATH" 2>/dev/null
            echo "✨ Autopep8 格式化完成: $FILE_PATH"
        fi
        ;;
    *.go)
        if command -v gofmt &> /dev/null; then
            gofmt -w "$FILE_PATH" 2>/dev/null
            echo "✨ Gofmt 格式化完成: $FILE_PATH"
        fi
        ;;
    *.rs)
        if command -v rustfmt &> /dev/null; then
            rustfmt "$FILE_PATH" 2>/dev/null
            echo "✨ Rustfmt 格式化完成: $FILE_PATH"
        fi
        ;;
esac

exit 0
```

### 3. post-edit-lint.sh - 代码检查

```bash
#!/bin/bash
# PostToolUse Hook - 代码质量检查

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 检查文件是否存在
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# 根据文件类型运行不同的 linter
case "$FILE_PATH" in
    *.js|*.jsx)
        if command -v eslint &> /dev/null; then
            RESULT=$(eslint "$FILE_PATH" 2>&1)
            if [[ $? -ne 0 ]]; then
                echo "⚠️ ESLint 问题:"
                echo "$RESULT"
            fi
        fi
        ;;
    *.ts|*.tsx)
        if command -v eslint &> /dev/null; then
            RESULT=$(eslint "$FILE_PATH" 2>&1)
            if [[ $? -ne 0 ]]; then
                echo "⚠️ ESLint 问题:"
                echo "$RESULT"
            fi
        fi
        ;;
    *.py)
        if command -v flake8 &> /dev/null; then
            RESULT=$(flake8 "$FILE_PATH" 2>&1)
            if [[ $? -ne 0 ]]; then
                echo "⚠️ Flake8 问题:"
                echo "$RESULT"
            fi
        fi
        ;;
    *.go)
        if command -v golint &> /dev/null; then
            RESULT=$(golint "$FILE_PATH" 2>&1)
            if [[ -n "$RESULT" ]]; then
                echo "⚠️ Golint 问题:"
                echo "$RESULT"
            fi
        fi
        ;;
esac

exit 0
```

### 4. post-write-test.sh - 触发相关测试

```bash
#!/bin/bash
# PostToolUse Hook - 触发相关测试

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 检查文件是否存在
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# 只对源代码文件触发测试
case "$FILE_PATH" in
    *.js|*.ts|*.jsx|*.tsx)
        # 检查是否有 package.json
        if [[ -f "package.json" ]]; then
            # 尝试运行相关测试
            if grep -q "jest" package.json 2>/dev/null; then
                echo "🧪 运行相关测试..."
                npm test -- --findRelatedTests "$FILE_PATH" --passWithNoTests 2>&1 || true
            elif grep -q "vitest" package.json 2>/dev/null; then
                echo "🧪 运行相关测试..."
                npx vitest run --related "$FILE_PATH" 2>&1 || true
            fi
        fi
        ;;
    *.py)
        # 查找对应的测试文件
        DIR=$(dirname "$FILE_PATH")
        BASENAME=$(basename "$FILE_PATH" .py)
        TEST_FILE=""

        # 尝试多个可能的测试文件位置
        for path in "tests/test_${BASENAME}.py" "test_${BASENAME}.py" "tests/${BASENAME}_test.py"; do
            if [[ -f "$path" ]]; then
                TEST_FILE="$path"
                break
            fi
        done

        if [[ -n "$TEST_FILE" ]]; then
            echo "🧪 运行测试: $TEST_FILE"
            python -m pytest "$TEST_FILE" -v 2>&1 || true
        fi
        ;;
esac

exit 0
```

---

## 学习要点

1. **PostToolUse 在操作后执行**
   - 工具已经执行，无法阻止
   - 适合做后处理（格式化、测试）

2. **SessionStart 注入上下文**
   - 让 Claude 了解当前项目状态
   - 加载最近的 git 变更

3. **多 Hook 协作**
   - 可以配置多个 PostToolUse Hook
   - 按顺序执行（格式化 → lint → 测试）

4. **超时设置**
   - `timeout` 参数控制执行时间
   - 测试可能需要更长超时时间

---

## 工作流程

```
Claude 编辑 src/index.js
         │
         ▼
┌─────────────────┐
│   Edit 工具执行  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ post-edit-format│ → Prettier 格式化
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ post-edit-lint  │ → ESLint 检查
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ post-write-test │ → 运行相关测试
└─────────────────┘
```

---

## 扩展练习

1. **添加类型检查**：TypeScript 项目自动运行 `tsc --noEmit`
2. **添加构建验证**：修改后自动运行构建
3. **通知集成**：测试失败时发送通知
