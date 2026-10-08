# Query Optimization and Performance Proof

## Query

The query retrieves the most recent student-related audit events:

    SELECT id, tbl, op, at
    FROM audit_log
    WHERE tbl = 'students'
    ORDER BY at DESC
    LIMIT 100;

## Baseline

The query was tested without the composite index `idx_audit_log_tbl_at`.

A temporary dataset of 100,000 audit records was used inside a transaction.

### BEFORE execution plan

- Scan: Sequential Scan
- Rows scanned: approximately 100,004
- Sort: Top-N heapsort
- Execution Time: **37.825 ms**

The plan was:

    Seq Scan -> Sort -> Limit

## Optimization

The following composite index was tested:

    CREATE INDEX idx_audit_log_tbl_at
    ON audit_log(tbl, at DESC);

The index supports both the `tbl = 'students'` filter and the `ORDER BY at DESC` operation.

## AFTER execution plan

- Scan: Index Scan
- Rows returned: 100
- Sort operation: eliminated
- Execution Time: **0.148 ms**

The plan changed to:

    Index Scan -> Limit

## Performance Result

| Metric | Before | After |
|---|---:|---:|
| Execution Time | 37.825 ms | 0.148 ms |
| Scan | Sequential Scan | Index Scan |
| Sort | Required | Eliminated |

The measured execution time improved by approximately **255x** in this test.

## Test Safety

The 100,000 test records and temporary index changes were performed inside a transaction and removed using:

    ROLLBACK;

Therefore, the production/demo data was not permanently modified.

## Conclusion

The composite index significantly improved this query by allowing PostgreSQL to locate the required `students` audit records in index order and avoid scanning and sorting the full matching dataset.
