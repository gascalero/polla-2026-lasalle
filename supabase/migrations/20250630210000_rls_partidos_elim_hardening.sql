-- Restringe UPDATE en partidos_elim a service_role unicamente
-- Antes era public, lo que permitia escribir resultados saltandose el write-proxy
DROP POLICY IF EXISTS update_partidos_elim ON partidos_elim;
CREATE POLICY update_partidos_elim ON partidos_elim
  FOR UPDATE TO service_role
  USING (true) WITH CHECK (true);
