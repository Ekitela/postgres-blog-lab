# PostgreSQL Performance, Transactions and PgBouncer Lab

## Overview

This lab demonstrates PostgreSQL query performance analysis, index optimization, transaction isolation behavior, and PgBouncer connection pooling using the `blog_db` database.

## 1. Query Performance and Optimization

The `orders` table contains:

```text
2,000,000 rows
```

Before testing, PostgreSQL statistics were updated with:

```sql
ANALYZE orders;
```

### Query Tested

```sql
SELECT customer_id, SUM(amount)
FROM orders
WHERE status = 'pending'
  AND created_at > now() - interval '30 days'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;
```

### Index Used

The optimized query used the existing partial covering index:

```sql
CREATE INDEX idx_pending_recent_covering
ON orders (created_at DESC, customer_id)
INCLUDE (amount)
WHERE status = 'pending';
```

This index allows PostgreSQL to retrieve the required columns directly from the index for the tested query.

### Baseline: Parallel Sequential Scan

To obtain a baseline, both regular index scans and bitmap scans were disabled:

```sql
SET enable_indexscan = off;
SET enable_bitmapscan = off;
```

The execution plan used a parallel sequential scan:

```text
Parallel Seq Scan on orders
```

Important measurements:

```text
Execution Time: 11473.419 ms
Planning Time: 59.291 ms
Workers Planned: 2
Workers Launched: 2
Rows returned: 51943
Rows Removed by Filter: 649352
Buffers: shared hit=15811 read=856
```

The sequential scan examined the table using parallel workers and filtered rows based on `status` and `created_at`.

### Optimized: Index-Only Scan

Index and bitmap scans were then re-enabled:

```sql
SET enable_indexscan = on;
SET enable_bitmapscan = on;
```

The same query was executed again.

PostgreSQL selected:

```text
Index Only Scan using idx_pending_recent_covering
```

Important measurements:

```text
Execution Time: 326.143 ms
Planning Time: 0.283 ms
Heap Fetches: 6
Buffers: shared hit=264
Rows returned: 51943
```

### Performance Comparison

| Execution plan           | Execution time |
| ------------------------ | -------------: |
| Parallel sequential scan |  11,473.419 ms |
| Index-only scan          |     326.143 ms |

The indexed execution was approximately **35 times faster** than the sequential-scan execution in these measured runs.

The indexed plan also required substantially fewer shared buffer accesses:

```text
Sequential scan: 15,811 hit + 856 read
Index-only scan: 264 hit
```

## 2. Transaction Isolation

Two PostgreSQL transaction isolation levels were tested using concurrent sessions.

### READ COMMITTED

Session 1 started a transaction using the default READ COMMITTED isolation level and initially read:

```text
amount = 5555
```

Session 2 updated the same row:

```sql
UPDATE orders
SET amount = 9999
WHERE id = 1;
```

The update was committed.

When Session 1 executed the SELECT again, it observed:

```text
amount = 9999
```

This demonstrates that under READ COMMITTED, each statement can receive a new snapshot and can see changes committed by other transactions between statements.

### REPEATABLE READ

The row was reset to:

```text
amount = 5555
```

Session 1 started:

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

It initially read:

```text
amount = 5555
```

Session 2 then updated and committed:

```text
amount = 9999
```

When Session 1 queried the same row again before committing, it still observed:

```text
amount = 5555
```

After Session 1 committed, a new query observed:

```text
amount = 9999
```

This demonstrates that REPEATABLE READ maintains a stable transaction snapshot.

## 3. PgBouncer Connection Pooling

PgBouncer version:

```text
1.25.1
```

PgBouncer was configured as a transaction-level connection pooler.

### Configuration

```text
listen_addr = localhost
listen_port = 6432
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

The `blog_db` database was configured to forward connections to PostgreSQL:

```text
blog_db=host=172.29.16.1 port=5432 dbname=blog_db
```

PostgreSQL was listening on port:

```text
5432
```

PgBouncer was listening on:

```text
6432
```

### Connection Test

A connection was successfully established through PgBouncer with:

```bash
psql -h 127.0.0.1 -p 6432 -U postgres -d blog_db
```

The connection was verified with:

```sql
SELECT current_database(), inet_server_port();
```

The result was:

```text
current_database | blog_db
inet_server_port | 5432
```

This confirms that the client connected to PgBouncer on port `6432`, which forwarded the connection to PostgreSQL on port `5432`.

### PgBouncer Service

The PgBouncer service was running successfully and listening on:

```text
127.0.0.1:6432
```

The configured transaction pooling mode allows PgBouncer to reuse backend PostgreSQL connections between client transactions.

## 4. Summary

This lab demonstrated:

* PostgreSQL performance measurement using `EXPLAIN (ANALYZE, BUFFERS)`
* Baseline performance using a parallel sequential scan
* Optimization using a partial covering index
* Index-only scanning
* Execution-time and buffer comparisons
* READ COMMITTED transaction behavior
* REPEATABLE READ transaction behavior
* PgBouncer installation and configuration
* Transaction-level connection pooling
* Successful connection through PgBouncer
* Verification of the PostgreSQL backend connection

## 5. Important Security Note

Sensitive authentication information such as PostgreSQL passwords, PgBouncer `userlist.txt` credentials, and GitHub tokens must not be committed to this repository.


## 6. Backup, Point-in-Time Recovery, and Streaming Replication

### Logical Backup

A logical backup of the PostgreSQL database was created and verified as part of the backup lab.

### WAL Archiving and PITR

PostgreSQL WAL archiving was configured to support Point-in-Time Recovery (PITR).

A base backup was created and a separate standby data directory was prepared for recovery testing.

The recovered PostgreSQL instance was started on port `5433` and verified with:

```sql
SELECT version(), pg_is_in_recovery();
```

The recovery test confirmed that the restored PostgreSQL instance was in recovery mode.

### PITR Verification

The PITR recovery target was:

2026-09-28 10:44:29.101878+03


Before the simulated disaster, the `students` table contained 5 rows. The database was restored from the physical base backup and WAL archive to the selected recovery point.

After recovery, the database was promoted and verified with:

SELECT pg_is_in_recovery(), COUNT(*) FROM students;

The final result confirmed:

pg_is_in_recovery | count
------------------+------
f                 | 5

### Streaming Replication

A PostgreSQL streaming standby was created from the primary using `pg_basebackup`.

The standby was configured on port `5433`.

The standby was verified with:

SELECT pg_is_in_recovery() AS standby;

The result was:

standby
-------
t

This confirmed that the instance on port `5433` was operating as a standby.



### Live Replication Test

A test record was inserted into the primary:

INSERT INTO students (name, course)
VALUES ('Final Replication Test', 'Streaming Replication');

The record was successfully retrieved from the standby:

id | name | course
39 | Final Replication Test | Streaming Replication

This confirmed that changes made on the primary were replicated to the standby.


### Replication Health

Replication status on the primary was verified with:

SELECT application_name, client_addr, state, sync_state,
       pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS lag
FROM pg_stat_replication;

The result was:

application_name | client_addr | state | sync_state | lag
walreceiver | 127.0.0.1 | streaming | async | 0 bytes

The standby WAL positions were also verified:

SELECT pg_is_in_recovery() AS standby,
       pg_last_wal_receive_lsn() AS received_lsn,
       pg_last_wal_replay_lsn() AS replayed_lsn;

The result was:

standby | received_lsn | replayed_lsn
t | 0/11000680 | 0/11000680

The matching WAL positions confirmed that all received WAL had been replayed on the standby.

### Backup and Replication Summary

This lab demonstrated:

* Logical PostgreSQL backup using pg_dump
* Logical backup restoration and verification
* WAL archiving
* Physical base backup using pg_basebackup
* Point-in-Time Recovery (PITR)
* Recovery to a specified timestamp
* Promotion of a recovered PostgreSQL instance
* Streaming replication
* Primary-to-standby replication testing
* Replication health monitoring
* Verification of replication lag

No database passwords, replication passwords, or other sensitive authentication credentials were added to the repository.
