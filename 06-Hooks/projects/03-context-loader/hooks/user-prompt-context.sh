#!/bin/bash
# UserPromptSubmit Hook - 预处理用户输入
# 检测关键词并注入相关上下文

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt')

ADDITIONAL_CONTEXT=""

# 如果提到 "bug" 或 "错误"，注入最近的错误日志
if [[ "$PROMPT" =~ [Bb]ug ]] || [[ "$PROMPT" =~ 错误 ]] || [[ "$PROMPT" =~ 修复 ]]; then
    if [[ -d "$CLAUDE_PROJECT_DIR/logs" ]]; then
        LATEST_LOG=$(ls -t "$CLAUDE_PROJECT_DIR/logs"/*.log 2>/dev/null | head -1)
        if [[ -n "$LATEST_LOG" ]]; then
            ERROR_CONTEXT=$(tail -50 "$LATEST_LOG" 2>/dev/null | grep -A 5 -i "error\|exception\|fail" | head -20)
            if [[ -n "$ERROR_CONTEXT" ]]; then
                ADDITIONAL_CONTEXT="### 最近的错误日志
\`\`\`
$ERROR_CONTEXT
\`\`\`"
            fi
        fi
    fi
fi

# 如果提到 "测试"，注入测试命令
if [[ "$PROMPT" =~ [Tt]est ]] || [[ "$PROMPT" =~ 测试 ]]; then
    if [[ -f "$CLAUDE_PROJECT_DIR/package.json" ]]; then
        TEST_CMD=$(jq -r '.scripts.test // "npm test"' "$CLAUDE_PROJECT_DIR/package.json" 2>/dev/null)
        ADDITIONAL_CONTEXT="$ADDITIONAL_CONTEXT

### 测试命令
\`\`\`bash
$TEST_CMD
\`\`\`"
    fi
fi

# 如果提到 "部署" 或 "deploy"，注入部署信息
if [[ "$PROMPT" =~ [Dd]eploy ]] || [[ "$PROMPT" =~ 部署 ]]; then
    if [[ -f "$CLAUDE_PROJECT_DIR/package.json" ]]; then
        DEPLOY_CMD=$(jq -r '.scripts.deploy // "未配置部署脚本"' "$CLAUDE_PROJECT_DIR/package.json" 2>/dev/null)
        ADDITIONAL_CONTEXT="$ADDITIONAL_CONTEXT

### 部署命令
\`\`\`bash
$DEPLOY_CMD
\`\`\`"
    fi
fi

# 如果提到 "API" 或 "接口"，注入 API 目录结构
if [[ "$PROMPT" =~ [Aa][Pp][Ii] ]] || [[ "$PROMPT" =~ 接口 ]]; then
    if [[ -d "$CLAUDE_PROJECT_DIR/src/api" ]]; then
        API_STRUCTURE=$(find "$CLAUDE_PROJECT_DIR/src/api" -name "*.js" -o -name "*.ts" 2>/dev/null | head -10)
        if [[ -n "$API_STRUCTURE" ]]; then
            ADDITIONAL_CONTEXT="$ADDITIONAL_CONTEXT

### API 文件结构
\`\`\`
$API_STRUCTURE
\`\`\`"
        fi
    fi
fi

# 如果有附加上下文，输出
if [[ -n "$ADDITIONAL_CONTEXT" ]]; then
    jq -n \
        --arg ctx "$ADDITIONAL_CONTEXT" \
        '{
            hookSpecificOutput: {
                additionalContext: $ctx
            }
        }'
fi

exit 0
