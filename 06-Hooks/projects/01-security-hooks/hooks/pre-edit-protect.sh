#!/bin/bash
# PreToolUse Hook - 保护敏感文件不被编辑
# Exit 0: 允许执行
# Exit 2: 阻断执行（通过 JSON 输出）

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# 敏感文件模式
PROTECTED_PATTERNS=(
    "\.env$"
    "\.env\."
    "credentials"
    "\.pem$"
    "\.key$"
    "id_rsa"
    "id_ed25519"
    "\.npmrc$"
    "\.pypirc$"
    "secrets?\."
    "config/secrets"
    "\.git/config"
    "\.git/credentials"
)

# 检查文件路径
for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" =~ $pattern ]]; then
        jq -n \
            --arg path "$FILE_PATH" \
            '{
                permissionDecision: "deny",
                permissionDecisionReason: "🔒 敏感文件保护: 禁止修改 \($path)",
                continue: true
            }'
        exit 0
    fi
done

# 允许执行
exit 0
