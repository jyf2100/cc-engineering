# Database Directory

This directory is for the SQLite sample database.

## Setup

Run the setup script to create the sample database:

```bash
./scripts/setup-db.sh
```

This will create `sample.db` with sample tables and data.

## Tables

After setup, the database will contain:

- `users` - User information
- `products` - Product catalog
- `orders` - Order records
- `order_items` - Order line items
