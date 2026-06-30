-- Calcula el ranking completo con puntajes detallados por participante
CREATE OR REPLACE FUNCTION get_ranking()
RETURNS TABLE (
  participante_id   uuid,
  nombre            text,
  pts_total         numeric,
  pts_elim          numeric,
  pts_grupos        numeric,
  exactos_elim      int,
  exactos_grupos    int,
  ganadores_elim    int,
  ganadores_grupos  int,
  penalti_ok        int,
  penalti_miss      int
) LANGUAGE sql STABLE AS
'
WITH pts_g AS (
  SELECT
    p.participante_id,
    SUM(
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
    )::numeric AS pts,
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
    )::int AS ganadores
  FROM predicciones p
  JOIN partidos pa ON pa.id = p.partido_id
  GROUP BY p.participante_id
),
pts_e AS (
  SELECT
    p.participante_id,
    SUM(
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
    )::numeric AS pts,
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
  FROM predicciones_elim p
  JOIN partidos_elim pa ON pa.id = p.partido_id
  GROUP BY p.participante_id
)
SELECT
  par.id,
  par.nombre,
  COALESCE(e.pts, 0) + COALESCE(g.pts, 0),
  COALESCE(e.pts, 0),
  COALESCE(g.pts, 0),
  COALESCE(e.exactos, 0),
  COALESCE(g.exactos, 0),
  COALESCE(e.ganadores, 0),
  COALESCE(g.ganadores, 0),
  COALESCE(e.penalti_ok, 0),
  COALESCE(e.penalti_miss, 0)
FROM participantes par
LEFT JOIN pts_e e ON e.participante_id = par.id
LEFT JOIN pts_g g ON g.participante_id = par.id
ORDER BY 3 DESC, 6 DESC, 7 DESC
';