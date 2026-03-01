#!/usr/bin/env node

/**
 * 简单的 MCP 服务器示例
 * 提供问候和计算工具
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

// 创建服务器实例
const server = new Server(
  {
    name: 'simple-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// 定义工具列表
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
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
      },
      {
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
      },
      {
        name: 'get_time',
        description: '获取当前时间',
        inputSchema: {
          type: 'object',
          properties: {
            timezone: {
              type: 'string',
              description: '时区，如 "Asia/Shanghai"',
            },
          },
        },
      },
    ],
  };
});

// 处理工具调用
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case 'hello':
      const greeting = args.name
        ? `你好，${args.name}！很高兴见到你！`
        : '你好！很高兴见到你！';
      return {
        content: [
          {
            type: 'text',
            text: greeting,
          },
        ],
      };

    case 'calculate':
      try {
        // 安全计算（仅支持基本运算）
        const safeEval = (expr) => {
          // 只允许数字和基本运算符
          if (!/^[\d\s+\-*/().]+$/.test(expr)) {
            throw new Error('无效表达式');
          }
          return Function(`"use strict"; return (${expr})`)();
        };
        const result = safeEval(args.expression);
        return {
          content: [
            {
              type: 'text',
              text: `计算结果: ${args.expression} = ${result}`,
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

    case 'get_time':
      const tz = args.timezone || 'UTC';
      const time = new Date().toLocaleString('zh-CN', { timeZone: tz });
      return {
        content: [
          {
            type: 'text',
            text: `当前时间 (${tz}): ${time}`,
          },
        ],
      };

    default:
      throw new Error(`未知工具: ${name}`);
  }
});

// 启动服务器
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Simple MCP Server 已启动');
}

main().catch(console.error);
