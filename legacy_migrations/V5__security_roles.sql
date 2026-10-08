
-- V5__security_roles.sql
-- Least-privilege database roles and permissions

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = 'app_read'
    ) THEN
        CREATE ROLE app_read NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = 'app_write'
    ) THEN
        CREATE ROLE app_write NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = 'api'
    ) THEN
        CREATE ROLE api NOLOGIN;
    END IF;
END
$$;

-- Database access
GRANT CONNECT ON DATABASE blog_db TO app_read, app_write, api;

-- Schema access
GRANT USAGE ON SCHEMA public TO app_read, app_write, api;

-- Read-only access
GRANT SELECT ON students TO app_read;

-- Read/write access
GRANT SELECT, INSERT, UPDATE, DELETE
ON students TO app_write;

-- API inherits app_write permissions
GRANT app_write TO api;
