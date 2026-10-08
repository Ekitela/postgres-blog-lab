-- V1__core_tables.sql
-- Core schema for the Student Training Management System

CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id),
    username VARCHAR(100) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL,
    password_hash TEXT NOT NULL
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    parent_id INT REFERENCES categories(id)
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id),
    category_id INT REFERENCES categories(id),
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id),
    student_id INT NOT NULL REFERENCES students(id),
    course_id INT NOT NULL REFERENCES courses(id),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    UNIQUE (student_id, course_id)
);

CREATE TABLE results (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id),
    enrollment_id INT NOT NULL REFERENCES enrollments(id),
    score DECIMAL(5,2),
    grade VARCHAR(5),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tbl TEXT NOT NULL,
    op TEXT NOT NULL,
    old_row JSONB,
    new_row JSONB,
    changed_by TEXT NOT NULL DEFAULT current_user,
    at TIMESTAMPTZ NOT NULL DEFAULT now()
);
