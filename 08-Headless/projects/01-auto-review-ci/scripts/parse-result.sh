#!/bin/bash
# 解析 Claude Code 审查结果的脚本

set -e

RESULT_FILE=${1:-review_result.json}

if [[ ! -f "$RESULT_FILE" ]]; then
    echo "Error: Result file not found: $RESULT_FILE"
    exit 1
fi

echo "=== Claude Code Review Result Parser ==="
echo ""

# 提取基本信息
RESULT=$(cat "$RESULT_FILE" | jq -r '.result // empty')
COST=$(cat "$RESULT_FILE" | jq -r '.cost_usd // 0')
DURATION=$(cat "$RESULT_FILE" | jq -r '.duration_ms // 0')
IS_ERROR=$(cat "$RESULT_FILE" | jq -r '.is_error // false')
SESSION_ID=$(cat "$RESULT_FILE" | jq -r '.session_id // empty')

echo "Session ID: $SESSION_ID"
echo "Duration: ${DURATION}ms"
echo "Cost: \$$COST"
echo "Error: $IS_ERROR"
echo ""

if [[ "$IS_ERROR" == "true" ]]; then
    echo "❌ Review failed with error"
    echo "$RESULT"
    exit 1
fi

echo "✅ Review completed successfully"
echo ""

# 尝试解析 JSON 结果
if echo "$RESULT" | jq -e '.issues' > /dev/null 2>&1; then
    echo "=== Issues Found ==="
    echo "$RESULT" | jq -r '.issues[] | "• [\(.severity)] \(.file):\(.line // "?") - \(.description)"'
    echo ""
    echo "Total issues: $(echo "$RESULT" | jq '.issues | length')"
else
    echo "=== Review Summary ==="
    echo "$RESULT"
fi

echo ""
echo "=== Full Result ==="
cat "$RESULT_FILE" | jq '.'
