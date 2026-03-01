#!/usr/bin/env python3
"""测试修复 Agent 入口"""

import asyncio
import sys
from pathlib import Path

# 添加 src 到路径
sys.path.insert(0, str(Path(__file__).parent))

from agent import TestAnalyzer, CodeFixer


async def main():
    # 从 stdin 或文件读取测试输出
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            test_output = f.read()
    else:
        test_output = sys.stdin.read()

    if not test_output:
        print("Usage: python main.py [test_output_file]")
        print("   or: npm test 2>&1 | python main.py")
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
