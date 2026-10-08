# Redis Integration

## Purpose

Redis is used as a caching layer for frequently accessed course information in the Student Training Management System.

PostgreSQL remains the primary source of truth for permanent application data. Redis stores temporary copies of frequently requested data to reduce repeated database queries and improve response time.

The cache is tenant-aware so that data belonging to one training institution cannot be returned to another institution.

## Cached Data

Course information is cached using tenant-specific keys:

- `course:1:PY101`
- `course:1:DB101`
- `course:2:WEB101`

The key format is:

    course:{tenant_id}:{course_code}

Including the tenant ID prevents a course code used by one tenant from colliding with the same course code used by another tenant.

For example:

    Tenant 1 → course:1:PY101
    Tenant 2 → course:2:PY101

PostgreSQL also filters by both tenant ID and course code:

    WHERE tenant_id = %s
      AND code = %s

## Cache Expiration

Cached entries use a TTL (Time To Live) of 300 seconds.

The application stores entries using:

    redis_client.set(cache_key, json.dumps(course), ex=REDIS_TTL)

This causes cached course information to expire automatically after five minutes.

## Cache Invalidation

When course information changes, the corresponding tenant-specific Redis key should be deleted.

For example:

    redis-cli DEL course:1:PY101

This prevents stale course information from remaining in the cache.

## Shared Redis Client

The application creates one shared Redis client outside the `get_course()` function.

The redis-py client manages connections through its internal connection pool. This avoids creating a new Redis client and socket connection for every course request.

This approach is more suitable for a production application receiving repeated traffic.

## Cache-Aside Pattern

The application follows a cache-aside pattern:

1. Check Redis using the tenant-aware cache key.
2. If the data exists, return the cached value.
3. If the data does not exist, query PostgreSQL.
4. Store the result in Redis with a five-minute TTL.
5. Return the course to the application.

## Why Redis?

Redis is appropriate because course information may be requested frequently but does not need to be permanently stored in the cache.

Using Redis provides:

- Fast in-memory reads
- Reduced PostgreSQL query load
- Automatic cache expiration
- Simple cache invalidation
- Tenant-aware cache isolation
- A clear separation between persistent storage and temporary cached data

## Data Ownership

| Component | Responsibility |
|---|---|
| PostgreSQL | Permanent source of truth |
| Redis | Temporary tenant-aware cache |
| Application | Reads from cache and falls back to PostgreSQL when needed |

## Verification

Redis was verified using:

    redis-cli ping

which returned:

    PONG

The cache behavior was also verified:

- Tenant 1, `PY101`: first request produced `CACHE MISS` and returned the course from PostgreSQL.
- Tenant 1, `PY101`: second request produced `CACHE HIT`.
- Tenant 2, `PY101`: returned `None` because that tenant does not have that course.
- Redis confirmed the tenant-specific key:

    course:1:PY101
