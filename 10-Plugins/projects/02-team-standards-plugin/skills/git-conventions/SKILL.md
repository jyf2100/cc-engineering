---
description: Git commit and branch conventions
---

# Git Conventions

## Branch Naming

Format: `type/ticket-number-short-description`

### Branch Types

| Type | Purpose | Example |
|------|---------|---------|
| `feature/` | New features | `feature/PROJ-123-add-auth` |
| `bugfix/` | Bug fixes | `bugfix/PROJ-456-fix-crash` |
| `hotfix/` | Production fixes | `hotfix/PROJ-789-security` |
| `refactor/` | Code refactoring | `refactor/PROJ-101-cleanup` |
| `docs/` | Documentation | `docs/PROJ-102-readme` |

## Commit Messages

Format:
```
type(scope): short description (max 50 chars)

[optional body - wrap at 72 chars]

[optional footer]
```

### Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code refactoring |
| `test` | Adding/updating tests |
| `chore` | Maintenance tasks |

### Examples

```
feat(auth): add OAuth2 login support

- Add Google OAuth provider
- Add session management
- Update login page UI

Closes #123
```

```
fix(api): handle null response in user service

The API was returning null for deleted users, causing
crashes. Added null check and default empty object.

Fixes #456
```

## PR Guidelines

### PR Title
Same format as commit messages:
```
feat(auth): add OAuth2 login support
```

### PR Description Template
```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests added
- [ ] Integration tests added
- [ ] Manual testing done

## Screenshots
[If applicable]

Closes #issue-number
```
