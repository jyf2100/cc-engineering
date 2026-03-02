/**
 * Calculate 工具 - 执行简单数学计算
 */

export const calculateTool = {
  name: 'calculate',
  description: '执行简单的数学计算',
  inputSchema: {
    type: 'object',
    properties: {
      expression: {
        type: 'string',
        description: '数学表达式，如 "1 + 2 * 3"',
      },
    },
    required: ['expression'],
  },
  handler: async (args) => {
    const { expression } = args;

    try {
      // 安全计算（仅支持基本运算）
      const safeEval = (expr) => {
        // 只允许数字和基本运算符
        if (!/^[\d\s+\-*/().]+$/.test(expr)) {
          throw new Error('无效表达式');
        }
        return Function(`"use strict"; return (${expr})`)();
      };

      const result = safeEval(expression);
      return {
        content: [
          {
            type: 'text',
            text: `计算结果: ${expression} = ${result}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `计算错误: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  },
};
