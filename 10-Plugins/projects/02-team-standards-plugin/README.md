# 项目 2：团队规范 Plugin

> 封装团队编码规范和最佳实践的插件

---

## 场景说明

这个 Plugin 封装了团队的开发规范：
- **Commands**: `/check-style`、`/generate-docs`、`/validate-pr`
- **Skills**: API 设计规范、Git 规范
- **Reference**: 规范文档

---

## 项目结构

```
02-team-standards-plugin/
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── commands/
│   ├── check-style.md           # 检查代码风格
│   ├── generate-docs.md         # 生成文档
│   └── validate-pr.md           # 验证 PR 规范
├── skills/
│   ├── api-conventions/
│   │   └── SKILL.md             # API 设计规范
│   └── git-conventions/
│       └── SKILL.md             # Git 规范
├── reference/
│   ├── api-design.md            # API 设计指南
│   └── naming-conventions.md    # 命名规范
└── README.md
```

---

## 插件清单

### .claude-plugin/plugin.json

```json
{
  "name": "team-standards",
  "version": "2.0.0",
  "description": "团队编码规范和最佳实践",
  "author": "my-team",
  "keywords": ["standards", "conventions", "best-practices"],
  "license": "MIT"
}
```

---

## Commands

### commands/check-style.md

```markdown
---
description: Check code against team style guide
argument-hint: [file or directory]
allowed-tools: Read,Grep,Glob
---

Check the code style for: $ARGUMENTS

Verify against our team standards:
1. Naming conventions
2. Code organization
3. Documentation requirements
4. Error handling patterns

Report any violations with specific suggestions.
```

### commands/generate-docs.md

```markdown
---
description: Generate documentation from code
argument-hint: [file or directory]
allowed-tools: Read,Glob,Grep,Write
---

Generate documentation for: $ARGUMENTS

Create documentation that includes:
1. Module overview
2. API reference
3. Usage examples
4. Type definitions

Follow our documentation standards.
```

### commands/validate-pr.md

```markdown
---
description: Validate PR meets team standards
argument-hint: [PR number or branch]
allowed-tools: Read,Grep,Glob,Bash(git log*),Bash(git diff*)
---

Validate the PR for: $ARGUMENTS

Check:
1. Commit message format
2. Branch naming convention
3. Code changes quality
4. Documentation updates
5. Test coverage

Report any issues that need to be addressed.
```

---

## Skills

### skills/api-conventions/SKILL.md

```markdown
---
description: API design conventions and best practices
---

# API Design Conventions

## RESTful URL Naming

- Use kebab-case for URLs: `/api/v1/user-profiles`
- Use plural nouns for resources: `/users`, `/orders`
- Avoid nested resources deeper than 2 levels

## Response Format

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

## Error Handling

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [...]
  }
}
```

## HTTP Methods

| Method | Purpose |
|--------|---------|
| GET | Retrieve resources |
| POST | Create resources |
| PUT | Full update |
| PATCH | Partial update |
| DELETE | Remove resources |

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Server Error |
```

### skills/git-conventions/SKILL.md

```markdown
---
description: Git commit and branch conventions
---

# Git Conventions

## Branch Naming

Format: `type/ticket-number-short-description`

Examples:
- `feature/PROJ-123-add-user-auth`
- `bugfix/PROJ-456-fix-login-crash`
- `hotfix/PROJ-789-security-patch`

Types:
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Production fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation

## Commit Messages

Format:
```
type(scope): short description

[optional body]

[optional footer]
```

Types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Maintenance

Examples:
```
feat(auth): add OAuth2 login support

- Add Google OAuth provider
- Add session management
- Update login page

Closes #123
```

## PR Guidelines

1. Link related issues
2. Describe changes clearly
3. Include test results
4. Request appropriate reviewers
```

---

## Reference Documents

### reference/api-design.md

```markdown
# API Design Guidelines

## Overview

This document outlines our team's API design standards.

## URL Structure

### Base URL
```
https://api.example.com/v1
```

### Resource URLs
- Use plural nouns: `/users`, `/products`
- Use kebab-case: `/user-profiles`
- Avoid verbs in URLs

### Query Parameters
- Use for filtering: `?status=active`
- Use for pagination: `?page=1&limit=20`
- Use for sorting: `?sort=-created_at`

## Request/Response

### Request Headers
```
Content-Type: application/json
Authorization: Bearer <token>
X-Request-ID: <uuid>
```

### Response Headers
```
Content-Type: application/json
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
```

## Authentication

All APIs require JWT authentication unless explicitly documented as public.

## Rate Limiting

- Standard: 100 requests/minute
- Elevated: 1000 requests/minute

## Versioning

Use URL path versioning: `/v1/`, `/v2/`
```

### reference/naming-conventions.md

```markdown
# Naming Conventions

## General Rules

- Use descriptive names
- Avoid abbreviations unless widely known
- Be consistent within the codebase

## JavaScript/TypeScript

### Variables
```typescript
// Good
const userProfile = getUserProfile();
const isActive = true;

// Bad
const up = getUserProfile();
const flag = true;
```

### Functions
```typescript
// Good
function calculateTotalPrice(items: Item[]): number { }
async function fetchUserById(id: string): Promise<User> { }

// Bad
function calc(items) { }
function get(id) { }
```

### Classes
```typescript
// Good
class UserService { }
class OrderRepository { }

// Bad
class userService { }
class Order_Repo { }
```

### Files
```
// Components
UserProfile.tsx
OrderList.tsx

// Utilities
dateUtils.ts
apiClient.ts

// Services
UserService.ts
OrderService.ts
```

## Database

### Tables
```sql
-- Good
CREATE TABLE user_profiles (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Bad
CREATE TABLE userProfile (
  ID serial primary key
);
```

### Columns
```sql
-- Good
first_name VARCHAR(100)
created_at TIMESTAMP

-- Bad
firstName VARCHAR(100)
createdAt TIMESTAMP
```
```

---

## 团队配置

在项目的 `.claude/settings.json` 中启用：

```json
{
  "plugins": {
    "enabled": [
      "team-standards@my-team"
    ]
  }
}
```

---

## 学习要点

1. **Skills 封装规范**
   - description 触发自动发现
   - 内容结构清晰

2. **Reference 文档**
   - 提供详细参考
   - 作为 Skill 的知识库

3. **团队共享**
   - 提交到 Git 仓库
   - 团队成员自动同步
