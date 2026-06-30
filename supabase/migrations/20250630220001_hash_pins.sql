-- Hashea los PINs existentes con bcrypt via pgcrypto
-- Evita que la anon key exponga PINs en texto plano
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ampliar columna para almacenar hash bcrypt (60 chars)
ALTER TABLE participantes ALTER COLUMN pin TYPE text;

-- Hashear PINs actuales en texto plano
UPDATE participantes
SET pin = crypt(pin::text, gen_salt('bf'))
WHERE pin NOT LIKE '$2a$%' AND pin NOT LIKE '$2b$%';

DROP FUNCTION IF EXISTS verify_and_create_session(uuid, text);
-- Reemplazar verify_and_create_session para comparar con hash
CREATE OR REPLACE FUNCTION verify_and_create_session(p_id uuid, p_pin text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER AS
$fn$
DECLARE
  v_pin     text;
  v_token   text;
  v_expires timestamptz;
BEGIN
  SELECT pin INTO v_pin FROM participantes WHERE id = p_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF crypt(p_pin, v_pin) <> v_pin THEN RETURN NULL; END IF;

  DELETE FROM sessions WHERE participante_id = p_id AND is_admin = false;

  v_expires := now() + interval '24 hours';
  INSERT INTO sessions (participante_id, is_admin, expires_at)
  VALUES (p_id, false, v_expires)
  RETURNING token INTO v_token;

  RETURN v_token;
END;
$fn$;

-- Reemplazar verify_admin_and_create_session (admin PIN no cambia, solo usuarios)
-- La comparacion de admin PIN sigue en la Edge Function con variable de entorno

-- Ocultar columna pin al rol anon: forzar acceso solo via RPC
CREATE OR REPLACE VIEW participantes_pub AS
  SELECT id, nombre, created_at FROM participantes;

GRANT SELECT ON participantes_pub TO anon, authenticated;
REVOKE SELECT ON participantes FROM anon, authenticated;
GRANT SELECT ON participantes TO service_role;
