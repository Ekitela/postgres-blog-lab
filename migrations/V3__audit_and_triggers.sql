-- V3__audit_and_triggers.sql
-- Audit logging for critical data changes

CREATE OR REPLACE FUNCTION audit_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        tbl,
        op,
        old_row,
        new_row,
        changed_by
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE
            WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD)
            ELSE NULL
        END,
        CASE
            WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW)
            ELSE NULL
        END,
        current_user
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_students_audit
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
EXECUTE FUNCTION audit_changes();

CREATE TRIGGER trg_courses_audit
AFTER INSERT OR UPDATE OR DELETE ON courses
FOR EACH ROW
EXECUTE FUNCTION audit_changes();

CREATE TRIGGER trg_enrollments_audit
AFTER INSERT OR UPDATE OR DELETE ON enrollments
FOR EACH ROW
EXECUTE FUNCTION audit_changes();

CREATE TRIGGER trg_results_audit
AFTER INSERT OR UPDATE OR DELETE ON results
FOR EACH ROW
EXECUTE FUNCTION audit_changes();
