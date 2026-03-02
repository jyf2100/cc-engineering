# Security Review Prompt Template

Scan the code changes for security vulnerabilities.

## Security Checks

### 1. SQL Injection
- Check for unsanitized user input in SQL queries
- Look for string concatenation in database calls
- Verify parameterized queries are used

### 2. XSS Vulnerabilities
- Check for unsanitized output in HTML
- Look for innerHTML usage
- Verify proper encoding

### 3. Hardcoded Secrets
- Check for API keys in code
- Look for passwords in configuration
- Verify secrets are in environment variables

### 4. Insecure Dependencies
- Check for known vulnerable packages
- Look for outdated dependencies
- Verify security patches are applied

### 5. Authentication Issues
- Check for weak password policies
- Look for missing authentication
- Verify proper session management

## Output Format

Provide your findings in this format:

```json
{
  "status": "pass|fail",
  "issues": [
    {
      "severity": "high|medium|low",
      "type": "Issue type",
      "file": "path/to/file",
      "line": 10,
      "description": "Issue description",
      "recommendation": "How to fix"
    }
  ],
  "summary": "Brief summary of security status"
}
```

## Important Notes

- Report ALL potential issues, even if uncertain
- Prioritize issues by severity
- Provide actionable recommendations
- Be thorough but avoid false positives
