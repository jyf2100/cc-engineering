#!/bin/bash
# SessionStart Hook - 加载开发上下文
# 在会话开始时自动注入项目上下文

# 读取项目说明
PROJECT_CONTEXT=""
if [[ -f "$CLAUDE_PROJECT_DIR/context/project.md" ]]; then
    PROJECT_CONTEXT=$(cat "$CLAUDE_PROJECT_DIR/context/project.md")
fi

# 读取待办事项
TODOS=""
if [[ -f "$CLAUDE_PROJECT_DIR/context/todos.md" ]]; then
    TODOS=$(cat "$CLAUDE_PROJECT_DIR/context/todos.md")
fi

# 获取 Git 状态
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_STATUS=$(git status --short 2>/dev/null || echo "工作区干净")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "无提交历史")

# 获取上次会话状态
LAST_SESSION_INFO=""
if [[ -f "$CLAUDE_PROJECT_DIR/state/session.json" ]]; then
    LAST_SESSION=$(cat "$CLAUDE_PROJECT_DIR/state/session.json")
    LAST_TASK=$(echo "$LAST_SESSION" | jq -r '.last_task // empty' 2>/dev/null)
    ENDED_AT=$(echo "$LAST_SESSION" | jq -r '.ended_at // empty' 2>/dev/null)
    if [[ -n "$LAST_TASK" ]]; then
        LAST_SESSION_INFO="### 上次未完成任务
- $LAST_TASK
- 结束时间: $ENDED_AT"
    fi
fi

# 构建完整上下文
CONTEXT="## 🚀 会话上下文

### 当前分支
\`$GIT_BRANCH\`

### 最近提交
\`\`\`
$RECENT_COMMITS
\`\`\`

### 未提交的变更
\`\`\`
$GIT_STATUS
\`\`\`

### 项目说明
$PROJECT_CONTEXT

### 待办事项
$TODOS

$LAST_SESSION_INFO
"

# 输出 JSON 格式的附加上下文
jq -n \
    --arg ctx "$CONTEXT" \
    '{
        hookSpecificOutput: {
            additionalContext: $ctx
        }
    }'
