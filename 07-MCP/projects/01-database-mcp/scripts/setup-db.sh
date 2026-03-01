#!/bin/bash
# 初始化示例数据库

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DB_DIR="$PROJECT_DIR/database"
DB_PATH="$DB_DIR/sample.db"

# 创建数据库目录
mkdir -p "$DB_DIR"

# 如果数据库已存在，先删除
if [[ -f "$DB_PATH" ]]; then
    rm "$DB_PATH"
fi

# 创建表和示例数据
sqlite3 "$DB_PATH" <<'EOF'
-- 用户表
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
);

-- 产品表
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category TEXT
);

-- 订单表
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 订单项表
CREATE TABLE order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 插入示例数据
INSERT INTO users (email, name, created_at, last_login) VALUES
    ('alice@example.com', 'Alice Wang', datetime('now', '-30 days'), datetime('now', '-1 day')),
    ('bob@example.com', 'Bob Zhang', datetime('now', '-25 days'), datetime('now', '-3 days')),
    ('charlie@example.com', 'Charlie Li', datetime('now', '-20 days'), datetime('now', '-7 days')),
    ('diana@example.com', 'Diana Chen', datetime('now', '-15 days'), datetime('now', '-2 days')),
    ('eve@example.com', 'Eve Liu', datetime('now', '-10 days'), datetime('now', '-5 days'));

INSERT INTO products (name, price, category) VALUES
    ('Pro 订阅', 99.00, 'subscription'),
    ('Enterprise 许可', 499.00, 'license'),
    ('API 调用包 10000', 29.00, 'api'),
    ('存储扩展 100GB', 19.00, 'storage'),
    ('技术支持月度', 199.00, 'support');

INSERT INTO orders (user_id, total_amount, status, created_at) VALUES
    (1, 99.00, 'completed', datetime('now', '-28 days')),
    (2, 528.00, 'completed', datetime('now', '-20 days')),
    (3, 29.00, 'completed', datetime('now', '-15 days')),
    (1, 118.00, 'completed', datetime('now', '-10 days')),
    (4, 499.00, 'completed', datetime('now', '-5 days')),
    (5, 29.00, 'pending', datetime('now', '-2 days'));

INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
    (1, 1, 1, 99.00),
    (2, 2, 1, 499.00),
    (2, 3, 1, 29.00),
    (3, 3, 1, 29.00),
    (4, 1, 1, 99.00),
    (4, 4, 1, 19.00),
    (5, 2, 1, 499.00),
    (6, 3, 1, 29.00);

-- 创建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

EOF

echo "✅ 数据库初始化完成: $DB_PATH"
echo ""
echo "表结构:"
sqlite3 "$DB_PATH" ".tables"
echo ""
echo "数据统计:"
sqlite3 "$DB_PATH" "SELECT 'users: ' || COUNT(*) FROM users UNION ALL SELECT 'products: ' || COUNT(*) FROM products UNION ALL SELECT 'orders: ' || COUNT(*) FROM orders;"
