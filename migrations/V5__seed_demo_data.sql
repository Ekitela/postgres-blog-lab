-- V5__seed_demo_data.sql
-- Demo data for testing and presentation

INSERT INTO tenants (name)
VALUES
    ('Kakuma Training Centre'),
    ('Nairobi Training Centre');

INSERT INTO users (tenant_id, username, role, password_hash)
VALUES
    (1, 'admin_kakuma', 'administrator',
     '$2b$12$demoHashKakumaAdmin'),
    (2, 'admin_nairobi', 'administrator',
     '$2b$12$demoHashNairobiAdmin');

INSERT INTO categories (name, parent_id)
VALUES
    ('Technology', NULL),
    ('Programming', 1),
    ('Databases', 1),
    ('Web Development', 1);

INSERT INTO students (tenant_id, name, email, phone)
VALUES
    (1, 'Robert Ekitela', 'robert@example.com', '+254700000001'),
    (1, 'Alice Wanjiku', 'alice@example.com', '+254700000002'),
    (2, 'John Otieno', 'john@example.com', '+254700000003'),
    (2, 'Mary Achieng', 'mary@example.com', '+254700000004');

INSERT INTO courses (tenant_id, category_id, name, code, description)
VALUES
    (1, 2, 'Python Programming', 'PY101',
     'Introduction to Python programming'),
    (1, 3, 'PostgreSQL Database Administration', 'DB101',
     'Database design, administration, and optimization'),
    (2, 4, 'Web Development', 'WEB101',
     'Fundamentals of modern web development');

INSERT INTO enrollments (tenant_id, student_id, course_id, status)
VALUES
    (1, 1, 1, 'active'),
    (1, 2, 2, 'active'),
    (2, 3, 3, 'active'),
    (2, 4, 3, 'completed');

INSERT INTO results (tenant_id, enrollment_id, score, grade)
VALUES
    (1, 1, 85.00, 'A'),
    (1, 2, 78.00, 'B'),
    (2, 3, 91.00, 'A'),
    (2, 4, 88.00, 'A');
