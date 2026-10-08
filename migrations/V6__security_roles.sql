
-- V6__security_roles.sql
-- Least-privilege application roles

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_read') THEN
        CREATE ROLE app_read NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_write') THEN
        CREATE ROLE app_write NOLOGIN;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE capstone TO app_read, app_write;
GRANT USAGE ON SCHEMA public TO app_read, app_write;

GRANT SELECT ON tenants, users, categories, students, courses, enrollments, results
TO app_read;

GRANT SELECT, INSERT, UPDATE, DELETE
ON tenants, users, categories, students, courses, enrollments, results
TO app_write;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
TO app_write;
