#!/bin/bash
# Stop Hook - 检查任务完成度，阻止过早停止
# 如果有未完成的待办事项，让 Claude 继续

INPUT=$(cat)

# 读取待办事项
TODOS_FILE="$CLAUDE_PROJECT_DIR/context/todos.md"
if [[ ! -f "$TODOS_FILE" ]]; then
    exit 0
fi

TODOS=$(cat "$TODOS_FILE")

# 检查是否有未完成的待办（匹配 "- [ ]" 模式）
UNFINISHED=$(echo "$TODOS" | grep -c "^\- \[ \]" 2>/dev/null || echo "0")

if [[ "$UNFINISHED" -gt 0 ]]; then
    # 获取第一个未完成的任务
    NEXT_TASK=$(echo "$TODOS" | grep "^\- \[ \]" | head -1 | sed 's/^- \[ \] //')

    # 输出 JSON 让 Claude 继续
    jq -n \
        --argjson count "$UNFINISHED" \
        --arg task "$NEXT_TASK" \
        '{
            decision: "continue",
            reason: "📋 还有 \($count) 个待办事项未完成。下一个任务: \($task)"
        }'
    exit 0
fi

# 所有任务已完成，正常退出
exit 0
