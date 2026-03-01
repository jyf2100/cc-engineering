# Naming Conventions

## General Principles

1. **Be descriptive**: Names should explain purpose
2. **Be consistent**: Follow the same patterns throughout
3. **Be concise**: But not at the cost of clarity
4. **Avoid abbreviations**: Unless widely known (URL, API, ID)

## JavaScript/TypeScript

### Variables and Parameters
```typescript
// Good - descriptive, camelCase
const userCount = users.length;
const isAuthenticated = checkAuth();

// Bad - unclear, abbreviations
const uc = users.length;
const isAuth = checkAuth();
```

### Constants
```typescript
// Good - UPPER_SNAKE_CASE for true constants
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';

// Good - camelCase for configuration objects
const defaultConfig = {
  timeout: 5000,
  retries: 3
};
```

### Functions and Methods
```typescript
// Good - verb + noun, descriptive
function fetchUserById(id: string): Promise<User> { }
function calculateTotalPrice(items: CartItem[]): number { }
function isValidEmail(email: string): boolean { }

// Bad - nouns only, unclear
function user(id: string) { }
function price(items: CartItem[]) { }
function email(email: string) { }
```

### Classes and Interfaces
```typescript
// Good - PascalCase, descriptive nouns
class UserService { }
interface ShoppingCart { }
type UserRole = 'admin' | 'user' | 'guest';

// Bad - camelCase, vague
class userService { }
interface Cart { }
type Role = string;
```

### Files and Directories
```
// Components - PascalCase
Button.tsx
UserProfile.tsx

// Utilities - camelCase
dateUtils.ts
apiClient.ts

// Services - PascalCase
UserService.ts
PaymentService.ts

// Directories - kebab-case
user-profile/
api-client/
```

## Database

### Tables
```sql
-- Good - snake_case, plural
CREATE TABLE user_profiles (
  id SERIAL PRIMARY KEY
);

-- Bad - mixed case, singular
CREATE TABLE UserProfile (
  ID SERIAL PRIMARY KEY
);
```

### Columns
```sql
-- Good - snake_case
first_name VARCHAR(100)
created_at TIMESTAMP
is_active BOOLEAN

-- Bad - camelCase
firstName VARCHAR(100)
createdAt TIMESTAMP
isActive BOOLEAN
```

### Indexes
```sql
-- Format: idx_table_columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);
```

## Git

### Branches
```
# Format: type/ticket-description
feature/PROJ-123-add-user-authentication
bugfix/PROJ-456-fix-login-crash
hotfix/PROJ-789-security-patch
```

### Commits
```
# Format: type(scope): description
feat(auth): add OAuth2 login
fix(api): handle null response
docs(readme): update installation steps
```

## Quick Reference

| Type | Convention | Example |
|------|------------|---------|
| Variables | camelCase | `userName` |
| Constants | UPPER_SNAKE | `MAX_COUNT` |
| Functions | camelCase | `getUser()` |
| Classes | PascalCase | `UserService` |
| Files | camelCase/PascalCase | `utils.ts` / `Button.tsx` |
| Directories | kebab-case | `user-profile/` |
| Database tables | snake_case | `user_profiles` |
| Database columns | snake_case | `created_at` |
| Git branches | type/description | `feature/add-auth` |
