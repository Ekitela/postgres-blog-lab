-- V2__indexes.sql
-- Indexes for common lookups, joins, filtering, and reporting

CREATE INDEX idx_users_tenant_id
    ON users(tenant_id);

CREATE INDEX idx_students_tenant_id
    ON students(tenant_id);

CREATE INDEX idx_courses_tenant_id
    ON courses(tenant_id);

CREATE INDEX idx_courses_category_id
    ON courses(category_id);

CREATE INDEX idx_enrollments_tenant_id
    ON enrollments(tenant_id);

CREATE INDEX idx_enrollments_student_id
    ON enrollments(student_id);

CREATE INDEX idx_enrollments_course_id
    ON enrollments(course_id);

CREATE INDEX idx_results_tenant_id
    ON results(tenant_id);

CREATE INDEX idx_results_enrollment_id
    ON results(enrollment_id);

CREATE INDEX idx_categories_parent_id
    ON categories(parent_id);

CREATE INDEX idx_audit_log_tbl_at
    ON audit_log(tbl, at DESC);
