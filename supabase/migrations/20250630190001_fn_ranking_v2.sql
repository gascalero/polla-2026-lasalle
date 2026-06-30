-- v2: solo fase eliminatoria (la de grupos fue un juego anterior independiente)
CREATE OR REPLACE FUNCTION get_ranking()
RETURNS TABLE (
  participante_id  uuid,
  nombre           text,
  pts_total        numeric,
  exactos          int,
  ganadores        int,
  penalti_ok       int,
  penalti_miss     int
) LANGUAGE sql STABLE AS
'
SELECT
  par.id,
  par.nombre,
  COALESCE(SUM(
    CASE
      WHEN pa.goles_local IS NULL THEN 0
      WHEN p.goles_local = pa.goles_local AND p.goles_visita = pa.goles_visita THEN 3
      WHEN (p.goles_local > p.goles_visita) = (pa.goles_local > pa.goles_visita)
        AND (p.goles_local < p.goles_visita) = (pa.goles_local < pa.goles_visita) THEN 1
      ELSE 0
    END
    + CASE WHEN pa.goles_local IS NOT NULL
        AND NOT (p.goles_local = pa.goles_local AND p.goles_visita = pa.goles_visita)
        AND p.goles_local = pa.goles_local THEN 0.5 ELSE 0 END
    + CASE WHEN pa.goles_local IS NOT NULL
        AND NOT (p.goles_local = pa.goles_local AND p.goles_visita = pa.goles_visita)
        AND p.goles_visita = pa.goles_visita THEN 0.5 ELSE 0 END
    + CASE WHEN p.pred_penaltis = true AND pa.penaltis = true
        AND p.pred_ganador_pen IS NOT NULL
        AND p.pred_ganador_pen = pa.ganador_pen THEN 2 ELSE 0 END
    + CASE WHEN pa.estado = ''finalizado''
        AND p.pred_penaltis = true
        AND pa.penaltis IS NOT TRUE
        AND pa.penalti_miss_activo IS NOT FALSE THEN -1 ELSE 0 END
  ), 0)::numeric AS pts_total,
  COUNT(*) FILTER (
    WHERE pa.goles_local IS NOT NULL
      AND p.goles_local = pa.goles_local
      AND p.goles_visita = pa.goles_visita
  )::int AS exactos,
  COUNT(*) FILTER (
    WHERE pa.goles_local IS NOT NULL
      AND NOT (p.goles_local = pa.goles_local AND p.goles_visita = pa.goles_visita)
      AND (p.goles_local > p.goles_visita) = (pa.goles_local > pa.goles_visita)
      AND (p.goles_local < p.goles_visita) = (pa.goles_local < pa.goles_visita)
  )::int AS ganadores,
  COUNT(*) FILTER (
    WHERE p.pred_penaltis = true AND pa.penaltis = true
      AND p.pred_ganador_pen IS NOT NULL
      AND p.pred_ganador_pen = pa.ganador_pen
  )::int AS penalti_ok,
  COUNT(*) FILTER (
    WHERE pa.estado = ''finalizado''
      AND p.pred_penaltis = true
      AND pa.penaltis IS NOT TRUE
      AND pa.penalti_miss_activo IS NOT FALSE
  )::int AS penalti_miss
FROM participantes par
LEFT JOIN predicciones_elim p ON p.participante_id = par.id
LEFT JOIN partidos_elim pa ON pa.id = p.partido_id
GROUP BY par.id, par.nombre
ORDER BY pts_total DESC, exactos DESC, ganadores DESC
';
