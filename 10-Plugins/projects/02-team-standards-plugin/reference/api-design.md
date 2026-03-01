# API Design Guidelines

## Overview

This document outlines our team's API design standards for RESTful services.

## URL Structure

### Base URL
```
Production: https://api.example.com/v1
Staging: https://api-staging.example.com/v1
```

### Resource URLs
- Use plural nouns: `/users`, `/products`, `/orders`
- Use kebab-case for multi-word: `/user-profiles`, `/order-items`
- Avoid verbs in URLs (use HTTP methods instead)

### Query Parameters

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `page` | Pagination | `?page=1` |
| `limit` | Page size | `?limit=20` |
| `sort` | Sorting | `?sort=-created_at` |
| `fields` | Field selection | `?fields=id,name` |
| `filter` | Filtering | `?status=active` |

## Request/Response

### Request Headers
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer <jwt_token>
X-Request-ID: <uuid>
X-Client-Version: 1.0.0
```

### Response Headers
```
Content-Type: application/json
X-Request-ID: <uuid>
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1640000000
```

## Pagination

### Request
```
GET /users?page=2&limit=20
```

### Response
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "page": 2,
    "limit": 20,
    "total": 150,
    "total_pages": 8
  },
  "links": {
    "first": "/users?page=1",
    "prev": "/users?page=1",
    "next": "/users?page=3",
    "last": "/users?page=8"
  }
}
```

## Authentication

All APIs require JWT authentication unless explicitly documented as public.

### Getting a Token
```
POST /auth/login
{
  "email": "user@example.com",
  "password": "secret"
}
```

### Using the Token
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

## Rate Limiting

| Tier | Limit |
|------|-------|
| Standard | 100 requests/minute |
| Elevated | 1000 requests/minute |
| Enterprise | Unlimited |

## Error Handling

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": [...]
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid input |
| UNAUTHORIZED | 401 | Missing/invalid token |
| FORBIDDEN | 403 | No permission |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Duplicate resource |
| RATE_LIMITED | 429 | Too many requests |
