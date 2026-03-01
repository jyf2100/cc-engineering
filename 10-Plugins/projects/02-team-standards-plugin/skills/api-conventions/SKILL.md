---
description: API design conventions and best practices
---

# API Design Conventions

## RESTful URL Naming

- Use kebab-case for URLs: `/api/v1/user-profiles`
- Use plural nouns for resources: `/users`, `/orders`
- Avoid nested resources deeper than 2 levels
- Version APIs in the path: `/api/v1/`

## Response Format

Standard success response:
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "total": 100
  }
}
```

Standard error response:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {"field": "email", "message": "Invalid email format"}
    ]
  }
}
```

## HTTP Methods

| Method | Purpose | Request Body |
|--------|---------|--------------|
| GET | Retrieve resources | No |
| POST | Create resources | Yes |
| PUT | Full update | Yes |
| PATCH | Partial update | Yes |
| DELETE | Remove resources | No |

## Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Missing/invalid token |
| 403 | Forbidden | No permission |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable | Validation failed |
| 500 | Server Error | Unexpected error |

## Authentication

All APIs require JWT Bearer token:
```
Authorization: Bearer <jwt_token>
```

## Rate Limiting

Include rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1640000000
```
