CREATE TABLE IF NOT EXISTS audit_log (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tbl TEXT,
  op TEXT,
  old_row JSONB,
  new_row JSONB,
  changed_by TEXT DEFAULT current_user,
  at TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION audit() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log(tbl, op, old_row, new_row)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    to_jsonb(OLD),
    to_jsonb(NEW)
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit ON students;

CREATE TRIGGER trg_audit
AFTER INSERT OR UPDATE OR DELETE
ON students
FOR EACH ROW
EXECUTE FUNCTION audit();
