---
description: Run tests
argument-hint: [test file or pattern]
allowed-tools: Bash(npm test*),Bash(pytest*),Bash(jest*),Read
---

Run tests for: $ARGUMENTS

If no argument provided, run all tests.

1. Detect the test framework
2. Run the appropriate test command
3. Report results
4. If tests fail, suggest fixes

Report any failures and suggest fixes.
