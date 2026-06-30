-- RPC: verifica PIN de usuario y crea sesión en un solo paso
-- SECURITY DEFINER: corre como owner, bypasea RLS
CREATE OR REPLACE FUNCTION verify_and_create_session(p_id uuid, p_pin text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stored text;
  v_token  uuid;
BEGIN
  SELECT pin INTO v_stored FROM participantes WHERE id = p_id;
  IF v_stored IS NULL OR v_stored != p_pin THEN
    RETURN NULL; -- PIN incorrecto
  END IF;

  -- Limpiar sesiones anteriores del usuario
  DELETE FROM sessions WHERE participante_id = p_id AND is_admin = false;

  -- Crear nueva sesión (24h)
  v_token := gen_random_uuid();
  INSERT INTO sessions (token, participante_id, is_admin, expires_at)
  VALUES (v_token, p_id, false, now() + interval '24 hours');

  RETURN v_token;
END;
$$;

-- RPC: verifica PIN admin y crea sesión admin
CREATE OR REPLACE FUNCTION verify_admin_and_create_session(p_pin text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stored text;
  v_token  uuid;
BEGIN
  SELECT valor INTO v_stored FROM configuracion WHERE clave = 'admin_pin';
  IF v_stored IS NULL OR v_stored != p_pin THEN
    RETURN NULL;
  END IF;

  -- Limpiar sesiones admin expiradas
  DELETE FROM sessions WHERE is_admin = true AND expires_at < now();

  v_token := gen_random_uuid();
  INSERT INTO sessions (token, participante_id, is_admin, expires_at)
  VALUES (v_token, NULL, true, now() + interval '4 hours');

  RETURN v_token;
END;
$$;
