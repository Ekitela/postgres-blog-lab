-- V4__row_level_security.sql
-- Row-Level Security for tenant data isolation

ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE students FORCE ROW LEVEL SECURITY;

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses FORCE ROW LEVEL SECURITY;

ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments FORCE ROW LEVEL SECURITY;

ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE results FORCE ROW LEVEL SECURITY;

CREATE POLICY students_tenant_policy
ON students
USING (
    tenant_id = current_setting('app.current_tenant')::INT
)
WITH CHECK (
    tenant_id = current_setting('app.current_tenant')::INT
);

CREATE POLICY courses_tenant_policy
ON courses
USING (
    tenant_id = current_setting('app.current_tenant')::INT
)
WITH CHECK (
    tenant_id = current_setting('app.current_tenant')::INT
);

CREATE POLICY enrollments_tenant_policy
ON enrollments
USING (
    tenant_id = current_setting('app.current_tenant')::INT
)
WITH CHECK (
    tenant_id = current_setting('app.current_tenant')::INT
);

CREATE POLICY results_tenant_policy
ON results
USING (
    tenant_id = current_setting('app.current_tenant')::INT
)
WITH CHECK (
    tenant_id = current_setting('app.current_tenant')::INT
);
