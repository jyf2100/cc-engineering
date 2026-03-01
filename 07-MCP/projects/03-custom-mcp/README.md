# 项目 3：自定义 MCP Server

> 从零开发一个简单的 MCP 服务器

---

## 场景说明

当现有 MCP 服务器不满足需求时，可以开发自定义 MCP Server。本项目演示如何创建一个简单的 MCP 服务器。

---

## 项目结构

```
03-custom-mcp/
├── README.md
├── .mcp.json              # MCP 配置
├── server/
│   ├── package.json       # Node.js 项目配置
│   ├── index.js           # MCP 服务器入口
│   └── tools/
│       ├── hello.js       # 示例工具
│       └── calculate.js   # 计算工具
└── examples/
    └── usage.md           # 使用示例
```

---

## MCP 服务器实现

### server/index.js

```javascript
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
    ],
  };
});

// 处理工具调用
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case 'hello':
      return {
        content: [
          {
            type: 'text',
            text: `你好，${args.name}！很高兴见到你！`,
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
```

### server/package.json

```json
{
  "name": "simple-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "bin": {
    "simple-mcp-server": "./index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  }
}
```

---

## MCP 配置

### .mcp.json

```json
{
  "mcpServers": {
    "simple": {
      "command": "node",
      "args": ["${CLAUDE_PROJECT_DIR}/server/index.js"]
    }
  }
}
```

---

## 使用示例

```
用户：向 Alice 打个招呼
Claude：[调用 simple.hello]
       你好，Alice！很高兴见到你！

用户：计算 123 * 456
Claude：[调用 simple.calculate]
       计算结果: 123 * 456 = 56088
```

---

## 学习要点

1. **MCP 服务器结构**
   - 使用 `@modelcontextprotocol/sdk`
   - 定义工具列表（ListToolsRequestSchema）
   - 处理工具调用（CallToolRequestSchema）

2. **stdio 传输**
   - 通过 stdin/stdout 通信
   - 日志输出到 stderr

3. **安全性**
   - 验证输入参数
   - 避免代码注入
   - 限制操作范围

---

## 扩展方向

1. **添加更多工具**：文件操作、HTTP 请求等
2. **添加资源支持**：读取文件、数据库等
3. **添加提示模板**：预定义的 prompt 模板
