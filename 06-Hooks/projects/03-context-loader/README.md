# 项目 3：上下文加载 Hooks

> 用 SessionStart/Stop 管理会话上下文，让 Claude "记住"更多

---

## 场景说明

Claude 每次启动新会话时，上下文是空的。本项目演示如何：

- **SessionStart**: 自动加载项目上下文、最近变更、待办事项
- **Stop**: 检查任务完成度，阻止过早停止
- **UserPromptSubmit**: 自动注入上下文到用户输入

---

## 项目结构

```
03-context-loader/
├── README.md
├── .claude/
│   └── settings.json           # Hook 配置
├── hooks/
│   ├── session-start.sh        # 会话启动加载上下文
│   ├── session-end.sh          # 会话结束保存状态
│   ├── stop-continue.sh        # 阻止过早停止
│   └── user-prompt-context.sh  # 用户输入预处理
├── context/
│   ├── project.md              # 项目说明
│   └── todos.md                # 待办事项
└── state/
    └── session.json            # 会话状态
```

---

## Hook 配置

### .claude/settings.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/session-start.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/session-end.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/stop-continue.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/user-prompt-context.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Hook 脚本详解

### 1. session-start.sh - 会话启动加载上下文

```bash
#!/bin/bash
# SessionStart Hook - 加载开发上下文

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
GIT_STATUS=$(git status --short 2>/dev/null || echo "")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "")

# 获取上次会话状态
LAST_SESSION=""
if [[ -f "$CLAUDE_PROJECT_DIR/state/session.json" ]]; then
    LAST_SESSION=$(cat "$CLAUDE_PROJECT_DIR/state/session.json")
    LAST_TASK=$(echo "$LAST_SESSION" | jq -r '.last_task // empty')
    if [[ -n "$LAST_TASK" ]]; then
        LAST_SESSION="上次未完成任务: $LAST_TASK"
    else
        LAST_SESSION=""
    fi
fi

# 构建完整上下文
CONTEXT="## 🚀 会话上下文

### 当前分支
$GIT_BRANCH

### 最近提交
$RECENT_COMMITS

### 未提交的变更
$GIT_STATUS

### 项目说明
$PROJECT_CONTEXT

### 待办事项
$TODOS

$LAST_SESSION
"

# 输出 JSON 格式的附加上下文
jq -n \
    --arg ctx "$CONTEXT" \
    '{
        hookSpecificOutput: {
            additionalContext: $ctx
        }
    }'
```

### 2. session-end.sh - 会话结束保存状态

```bash
#!/bin/bash
# SessionEnd Hook - 保存会话状态

INPUT=$(cat)

# 提取会话信息
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# 确保状态目录存在
mkdir -p "$CLAUDE_PROJECT_DIR/state"

# 保存会话状态
jq -n \
    --arg sid "$SESSION_ID" \
    --arg time "$(date -Iseconds)" \
    '{
        session_id: $sid,
        ended_at: $time
    }' > "$CLAUDE_PROJECT_DIR/state/session.json"

echo "📝 会话状态已保存"
```

### 3. stop-continue.sh - 阻止过早停止

```bash
#!/bin/bash
# Stop Hook - 检查任务完成度，阻止过早停止

INPUT=$(cat)

# 读取待办事项
if [[ ! -f "$CLAUDE_PROJECT_DIR/context/todos.md" ]]; then
    exit 0
fi

TODOS=$(cat "$CLAUDE_PROJECT_DIR/context/todos.md")

# 检查是否有未完成的待办
UNFINISHED=$(echo "$TODOS" | grep -c "^\- \[ \]" || true)

if [[ "$UNFINISHED" -gt 0 ]]; then
    # 还有未完成的待办事项
    jq -n \
        --argjson count "$UNFINISHED" \
        '{
            decision: "continue",
            reason: "还有 \($count) 个待办事项未完成，请继续完成任务"
        }'
fi

exit 0
```

### 4. user-prompt-context.sh - 用户输入预处理

```bash
#!/bin/bash
# UserPromptSubmit Hook - 预处理用户输入

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt')

# 检测特定关键词并注入上下文
ADDITIONAL_CONTEXT=""

# 如果提到 "bug" 或 "错误"，注入最近的错误日志
if [[ "$PROMPT" =~ [Bb]ug|[错误|修复] ]]; then
    if [[ -d "logs" ]]; then
        LATEST_LOG=$(ls -t logs/*.log 2>/dev/null | head -1)
        if [[ -n "$LATEST_LOG" ]]; then
            ERROR_CONTEXT=$(tail -50 "$LATEST_LOG" | grep -A 5 -i "error\|exception" | head -20)
            if [[ -n "$ERROR_CONTEXT" ]]; then
                ADDITIONAL_CONTEXT="最近的错误日志:\n$ERROR_CONTEXT"
            fi
        fi
    fi
fi

# 如果提到 "测试"，注入测试命令
if [[ "$PROMPT" =~ [测试|test] ]]; then
    if [[ -f "package.json" ]]; then
        TEST_CMD=$(jq -r '.scripts.test // "npm test"' package.json)
        ADDITIONAL_CONTEXT="$ADDITIONAL_CONTEXT\n测试命令: $TEST_CMD"
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
```

---

## 上下文文件

### context/project.md

```markdown
# 项目说明

## 技术栈
- Node.js 18+
- Express.js
- PostgreSQL

## 核心模块
- `src/api/` - API 路由
- `src/models/` - 数据模型
- `src/services/` - 业务逻辑

## 编码规范
- 使用 async/await
- 错误处理用 try-catch
- 所有 API 需要 JWT 认证
```

### context/todos.md

```markdown
# 待办事项

- [ ] 实现 /api/users 端点
- [ ] 添加单元测试
- [x] 配置数据库连接
- [ ] 编写 API 文档
```

---

## 工作流程

```
┌─────────────────┐
│  会话开始        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ SessionStart    │ → 加载项目上下文、待办、Git 状态
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 用户输入 prompt │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│UserPromptSubmit │ → 检测关键词，注入相关上下文
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ Claude  │
    │ 处理中   │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│      Stop       │ → 检查待办完成度，可能阻止停止
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   SessionEnd    │ → 保存会话状态
└─────────────────┘
```

---

## 学习要点

1. **SessionStart 是注入上下文的最佳时机**
   - 加载项目说明、待办事项
   - 显示 Git 状态和最近变更

2. **Stop 可以阻止过早结束**
   - 检查任务完成度
   - 让 Claude 继续工作

3. **UserPromptSubmit 可以智能增强输入**
   - 检测关键词
   - 自动注入相关上下文

4. **SessionEnd 用于保存状态**
   - 记录会话信息
   - 为下次会话提供延续性

---

## 扩展练习

1. **智能上下文选择**：根据用户问题自动选择加载哪些上下文
2. **任务追踪**：更精细的任务完成度检测
3. **多项目支持**：为不同项目加载不同的上下文模板
