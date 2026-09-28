CREATE OR REPLACE FUNCTION audit_expense_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            changed_by,
            old_data,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            NEW.id,
            TG_OP,
            NULLIF(current_setting('app.user_id', true), '')::BIGINT,
            NULL,
            to_jsonb(NEW)
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            changed_by,
            old_data,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            NEW.id,
            TG_OP,
            NULLIF(current_setting('app.user_id', true), '')::BIGINT,
            to_jsonb(OLD),
            to_jsonb(NEW)
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            changed_by,
            old_data,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            OLD.id,
            TG_OP,
            NULLIF(current_setting('app.user_id', true), '')::BIGINT,
            to_jsonb(OLD),
            NULL
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_expenses_audit
AFTER INSERT OR UPDATE OR DELETE
ON expenses
FOR EACH ROW
EXECUTE FUNCTION audit_expense_changes();