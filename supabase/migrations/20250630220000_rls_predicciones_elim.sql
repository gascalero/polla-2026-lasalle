-- Oculta predicciones de partidos que aun no han iniciado
-- Evita que alguien lea marcadores de otros antes del cierre
ALTER TABLE predicciones_elim ENABLE ROW LEVEL SECURITY;

-- Solo se pueden ver predicciones de partidos ya iniciados (hora_inicio <= now())
-- El service_role ve todo (para write-proxy, ranking, audit)
CREATE POLICY "ver_predicciones_partido_iniciado" ON predicciones_elim
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM partidos_elim pe
      WHERE pe.id = predicciones_elim.partido_id
        AND pe.hora_inicio <= now()
    )
  );

-- INSERT/UPDATE/DELETE solo via service_role (write-proxy)
CREATE POLICY "escribir_predicciones_service_role" ON predicciones_elim
  FOR ALL TO service_role USING (true) WITH CHECK (true);
