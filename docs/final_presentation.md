# Student Training Management System
## Capstone Final Presentation

---

## Slide 1 — Project Overview

### Student Training Management System

A multi-tenant PostgreSQL-based system for managing:

- Training institutions
- Users
- Students
- Courses
- Enrollments
- Results
- Audit records

### Technologies

- PostgreSQL 18.6
- Flyway migrations
- Redis 8.0.5
- Python
- Git/GitHub

---

## Slide 2 — Problem and Requirements

### Problem

Training organizations need a reliable system to manage student training data while keeping data from different institutions isolated.

### Key Requirements

- Manage multiple training tenants
- Store student and course information
- Track enrollments and results
- Support hierarchical course categories
- Protect tenant data
- Record database changes
- Improve query performance
- Provide backup and recovery

---

## Slide 3 — Database Design

### Core Entities

- tenants
- users
- categories
- students
- courses
- enrollments
- results
- audit_log

### Key Relationships

- A tenant has many students and courses.
- Students enroll in courses through enrollments.
- Enrollments have results.
- Courses belong to categories.
- Audit triggers record changes to important tables.

### Schema Management

The database is managed using versioned Flyway migrations:

- V1 — Core tables
- V2 — Indexes
- V3 — Audit and triggers
- V4 — Row-Level Security
- V5 — Demo seed data
- V6 — Security roles
- V7 — Performance indexes

---

## Slide 4 — Multi-Tenancy and Security

### Row-Level Security

RLS is enabled and forced on:

- students
- courses
- enrollments
- results

Tenant filtering uses:

    current_setting('app.current_tenant')::INT

### Verification

Tenant 1 can see only:

- Robert Ekitela
- Alice Wanjiku

Tenant 2 can see only:

- John Otieno
- Mary Achieng

This demonstrates database-level tenant isolation.

---

## Slide 5 — Least Privilege and Auditing

### Database Roles

`app_read`

- SELECT access to application tables
- No superuser privileges
- Cannot create databases or roles
- Cannot log in directly

`app_write`

- SELECT, INSERT, UPDATE, DELETE
- No superuser privileges
- Cannot create databases or roles
- Cannot log in directly

### Audit Logging

Triggers automatically record database changes.

Verified audit events:

- Courses: 3 INSERTs
- Enrollments: 4 INSERTs
- Results: 4 INSERTs
- Students: 4 INSERTs

Total: 15 events

---

## Slide 6 — Redis Caching

### Why Redis?

Redis is used as a cache for frequently accessed course information.

Example cache key:

    course:PY101

### Cache Strategy

1. Application checks Redis.
2. CACHE HIT returns cached data.
3. CACHE MISS queries PostgreSQL.
4. Result is stored in Redis.
5. Cache expires after 300 seconds.

### Data Ownership

PostgreSQL remains the source of truth.

Redis stores temporary cached copies only.

---

## Slide 7 — Performance Optimization

### Enrollment Query

The enrollment query filters by tenant and status.

A composite index was added:

    idx_enrollments_tenant_status

On the small demo dataset, PostgreSQL correctly chose a sequential scan because the table contained only a few rows.

### Controlled Performance Test

To demonstrate the benefit of indexing at a larger scale, a controlled audit-log benchmark used 100,000 temporary rows.

- Before index: 37.825 ms
- After index: 0.148 ms

The execution plan changed from a sequential scan plus sort to an index scan.

This demonstrated a substantial performance improvement.

---

## Slide 8 — Backup and Recovery

### Backup

A PostgreSQL custom-format backup was created:

    pg_dump -Fc

Backup:

    backups/capstone_2026-10-08.dump

### Restore Test

The backup was restored into a temporary database.

Verified after restoration:

- Tenants: 2
- Users: 2
- Students: 4
- Courses: 3
- Enrollments: 4
- Results: 4
- Audit events: 15

The temporary restore database was then removed.

---

## Slide 9 — Conclusion and Demo

### What Was Delivered

- Complete multi-tenant PostgreSQL schema
- Version-controlled Flyway migrations
- RLS tenant isolation
- Least-privilege database roles
- Audit logging
- Redis caching
- Performance optimization evidence
- Backup and tested recovery
- Security documentation
- GitHub source control

### Final Demonstration

Show:

1. Database schema
2. Flyway migration history
3. RLS tenant isolation
4. Redis CACHE MISS and CACHE HIT
5. Performance EXPLAIN plans
6. Backup and restore evidence

### Conclusion

The Student Training Management System demonstrates a secure, scalable, and maintainable PostgreSQL-based application design with caching, performance optimization, tenant isolation, auditing, and recovery capabilities.
