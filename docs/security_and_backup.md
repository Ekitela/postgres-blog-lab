# Security and Backup Evidence

## 1. Least-Privilege Database Roles

The application uses two database roles:

- `app_read` — read-only access to application tables.
- `app_write` — SELECT, INSERT, UPDATE, and DELETE access to application tables.

Neither role is a superuser, can create databases, can create roles, or can log in directly.

The `audit_log` table is excluded from application-role privileges so audit records cannot be modified directly by the application.

## 2. Row-Level Security

Row-Level Security (RLS) is enabled and forced on:

- `students`
- `courses`
- `enrollments`
- `results`

The tenant policies use the session setting:

    current_setting('app.current_tenant')::INT

This ensures that application queries are restricted to the active tenant.

### RLS Verification

Using the non-superuser `app_read` role:

- Tenant 1 returned only Robert Ekitela and Alice Wanjiku.
- Tenant 2 returned only John Otieno and Mary Achieng.

This confirms tenant isolation is enforced by PostgreSQL.

## 3. Audit Logging

Database triggers automatically record INSERT, UPDATE, and DELETE operations on:

- `students`
- `courses`
- `enrollments`
- `results`

The audit log stores the table, operation, old row, new row, database user, and timestamp.

Current verification recorded:

- Courses: 3 INSERT events
- Enrollments: 4 INSERT events
- Results: 4 INSERT events
- Students: 4 INSERT events

Total verified audit events: 15.

## 4. Password Security

The `users` table stores a `password_hash` field rather than plaintext passwords.

The demonstration seed values use bcrypt-style `$2b$` placeholders. These are demonstration values only and must be replaced with complete, securely generated password hashes before production deployment.

## 5. SQL Injection Protection

The Redis/Python application uses parameterized PostgreSQL queries.

Example:

    cur.execute(
        """
        SELECT id, name, code
        FROM courses
        WHERE code = %s
        """,
        (code,),
    )

The user-supplied value is passed separately from the SQL statement.

## 6. Database Backup

A PostgreSQL custom-format backup was created using:

    sudo -u postgres pg_dump -Fc -f "backups/capstone_$(date +%F).dump" capstone

Backup file:

    backups/capstone_2026-10-08.dump

The backup is excluded from Git using:

    backups/*.dump

## 7. Backup Restore Test

A temporary database named `capstone_restore_test` was created and the backup was restored successfully.

The restored database contained all expected tables:

- audit_log
- categories
- courses
- enrollments
- flyway_schema_history
- results
- students
- tenants
- users

The restored data was verified:

| Table | Rows |
|---|---:|
| tenants | 2 |
| users | 2 |
| students | 4 |
| courses | 3 |
| enrollments | 4 |
| results | 4 |
| audit_log | 15 |

After verification, the temporary restore database was removed.

## 8. Security Summary

The Student Training Management System applies multiple layers of database security:

1. Least-privilege database roles
2. Row-Level Security for tenant isolation
3. Database audit logging
4. Password hashing fields
5. Parameterized SQL queries
6. PostgreSQL backup and tested restore
7. Backup files excluded from source control
