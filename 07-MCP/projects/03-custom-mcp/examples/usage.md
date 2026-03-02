# 自定义 MCP Server 使用示例

本文档演示如何使用自定义的 Simple MCP Server。

## 启动服务器

```bash
# 进入服务器目录
cd server

# 安装依赖
npm install

# 启动服务器（通过 Claude Code 自动启动）
# 在项目根目录运行 Claude Code
claude
```

## 使用示例

### Hello 工具

```
用户：向 Alice 打个招呼
Claude：[调用 simple.hello]
       你好，Alice！很高兴见到你！

用户：问候一下 Bob
Claude：[调用 simple.hello]
       你好，Bob！很高兴见到你！
```

### Calculate 工具

```
用户：计算 123 * 456
Claude：[调用 simple.calculate]
       计算结果: 123 * 456 = 56088

用户：帮我算一下 (10 + 5) * 3
Claude：[调用 simple.calculate]
       计算结果: (10 + 5) * 3 = 45

用户：计算 2 的 10 次方
Claude：[调用 simple.calculate]
       计算结果: 2 ** 10 = 1024
```

## 扩展工具

要添加新工具，在 `server/tools/` 目录下创建新文件：

```javascript
// server/tools/myTool.js
export const myTool = {
  name: 'my_tool',
  description: '工具描述',
  inputSchema: {
    type: 'object',
    properties: {
      // 输入参数定义
    },
    required: ['param1'],
  },
  handler: async (args) => {
    // 处理逻辑
    return {
      content: [
        {
          type: 'text',
          text: '结果',
        },
      ],
    };
  },
};
```

然后在 `server/index.js` 中注册：

```javascript
import { myTool } from './tools/myTool.js';

// 添加到工具列表
tools.push(myTool);
```
