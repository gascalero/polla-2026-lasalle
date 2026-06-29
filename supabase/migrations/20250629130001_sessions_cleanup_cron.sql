-- ============================================================
-- Limpieza automática de sesiones expiradas
-- Requiere pg_cron habilitado: Database → Extensions → pg_cron
-- ============================================================

SELECT cron.schedule(
  'cleanup-expired-sessions',
  '0 3 * * *',
  $$DELETE FROM sessions WHERE expires_at < now();$$
);
