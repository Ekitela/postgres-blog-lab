"""Tenant-aware Redis cache-aside example for course data."""

import json
import os

import psycopg
import redis


REDIS_TTL = 300

# Shared Redis client.
# redis-py manages connections through its internal connection pool.
redis_client = redis.Redis(
    host="127.0.0.1",
    port=6379,
    decode_responses=True,
)


def get_course(tenant_id, code):
    cache_key = f"course:{tenant_id}:{code}"

    # 1. Check Redis first
    cached = redis_client.get(cache_key)

    if cached:
        print("CACHE HIT")
        return json.loads(cached)

    # 2. Cache miss: query PostgreSQL
    print("CACHE MISS - querying PostgreSQL")

    password = os.environ.get("FLYWAY_PASSWORD")

    if not password:
        raise RuntimeError("FLYWAY_PASSWORD is not set")

    with psycopg.connect(
        host="127.0.0.1",
        port=5432,
        dbname="capstone",
        user="postgres",
        password=password,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, name, code
                FROM courses
                WHERE tenant_id = %s
                  AND code = %s
                """,
                (tenant_id, code),
            )

            row = cur.fetchone()

    if row is None:
        return None

    course = {
        "id": row[0],
        "tenant_id": tenant_id,
        "name": row[1],
        "code": row[2],
    }

    # 3. Store the tenant-specific result in Redis for 5 minutes
    redis_client.set(
        cache_key,
        json.dumps(course),
        ex=REDIS_TTL,
    )

    return course


if __name__ == "__main__":
    course = get_course(1, "PY101")
    print(course)
