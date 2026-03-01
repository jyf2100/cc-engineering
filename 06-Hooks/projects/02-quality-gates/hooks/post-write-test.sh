#!/bin/bash
# PostToolUse Hook - 触发相关测试
# 在源代码文件被修改后自动运行相关测试

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 检查文件是否存在
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# 跳过测试文件本身和非源代码文件
case "$FILE_PATH" in
    *.test.js|*.spec.js|*.test.ts|*.spec.ts|*_test.py|test_*.py)
        exit 0
        ;;
    *.md|*.txt|*.json|*.yaml|*.yml|*.toml)
        exit 0
        ;;
esac

# 根据文件类型运行测试
case "$FILE_PATH" in
    *.js|*.ts|*.jsx|*.tsx)
        # 检查是否有 package.json
        if [[ -f "package.json" ]]; then
            # 尝试运行相关测试
            if grep -q '"jest"' package.json 2>/dev/null; then
                echo "🧪 运行 Jest 相关测试..."
                npx jest --findRelatedTests "$FILE_PATH" --passWithNoTests 2>&1 | tail -20 || true
            elif grep -q '"vitest"' package.json 2>/dev/null; then
                echo "🧪 运行 Vitest 相关测试..."
                npx vitest run --related "$FILE_PATH" 2>&1 | tail -20 || true
            elif grep -q '"mocha"' package.json 2>/dev/null; then
                echo "🧪 运行 Mocha 测试..."
                npm test 2>&1 | tail -20 || true
            fi
        fi
        ;;
    *.py)
        # 查找对应的测试文件
        DIR=$(dirname "$FILE_PATH")
        BASENAME=$(basename "$FILE_PATH" .py)
        TEST_FILE=""

        # 尝试多个可能的测试文件位置
        for path in \
            "tests/test_${BASENAME}.py" \
            "test/test_${BASENAME}.py" \
            "tests/${BASENAME}_test.py" \
            "${DIR}/test_${BASENAME}.py" \
            "test_${BASENAME}.py"
        do
            if [[ -f "$path" ]]; then
                TEST_FILE="$path"
                break
            fi
        done

        if [[ -n "$TEST_FILE" ]]; then
            echo "🧪 运行测试: $TEST_FILE"
            python -m pytest "$TEST_FILE" -v 2>&1 | tail -20 || true
        else
            # 没找到特定测试文件，尝试运行所有测试
            if [[ -d "tests" ]] || [[ -d "test" ]]; then
                echo "🧪 运行所有测试..."
                python -m pytest -v 2>&1 | tail -20 || true
            fi
        fi
        ;;
    *.go)
        # Go 测试
        echo "🧪 运行 Go 测试..."
        go test ./... 2>&1 | tail -20 || true
        ;;
    *.rs)
        # Rust 测试
        if command -v cargo &> /dev/null; then
            echo "🧪 运行 Cargo 测试..."
            cargo test 2>&1 | tail -20 || true
        fi
        ;;
esac

exit 0
