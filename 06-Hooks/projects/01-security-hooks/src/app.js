/**
 * 示例 Express 应用
 * 用于演示 security hooks 如何保护代码修改
 */

const express = require('express');
const config = require('./config');

const app = express();
const PORT = config.port || 3000;

// 中间件
app.use(express.json());

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 用户 API
app.get('/api/users', async (req, res) => {
  try {
    // TODO: 实现用户列表查询
    res.json({ users: [] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    if (!name || !email) {
      return res.status(400).json({ error: 'name and email are required' });
    }
    // TODO: 实现用户创建
    res.status(201).json({ id: 1, name, email });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 启动服务器
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
