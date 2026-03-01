# 代码审查 Prompt 模板

## 通用审查

```
Review the code changes in this PR for:

### Code Quality
- Code organization and structure
- Naming conventions
- Code duplication
- Complexity

### Potential Bugs
- Logic errors
- Edge cases
- Null/undefined handling
- Error handling

### Best Practices
- Language-specific best practices
- Design patterns
- Testing considerations

### Actionable Feedback
Provide specific, actionable suggestions for improvement.

Format your response as:
- **Issue**: Description of the issue
- **Location**: File and line number
- **Suggestion**: How to fix it
```

## 安全审查

```
Scan the code for security vulnerabilities:

1. **Input Validation**
   - SQL injection
   - XSS vulnerabilities
   - Command injection
   - Path traversal

2. **Authentication & Authorization**
   - Weak authentication
   - Missing access control
   - Session management issues

3. **Sensitive Data**
   - Hardcoded credentials
   - Sensitive data exposure
   - Insecure data storage

4. **Dependencies**
   - Known vulnerable packages
   - Outdated dependencies

Report findings with severity levels (Critical/High/Medium/Low).
```

## 性能审查

```
Analyze the code for performance issues:

1. **Algorithm Efficiency**
   - Time complexity
   - Space complexity
   - Unnecessary loops

2. **Resource Usage**
   - Memory leaks
   - Unclosed connections
   - Large object allocations

3. **Database**
   - N+1 queries
   - Missing indexes
   - Inefficient queries

4. **Caching**
   - Cache opportunities
   - Cache invalidation issues
```
