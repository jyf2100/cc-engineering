#!/bin/bash
# PostToolUse Hook - 代码质量检查
# 在文件被编辑后自动运行 linter

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 检查文件是否存在
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# 根据文件类型运行不同的 linter
run_lint() {
    local cmd="$1"
    local name="$2"

    if ! command -v "$cmd" &> /dev/null; then
        return
    fi

    local result
    result=$($cmd "$FILE_PATH" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 && -n "$result" ]]; then
        echo "⚠️ $name 发现问题:"
        echo "$result" | head -20  # 限制输出行数
        echo ""
    fi
}

case "$FILE_PATH" in
    *.js|*.jsx)
        run_lint "eslint" "ESLint"
        ;;
    *.ts|*.tsx)
        run_lint "eslint" "ESLint"
        # 也可以运行类型检查
        if command -v tsc &> /dev/null && [[ -f "tsconfig.json" ]]; then
            tsc --noEmit 2>&1 | head -10 || true
        fi
        ;;
    *.py)
        run_lint "flake8" "Flake8"
        run_lint "pylint" "Pylint"
        ;;
    *.go)
        run_lint "golint" "Golint"
        # go vet
        if command -v go &> /dev/null; then
            go vet "$FILE_PATH" 2>&1 | head -10 || true
        fi
        ;;
    *.rs)
        if command -v cargo &> /dev/null; then
            cargo clippy --message-format=short 2>&1 | head -10 || true
        fi
        ;;
    *.sh)
        run_lint "shellcheck" "ShellCheck"
        ;;
esac

exit 0
