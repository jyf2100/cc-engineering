"""代码修复器 - 使用 Claude SDK 修复代码"""

import asyncio
from typing import Optional
from claude_code_sdk import query, ClaudeCodeOptions
from .test_analyzer import TestFailure


class CodeFixer:
    """使用 Claude Code SDK 修复代码"""

    def __init__(self, max_turns: int = 15):
        self.max_turns = max_turns

    async def fix_failure(
        self,
        failure: TestFailure,
        test_output: str
    ) -> dict:
        """修复单个测试失败"""
        prompt = f"""
        A test is failing. Please analyze and fix it.

        Test: {failure.test_name}
        File: {failure.file_path}
        Error: {failure.error_message}

        Full test output:
        ```
        {test_output}
        ```

        Please:
        1. Read the failing test to understand what it expects
        2. Read the implementation code being tested
        3. Identify the bug
        4. Fix the bug (not the test)
        5. Run the test to verify the fix
        """

        result = await query(
            prompt,
            options=ClaudeCodeOptions(
                allowed_tools=[
                    "Read",
                    "Edit",
                    "Bash(npm test*)",
                    "Bash(pytest*)",
                    "Bash(python -m pytest*)",
                ],
                max_turns=self.max_turns,
                system_prompt="""You are a test fixer. Your job is to fix failing tests.
                Always fix the implementation code, not the test.
                Run tests after making changes to verify the fix.
                Be careful not to break other tests.""",
            )
        )

        return result

    async def fix_all_failures(
        self,
        failures: list[TestFailure],
        test_output: str
    ) -> list[dict]:
        """修复所有失败（逐个处理）"""
        results = []
        for failure in failures:
            print(f"Fixing: {failure.test_name}")
            result = await self.fix_failure(failure, test_output)
            results.append({
                "test": failure.test_name,
                "result": result,
            })
        return results
