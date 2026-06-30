-- ============================================================
-- RLS Hardening: limitar anon key a solo lectura
-- ============================================================

ALTER TABLE participantes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_participantes" ON participantes
  FOR SELECT USING (true);

ALTER TABLE partidos_elim ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_partidos_elim" ON partidos_elim
  FOR SELECT USING (true);

ALTER TABLE partidos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_partidos" ON partidos
  FOR SELECT USING (true);

ALTER TABLE configuracion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_configuracion" ON configuracion
  FOR SELECT USING (true);

-- sessions: RLS ya activo, sin políticas para anon = acceso cero
