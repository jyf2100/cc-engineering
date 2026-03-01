# 项目 1：代码质量 Plugin

> 打包代码审查、检查、格式化能力的完整插件

---

## 场景说明

这个 Plugin 提供完整的代码质量工具集：
- **Commands**: `/review`、`/lint`、`/format`、`/test`
- **Agents**: 代码质量守卫
- **Skills**: 代码质量分析能力
- **Hooks**: 自动格式化

---

## 项目结构

```
01-code-quality-plugin/
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── commands/
│   ├── review.md                # 代码审查命令
│   ├── lint.md                  # 代码检查命令
│   ├── format.md                # 代码格式化命令
│   └── test.md                  # 测试运行命令
├── agents/
│   └── quality-guard.md         # 质量守卫 Agent
├── skills/
│   └── code-quality/
│       └── SKILL.md             # 代码质量 Skill
├── hooks/
│   └── hooks.json               # 自动格式化 Hooks
└── README.md
```

---

## 插件清单

### .claude-plugin/plugin.json

```json
{
  "name": "code-quality",
  "version": "1.0.0",
  "description": "代码质量检查和改进工具集",
  "author": "claude-code-course",
  "keywords": ["code-review", "lint", "format", "quality"],
  "license": "MIT"
}
```

---

## Commands

### commands/review.md

```markdown
---
description: Review code for quality and security
argument-hint: [file or directory]
allowed-tools: Read,Grep,Glob,Bash(git diff*)
---

Review the following code for quality, security, and best practices: $ARGUMENTS

Focus on:
1. Security vulnerabilities
2. Code quality issues
3. Performance concerns
4. Best practices

Provide actionable suggestions for improvement.
```

### commands/lint.md

```markdown
---
description: Run linting on codebase
argument-hint: [file or directory]
allowed-tools: Bash(npm run lint*),Bash(eslint*),Bash(pylint*),Read
---

Run linting on: $ARGUMENTS

Fix any issues found and report the results.
```

### commands/format.md

```markdown
---
description: Format code with Prettier
argument-hint: [file or directory]
allowed-tools: Bash(prettier*),Read,Edit,Write
---

Format the following files using Prettier: $ARGUMENTS

Ensure consistent code style across the codebase.
```

### commands/test.md

```markdown
---
description: Run tests
argument-hint: [test file or pattern]
allowed-tools: Bash(npm test*),Bash(pytest*),Bash(jest*),Read
---

Run tests for: $ARGUMENTS

Report any failures and suggest fixes.
```

---

## Agents

### agents/quality-guard.md

```markdown
---
name: quality-guard
description: Monitor code quality and enforce standards
tools: Read,Grep,Glob
model: sonnet
---

You are a code quality guard. Your responsibilities:

1. **Code Review**
   - Check for security vulnerabilities
   - Identify code smells
   - Suggest improvements

2. **Standards Enforcement**
   - Verify naming conventions
   - Check code organization
   - Ensure documentation

3. **Reporting**
   - Provide clear issue descriptions
   - Suggest actionable fixes
   - Prioritize issues by severity

Always be constructive and helpful in your feedback.
```

---

## Skills

### skills/code-quality/SKILL.md

```markdown
---
description: Analyze code quality and provide improvement suggestions
---

# Code Quality Analysis

## Capabilities

This skill helps analyze and improve code quality:

### Security Analysis
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication issues
- Sensitive data exposure

### Code Quality
- Code complexity
- Code duplication
- Naming conventions
- Error handling

### Performance
- Algorithm efficiency
- Resource usage
- Database query optimization

### Best Practices
- Language-specific patterns
- Framework conventions
- Testing coverage

## Usage

When asked to analyze code quality:

1. Read the target code
2. Identify issues by category
3. Provide severity ratings
4. Suggest specific improvements
5. Prioritize fixes
```

---

## Hooks

### hooks/hooks.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$FILE_PATH\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

---

## 安装使用

```bash
# 从本地安装
/plugin install ./01-code-quality-plugin

# 使用命令
/review src/
/lint src/
/format src/
/test

# 使用 Agent
让 quality-guard 审查 src/auth.js

# Skill 自动触发
# 当你问"分析这段代码的质量"时自动触发
```

---

## 学习要点

1. **plugin.json** 定义插件元数据
2. **commands/** 定义斜杠命令
3. **agents/** 定义子代理
4. **skills/** 定义自动发现的能力
5. **hooks/** 定义事件钩子
