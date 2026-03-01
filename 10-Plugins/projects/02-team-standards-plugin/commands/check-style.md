---
description: Check code against team style guide
argument-hint: [file or directory]
allowed-tools: Read,Grep,Glob
---

Check the code style for: $ARGUMENTS

Verify against our team standards:

## Naming Conventions
- Variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Classes: PascalCase
- Files: kebab-case for utilities, PascalCase for components

## Code Organization
- One export per file (default export)
- Group imports: external → internal → relative
- Max file length: 300 lines

## Documentation
- All public functions need JSDoc comments
- Complex logic needs inline comments

## Error Handling
- Always use try-catch for async operations
- Throw custom error classes
- Log errors with context

Report any violations with specific suggestions.
