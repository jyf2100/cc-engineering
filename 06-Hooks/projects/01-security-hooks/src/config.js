/**
 * 应用配置
 *
 * ⚠️ 安全提示：此文件包含示例敏感信息
 * 实际项目中应使用环境变量
 */

module.exports = {
  // 服务配置
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development',

  // 数据库配置 - 应从环境变量读取
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    name: process.env.DB_NAME || 'myapp',
    user: process.env.DB_USER || 'postgres',
    // 注意：生产环境不要硬编码密码
    password: process.env.DB_PASSWORD || '',
  },

  // API 密钥 - 应从环境变量读取
  apiKeys: {
    // 示例：第三方服务 API Key
    stripe: process.env.STRIPE_API_KEY || '',
    sendgrid: process.env.SENDGRID_API_KEY || '',
  },

  // JWT 配置
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: '7d',
  },

  // 日志配置
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: 'json',
  },
};
