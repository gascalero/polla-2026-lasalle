-- ============================================================
-- Tabla de auditoría inmutable para predicciones
-- ============================================================

CREATE TABLE IF NOT EXISTS audit_log (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  ts              timestamptz NOT NULL DEFAULT now(),
  tabla           text        NOT NULL,
  operacion       text        NOT NULL,  -- INSERT | UPDATE
  participante_id uuid,
  partido_id      text,
  datos_antes     jsonb,                 -- snapshot OLD (solo en UPDATE)
  datos_nuevo     jsonb       NOT NULL   -- snapshot NEW
);

-- Solo service role puede leer — protege la integridad del log
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Índices para consultas frecuentes
CREATE INDEX idx_audit_participante ON audit_log(participante_id);
CREATE INDEX idx_audit_partido      ON audit_log(partido_id);
CREATE INDEX idx_audit_ts           ON audit_log(ts DESC);

-- ── Función trigger ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_audit_prediccion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO audit_log (tabla, operacion, participante_id, partido_id, datos_antes, datos_nuevo)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    COALESCE(NEW.participante_id, OLD.participante_id),
    COALESCE(NEW.partido_id::text, OLD.partido_id::text),
    CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
    to_jsonb(NEW)
  );
  RETURN NEW;
END;
$$;

-- ── Triggers en ambas tablas de predicciones ──────────────────
CREATE TRIGGER audit_predicciones_elim
  AFTER INSERT OR UPDATE ON predicciones_elim
  FOR EACH ROW EXECUTE FUNCTION fn_audit_prediccion();

CREATE TRIGGER audit_predicciones
  AFTER INSERT OR UPDATE ON predicciones
  FOR EACH ROW EXECUTE FUNCTION fn_audit_prediccion();
