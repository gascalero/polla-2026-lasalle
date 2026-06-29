CREATE TABLE IF NOT EXISTS sessions (
  token        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participante_id integer REFERENCES participantes(id) ON DELETE CASCADE,
  is_admin     boolean NOT NULL DEFAULT false,
  expires_at   timestamptz NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Solo service role puede leer/escribir sesiones
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

-- Limpiar sesiones expiradas automáticamente (ejecutar periódicamente)
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);
