/**
 * Hello 工具 - 向用户打招呼
 */

export const helloTool = {
  name: 'hello',
  description: '向指定名字的人打招呼',
  inputSchema: {
    type: 'object',
    properties: {
      name: {
        type: 'string',
        description: '要打招呼的名字',
      },
    },
    required: ['name'],
  },
  handler: async (args) => {
    const { name } = args;
    return {
      content: [
        {
          type: 'text',
          text: `你好，${name}！很高兴见到你！`,
        },
      ],
    };
  },
};
