# 项目 1：测试修复 Agent

> 使用 Python SDK 构建自动化测试修复 Agent

---

## 场景说明

当测试失败时，自动：
1. 分析测试失败原因
2. 定位问题代码
3. 尝试修复
4. 验证修复结果

---

## 项目结构

```
01-test-fixer-agent/
├── README.md
├── src/
│   ├── agent/
│   │   ├── __init__.py
│   │   ├── test_analyzer.py      # 测试分析器
│   │   └── code_fixer.py         # 代码修复器
│   └── main.py                   # 入口脚本
├── pyproject.toml                # Python 项目配置
└── examples/
    └── sample-failing-tests/     # 示例失败测试
```

---

## 核心代码

### src/agent/__init__.py

```python
"""测试修复 Agent"""

from .test_analyzer import TestAnalyzer
from .code_fixer import CodeFixer

__all__ = ["TestAnalyzer", "CodeFixer"]
```

### src/agent/test_analyzer.py

```python
"""测试分析器 - 分析测试失败原因"""

from dataclasses import dataclass
from typing import Optional
import re


@dataclass
class TestFailure:
    """测试失败信息"""
    test_name: str
    file_path: str
    line_number: Optional[int]
    error_message: str
    stack_trace: Optional[str] = None


class TestAnalyzer:
    """分析测试输出，提取失败信息"""

    # 常见测试框架的失败模式
    PATTERNS = {
        'jest': r'FAIL\s+(.+?)\s+●\s+(.+?)\s+',\n        'pytest': r'FAILED\s+(.+?)::(.+?)\s+-\s+(.+)',
        'mocha': r'1\) (.+?)\n\s+Error: (.+)',
    }

    def __init__(self, framework: str = 'auto'):
        self.framework = framework

    def parse_failures(self, test_output: str) -> list[TestFailure]:
        """解析测试输出，返回失败列表"""
        failures = []

        # 自动检测框架
        if self.framework == 'auto':
            self.framework = self._detect_framework(test_output)

        pattern = self.PATTERNS.get(self.framework)
        if not pattern:
            # 通用解析
            failures.extend(self._generic_parse(test_output))
        else:
            failures.extend(self._framework_parse(test_output, pattern))

        return failures

    def _detect_framework(self, output: str) -> str:
        """检测测试框架"""
        if 'jest' in output.lower() or 'FAIL' in output:
            return 'jest'
        elif 'pytest' in output.lower() or 'FAILED' in output:
            return 'pytest'
        elif 'mocha' in output.lower():
            return 'mocha'
        return 'generic'

    def _framework_parse(self, output: str, pattern: str) -> list[TestFailure]:
        """使用框架特定模式解析"""
        failures = []
        for match in re.finditer(pattern, output, re.MULTILINE):
            # 根据框架提取不同字段
            if self.framework == 'pytest':
                failures.append(TestFailure(
                    test_name=match.group(2),
                    file_path=match.group(1),
                    line_number=None,
                    error_message=match.group(3)
                ))
            else:
                failures.append(TestFailure(
                    test_name=match.group(1),
                    file_path='unknown',
                    line_number=None,
                    error_message=match.group(2)
                ))
        return failures

    def _generic_parse(self, output: str) -> list[TestFailure]:
        """通用解析"""
        failures = []
        # 查找 Error: 或 AssertionError: 模式
        error_pattern = r'(.+?):(\d+):.*?(Error|AssertionError):\s*(.+)'
        for match in re.finditer(error_pattern, output, re.MULTILINE | re.DOTALL):
            failures.append(TestFailure(
                test_name='unknown',
                file_path=match.group(1),
                line_number=int(match.group(2)),
                error_message=f"{match.group(3)}: {match.group(4)}"
            ))
        return failures
```

### src/agent/code_fixer.py

```python
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
```

### src/main.py

```python
#!/usr/bin/env python3
"""测试修复 Agent 入口"""

import asyncio
import sys
from agent import TestAnalyzer, CodeFixer


async def main():
    # 从 stdin 或文件读取测试输出
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            test_output = f.read()
    else:
        test_output = sys.stdin.read()

    if not test_output:
        print("Usage: python -m agent [test_output_file]")
        print("   or: npm test 2>&1 | python -m agent")
        sys.exit(1)

    # 分析测试失败
    analyzer = TestAnalyzer()
    failures = analyzer.parse_failures(test_output)

    if not failures:
        print("No test failures found in the output.")
        sys.exit(0)

    print(f"Found {len(failures)} failing tests:")
    for f in failures:
        print(f"  - {f.test_name}: {f.error_message[:50]}...")

    # 修复失败
    fixer = CodeFixer(max_turns=15)
    results = await fixer.fix_all_failures(failures, test_output)

    # 报告结果
    print("\n=== Fix Results ===")
    for r in results:
        status = "✅" if not r["result"].get("is_error") else "❌"
        print(f"{status} {r['test']}")

    # 返回码
    all_fixed = all(not r["result"].get("is_error") for r in results)
    sys.exit(0 if all_fixed else 1)


if __name__ == "__main__":
    asyncio.run(main())
```

---

## pyproject.toml

```toml
[project]
name = "test-fixer-agent"
version = "0.1.0"
description = "Automated test fixing agent using Claude Code SDK"
requires-python = ">=3.10"
dependencies = [
    "claude-code-sdk>=0.1.0",
]

[project.scripts]
test-fixer = "agent.main:main"
```

---

## 使用方法

```bash
# 安装
pip install -e .

# 方式 1：从文件读取测试输出
test-fixer test-output.txt

# 方式 2：管道输入
npm test 2>&1 | test-fixer

# 方式 3：Python 调用
python -m agent test-output.txt
```

---

## 学习要点

1. **SDK 集成**
   - 使用 `claude-code-sdk` 包
   - 异步调用 `query()` 函数
   - 配置 `ClaudeCodeOptions`

2. **工具权限**
   - 只允许必要的工具
   - 限制 Bash 命令范围

3. **系统提示**
   - 明确 Agent 角色
   - 提供修复策略

---

## 扩展

1. **多语言支持**：添加 Java、Go 等测试框架
2. **增量修复**：只修复最近失败的测试
3. **回滚机制**：修复失败时自动回滚
