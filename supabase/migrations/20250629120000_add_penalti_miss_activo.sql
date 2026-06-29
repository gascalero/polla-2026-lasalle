-- Permite desactivar la deducción de -1 pt por partido individual
-- Default true = la regla aplica. false = partido exento.
ALTER TABLE partidos_elim
  ADD COLUMN IF NOT EXISTS penalti_miss_activo boolean NOT NULL DEFAULT true;
