ALTER TABLE courses
    DROP CONSTRAINT courses_code_key;

ALTER TABLE courses
    ADD CONSTRAINT courses_tenant_code_key
    UNIQUE (tenant_id, code);

ALTER TABLE students
    DROP CONSTRAINT students_email_key;

ALTER TABLE students
    ADD CONSTRAINT students_tenant_email_key
    UNIQUE (tenant_id, email);
