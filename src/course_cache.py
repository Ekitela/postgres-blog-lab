"""Redis cache-aside example for course data."""

import json
import os

import psycopg
import redis


REDIS_TTL = 300


def get_course(code):
    cache_key = f"course:{code}"

    # Connect to Redis
    r = redis.Redis(host="127.0.0.1", port=6379, decode_responses=True)

    # 1. Check Redis first
    cached = r.get(cache_key)

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
                WHERE code = %s
                """,
                (code,),
            )

            row = cur.fetchone()

    if row is None:
        return None

    course = {
        "id": row[0],
        "name": row[1],
        "code": row[2],
    }

    # 3. Store the result in Redis for 5 minutes
    r.set(cache_key, json.dumps(course), ex=REDIS_TTL)

    return course


if __name__ == "__main__":
    course = get_course("PY101")
    print(course)
