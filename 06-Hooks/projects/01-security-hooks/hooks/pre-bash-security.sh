#!/bin/bash
# PreToolUse Hook - Bash 命令安全检查
# Exit 0: 允许执行
# Exit 2: 阻断执行（通过 JSON 输出）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# 危险命令模式列表
DANGEROUS_PATTERNS=(
    # 文件系统破坏
    "rm -rf /"
    "rm -rf /*"
    "rm -rf ~"
    "rm -rf ~/*"
    "rm -rf \.\*"
    "mkfs"
    "dd if=.*of=/dev/"

    # Fork 炸弹
    ":(){ :|:& };:"

    # 远程执行
    "curl .*|.*bash"
    "curl .*|.*sh"
    "wget .*|.*bash"
    "wget .*|.*sh"

    # 权限滥用
    "chmod -R 777 /"
    "chmod -R 777 ~"
    "chmod 777 /etc"

    # 数据库危险操作
    "DROP DATABASE"
    "DROP TABLE"
    "TRUNCATE TABLE"
    "DELETE FROM.*WHERE.*1=1"

    # 敏感信息泄露
    "cat .*/etc/shadow"
    "cat .*/etc/passwd"
    "cat .*id_rsa"
    "cat .*\.pem"

    # 强制推送
    "git push --force"
    "git push -f"
)

# 检查每个危险模式
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        # 输出 JSON 格式的阻断响应
        jq -n \
            --arg reason "🚫 安全策略：禁止执行危险命令 - 匹配模式: $pattern" \
            '{
                permissionDecision: "deny",
                permissionDecisionReason: $reason,
                continue: true
            }'
        exit 0
    fi
done

# 允许执行
exit 0
