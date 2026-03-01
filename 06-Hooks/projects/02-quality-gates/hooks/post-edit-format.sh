#!/bin/bash
# PostToolUse Hook - 自动格式化代码
# 在文件被编辑后自动运行格式化工具

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 检查文件是否存在
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# 根据文件扩展名选择格式化工具
case "$FILE_PATH" in
    *.js|*.jsx|*.ts|*.tsx|*.json|*.md|*.yaml|*.yml)
        # 检查是否有 prettier
        if command -v prettier &> /dev/null; then
            prettier --write "$FILE_PATH" 2>/dev/null && \
                echo "✨ Prettier 格式化完成: $FILE_PATH"
        fi
        ;;
    *.py)
        # Python 格式化工具
        if command -v black &> /dev/null; then
            black "$FILE_PATH" 2>/dev/null && \
                echo "✨ Black 格式化完成: $FILE_PATH"
        elif command -v autopep8 &> /dev/null; then
            autopep8 --in-place "$FILE_PATH" 2>/dev/null && \
                echo "✨ Autopep8 格式化完成: $FILE_PATH"
        fi
        ;;
    *.go)
        if command -v gofmt &> /dev/null; then
            gofmt -w "$FILE_PATH" 2>/dev/null && \
                echo "✨ Gofmt 格式化完成: $FILE_PATH"
        fi
        ;;
    *.rs)
        if command -v rustfmt &> /dev/null; then
            rustfmt "$FILE_PATH" 2>/dev/null && \
                echo "✨ Rustfmt 格式化完成: $FILE_PATH"
        fi
        ;;
    *.java)
        if command -v google-java-format &> /dev/null; then
            google-java-format -i "$FILE_PATH" 2>/dev/null && \
                echo "✨ Google Java Format 完成: $FILE_PATH"
        fi
        ;;
esac

exit 0
