# 项目说明

## 技术栈
- Node.js 18+
- Express.js
- PostgreSQL
- Redis (缓存)

## 核心模块
- `src/api/` - API 路由定义
- `src/models/` - 数据模型 (Sequelize)
- `src/services/` - 业务逻辑层
- `src/middleware/` - 中间件 (认证、日志等)
- `src/utils/` - 工具函数

## API 规范
- RESTful 风格
- 所有响应格式: `{ success: boolean, data: any, error?: string }`
- 认证: JWT Bearer Token
- 版本前缀: `/api/v1/`

## 编码规范
- 使用 async/await，避免回调地狱
- 所有错误用 try-catch 捕获
- 服务层处理业务逻辑，控制器只做请求转发
- 所有 API 需要 JWT 认证（除 /auth/* 外）

## 常用命令
- `npm run dev` - 开发服务器
- `npm test` - 运行测试
- `npm run lint` - 代码检查
- `npm run db:migrate` - 数据库迁移
