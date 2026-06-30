-- 1. get_ranking: SECURITY DEFINER para que anon pueda llamarlo aunque no tenga
--    SELECT en participantes ni en predicciones_elim
DROP FUNCTION IF EXISTS get_ranking();
CREATE OR REPLACE FUNCTION get_ranking()
RETURNS TABLE (
  participante_id    uuid,
  nombre             text,
  pts_total          numeric,
  exactos            int,
  ganadores          int,
  pts_goles          numeric,
  penalti_ok         int,
  penalti_miss       int
) LANGUAGE sql STABLE SECURITY DEFINER AS
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
  COALESCE(SUM(
    CASE WHEN pa.goles_local IS NOT NULL
      AND NOT (p.goles_local = pa.goles_local AND p.goles_visita = pa.goles_visita)
      AND p.goles_local = pa.goles_local THEN 0.5 ELSE 0 END
    + CASE WHEN pa.goles_local IS NOT NULL
      AND NOT (p.goles_local = pa.goles_local AND p.goles_visita = pa.goles_visita)
      AND p.goles_visita = pa.goles_visita THEN 0.5 ELSE 0 END
  ), 0)::numeric AS pts_goles,
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

-- 2. verify_pin: comparacion bcrypt
DROP FUNCTION IF EXISTS verify_pin(uuid, text);
CREATE OR REPLACE FUNCTION verify_pin(p_id uuid, p_pin text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS
$fn$
DECLARE
  stored_pin text;
BEGIN
  SELECT pin INTO stored_pin FROM participantes WHERE id = p_id;
  RETURN stored_pin IS NOT NULL AND crypt(p_pin, stored_pin) = stored_pin;
END;
$fn$;

-- 3. change_pin: hashea el PIN nuevo antes de guardarlo
DROP FUNCTION IF EXISTS change_pin(uuid, text, text);
CREATE OR REPLACE FUNCTION change_pin(p_id uuid, p_pin_actual text, p_pin_nuevo text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS
$fn$
DECLARE
  stored_pin text;
BEGIN
  SELECT pin INTO stored_pin FROM participantes WHERE id = p_id;
  IF stored_pin IS NULL THEN RETURN false; END IF;
  IF crypt(p_pin_actual, stored_pin) <> stored_pin THEN RETURN false; END IF;
  UPDATE participantes SET pin = crypt(p_pin_nuevo, gen_salt('bf')) WHERE id = p_id;
  RETURN true;
END;
$fn$;
