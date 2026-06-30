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

    // verify_and_create_session hace la comparación bcrypt y crea la sesión
    const { data: token, error: rpcErr } = await supabase
      .rpc('verify_and_create_session', { p_id: participante_id, p_pin: String(pin) })

    if (rpcErr) return err('Error verificando PIN', 500)
    if (!token) return err('PIN incorrecto', 401)

    const expires_at = new Date(Date.now() + USER_TTL_HOURS * 3600 * 1000).toISOString()
    return new Response(JSON.stringify({ token, expires_at }), {
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
