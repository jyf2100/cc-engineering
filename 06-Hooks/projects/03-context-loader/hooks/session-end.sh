#!/bin/bash
# SessionEnd Hook - 保存会话状态
# 在会话结束时保存状态，以便下次恢复

INPUT=$(cat)

# 提取会话信息
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# 确保状态目录存在
mkdir -p "$CLAUDE_PROJECT_DIR/state"

# 保存会话状态
jq -n \
    --arg sid "$SESSION_ID" \
    --arg time "$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)" \
    '{
        session_id: $sid,
        ended_at: $time,
        last_task: ""
    }' > "$CLAUDE_PROJECT_DIR/state/session.json"

# 输出日志（会显示在 transcript）
echo "📝 会话状态已保存到 state/session.json"
