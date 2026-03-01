# SQL 查询示例

## 用户相关

```sql
-- 查询用户总数
SELECT COUNT(*) FROM users;

-- 最近 7 天注册的用户
SELECT COUNT(*)
FROM users
WHERE created_at >= datetime('now', '-7 days');

-- 活跃用户（最近 30 天有登录）
SELECT COUNT(*)
FROM users
WHERE last_login >= datetime('now', '-30 days');
```

## 订单相关

```sql
-- 上个月销售额
SELECT SUM(total_amount)
FROM orders
WHERE created_at >= datetime('now', 'start of month', '-1 month')
  AND created_at < datetime('now', 'start of month');

-- 销售额最高的 5 个产品
SELECT p.name, SUM(oi.quantity * oi.price) as revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.id
ORDER BY revenue DESC
LIMIT 5;

-- 每日订单趋势（最近 30 天）
SELECT DATE(created_at) as date, COUNT(*) as orders, SUM(total_amount) as revenue
FROM orders
WHERE created_at >= datetime('now', '-30 days')
GROUP BY DATE(created_at)
ORDER BY date;
```

## 数据质量检查

```sql
-- 检查重复邮箱
SELECT email, COUNT(*)
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- 检查孤儿订单（无对应用户）
SELECT o.id
FROM orders o
LEFT JOIN users u ON o.user_id = u.id
WHERE u.id IS NULL;

-- 检查数据一致性
SELECT
  (SELECT COUNT(*) FROM orders) as total_orders,
  (SELECT COUNT(*) FROM order_items) as total_items,
  (SELECT COUNT(DISTINCT order_id) FROM order_items) as orders_with_items;
```
