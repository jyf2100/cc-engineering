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
        'jest': r'FAIL\s+(.+?)\s+●\s+(.+?)\s+',
        'pytest': r'FAILED\s+(.+?)::(.+?)\s+-\s+(.+)',
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
