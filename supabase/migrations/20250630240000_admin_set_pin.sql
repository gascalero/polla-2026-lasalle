-- admin_set_pin: permite al admin asignar PIN sin exponer el hash
-- El front llama este RPC en lugar de sbPatch directo
DROP FUNCTION IF EXISTS admin_set_pin(uuid, text);
CREATE OR REPLACE FUNCTION admin_set_pin(p_id uuid, p_pin text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS
$fn$
BEGIN
  UPDATE participantes SET pin = crypt(p_pin, gen_salt('bf')) WHERE id = p_id;
END;
$fn$;
