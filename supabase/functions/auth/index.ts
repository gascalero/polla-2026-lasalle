import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ADMIN_PIN    = Deno.env.get('ADMIN_PIN')!

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, authorization',
}

const USER_TTL_HOURS  = 24
const ADMIN_TTL_HOURS = 4

function err(msg: string, status = 400) {
  return new Response(JSON.stringify({ error: msg }), {
    status, headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: CORS })
  if (req.method !== 'POST') return err('Method not allowed', 405)

  let body: any
  try { body = await req.json() } catch { return err('Invalid JSON') }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY)

  // ── Autenticación de usuario normal ────────────────────────────────────────
  if (body.participante_id && body.pin) {
    const { participante_id, pin } = body

    // Verificar PIN contra la BD
    const { data: part, error } = await supabase
      .from('participantes')
      .select('id, pin')
      .eq('id', participante_id)
      .single()

    if (error || !part) return err('Participante no encontrado', 404)

    // Comparación segura del PIN
    if (String(part.pin) !== String(pin)) return err('PIN incorrecto', 401)

    // Limpiar sesiones anteriores del usuario
    await supabase.from('sessions')
      .delete()
      .eq('participante_id', participante_id)
      .eq('is_admin', false)

    // Crear nueva sesión
    const expires_at = new Date(Date.now() + USER_TTL_HOURS * 3600 * 1000).toISOString()
    const { data: session, error: sErr } = await supabase
      .from('sessions')
      .insert({ participante_id, is_admin: false, expires_at })
      .select('token, expires_at')
      .single()

    if (sErr || !session) return err('Error creando sesión', 500)

    return new Response(JSON.stringify({ token: session.token, expires_at: session.expires_at }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  }

  // ── Autenticación de admin ──────────────────────────────────────────────────
  if (body.admin_pin) {
    if (body.admin_pin !== ADMIN_PIN) return err('PIN admin incorrecto', 401)

    // Limpiar sesiones admin anteriores
    await supabase.from('sessions')
      .delete()
      .eq('is_admin', true)
      .lt('expires_at', new Date().toISOString())

    const expires_at = new Date(Date.now() + ADMIN_TTL_HOURS * 3600 * 1000).toISOString()
    const { data: session, error: sErr } = await supabase
      .from('sessions')
      .insert({ participante_id: null, is_admin: true, expires_at })
      .select('token, expires_at')
      .single()

    if (sErr || !session) return err('Error creando sesión admin', 500)

    return new Response(JSON.stringify({ token: session.token, expires_at: session.expires_at }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  }

  return err('Parámetros inválidos')
})
