# Redis Integration

## Purpose

Redis is used as a caching layer for frequently accessed course information in the Student Training Management System.

PostgreSQL remains the primary source of truth for permanent application data. Redis stores temporary copies of frequently requested data to reduce repeated database queries and improve response time.

## Cached Data

Course information is cached using keys such as:

- course:PY101
- course:DB101
- course:WEB101

Example cached value: Python Programming|PY101

## Cache Expiration

Cached entries use a TTL (Time To Live). For example:

redis-cli SET course:PY101 "Python Programming|PY101" EX 300

The EX 300 option causes the cache entry to expire after five minutes.

## Cache Invalidation

When course information changes, the corresponding Redis key can be deleted:

redis-cli DEL course:PY101

This prevents stale course information from remaining in the cache.

## Why Redis?

Redis is appropriate because course information may be requested frequently but does not need to be permanently stored in the cache.

Using Redis provides:

- Fast in-memory reads
- Reduced PostgreSQL query load
- Automatic cache expiration
- Simple cache invalidation
- A clear separation between persistent storage and temporary cached data

## Data Ownership

| Component | Responsibility |
|---|---|
| PostgreSQL | Permanent source of truth |
| Redis | Temporary cache |
| Application | Reads from cache and falls back to PostgreSQL when needed |

## Verification

Redis was verified using redis-cli ping, which returned PONG.

A PostgreSQL course was also cached and successfully retrieved from Redis.
