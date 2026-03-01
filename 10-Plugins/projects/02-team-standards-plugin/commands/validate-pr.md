---
description: Validate PR meets team standards
argument-hint: [PR number or branch]
allowed-tools: Read,Grep,Glob,Bash(git log*),Bash(git diff*)
---

Validate the PR for: $ARGUMENTS

## Commit Message Format

Check that commits follow:
```
type(scope): description

[optional body]
```

Valid types: feat, fix, docs, style, refactor, test, chore

## Branch Naming

Check branch name follows: `type/ticket-description`

Valid prefixes: feature, bugfix, hotfix, refactor, docs

## Code Quality

Check that:
- [ ] No debug code left in
- [ ] No commented-out code
- [ ] No hardcoded values
- [ ] Proper error handling

## Documentation

Check that:
- [ ] README updated if needed
- [ ] API docs updated if needed
- [ ] Changelog entry added

## Tests

Check that:
- [ ] New code has tests
- [ ] All tests pass

Report any issues that need to be addressed.
