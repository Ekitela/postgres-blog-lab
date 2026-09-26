# PostgreSQL Performance and PgBouncer Lab

## Overview

This lab demonstrates PostgreSQL performance optimization, transaction isolation, and connection pooling using PgBouncer.

## 1. Query Performance

The `orders` table contains 2,000,000 rows.

The following query was analyzed using `EXPLAIN (ANALYZE, BUFFERS)`:

```sql
SELECT customer_id, SUM(amount)
FROM orders
WHERE status = 'pending'
  AND created_at > now() - interval '30 days'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;
