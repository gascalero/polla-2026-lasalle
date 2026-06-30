-- sync_bloqueado ya no cumple función: sync-results no escribe en la BD
ALTER TABLE partidos_elim DROP COLUMN IF EXISTS sync_bloqueado;
