#!/bin/bash
# PreToolUse Hook - 写入文件保护
# 检查写入内容和目标路径

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content')

# 检查是否写入系统目录
SYSTEM_PATHS=(
    "^/etc/"
    "^/bin/"
    "^/sbin/"
    "^/usr/bin/"
    "^/usr/sbin/"
    "^/boot/"
    "^/sys/"
    "^/proc/"
    "^/root/"
)

for pattern in "${SYSTEM_PATHS[@]}"; do
    if [[ "$FILE_PATH" =~ $pattern ]]; then
        jq -n \
            --arg path "$FILE_PATH" \
            '{
                permissionDecision: "deny",
                permissionDecisionReason: "🛡️ 系统保护: 禁止写入系统目录 \($path)",
                continue: true
            }'
        exit 0
    fi
done

# 检查内容中是否包含敏感信息模式（警告但不阻止）
SENSITIVE_CONTENT_PATTERNS=(
    "-----BEGIN.*PRIVATE KEY-----"
)

for pattern in "${SENSITIVE_CONTENT_PATTERNS[@]}"; do
    if [[ "$CONTENT" =~ $pattern ]]; then
        echo "⚠️ 警告：写入内容可能包含私钥信息" >&2
        break
    fi
done

exit 0
