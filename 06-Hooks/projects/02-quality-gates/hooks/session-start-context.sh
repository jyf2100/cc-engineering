#!/bin/bash
# SessionStart Hook - 加载开发上下文
# 在会话开始时自动注入项目上下文

# 获取最近的提交和变更
RECENT_CHANGES=$(git log --oneline -5 2>/dev/null || echo "Not a git repo")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
CHANGED_FILES=$(git status --short 2>/dev/null || echo "")

# 检查是否有 package.json 并提取项目信息
PROJECT_INFO=""
if [[ -f "package.json" ]]; then
    PROJECT_NAME=$(jq -r '.name // "unnamed"' package.json 2>/dev/null)
    PROJECT_VERSION=$(jq -r '.version // "0.0.0"' package.json 2>/dev/null)
    PROJECT_INFO="项目: $PROJECT_NAME@$PROJECT_VERSION"
fi

# 构建上下文
CONTEXT="## 开发上下文

### 项目信息
$PROJECT_INFO

### 当前分支
$CURRENT_BRANCH

### 最近提交
\`\`\`
$RECENT_CHANGES
\`\`\`

### 未提交的变更
\`\`\`
$CHANGED_FILES
\`\`\`
"

# 输出 JSON 格式的附加上下文
jq -n \
    --arg ctx "$CONTEXT" \
    '{
        hookSpecificOutput: {
            additionalContext: $ctx
        }
    }'
