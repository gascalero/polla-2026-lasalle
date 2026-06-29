import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type',
}

// Qué tabla puede hacer qué operaciones, y si requiere admin
const TABLE_RULES: Record<string, { ops: string[], adminOnly: boolean }> = {
  predicciones_elim: { ops: ['insert', 'update', 'upsert'], adminOnly: false },
  predicciones_g:    { ops: ['insert', 'update', 'upsert'], adminOnly: false },
  partidos_elim:     { ops: ['update'],                     adminOnly: true  },
  partidos_g:        { ops: ['update'],                     adminOnly: true  },
  participantes:     { ops: ['update'],                     adminOnly: true  },
}

function err(msg: string, status = 400) {
  return new Response(JSON.stringify({ error: msg }), {
    status, headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

function ok(data: unknown) {
  return new Response(JSON.stringify(data ?? null), {
    status: 200, headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: CORS })
  if (req.method !== 'POST') return err('Method not allowed', 405)

  let body: any
  try { body = await req.json() } catch { return err('Invalid JSON') }

  const { operation, tabla, body: payload, eq, session_token } = body

  // ── 1. Validar session_token ───────────────────────────────────────────────
  if (!session_token) return err('session_token requerido', 401)

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY)
  const { data: session, error: sErr } = await supabase
    .from('sessions')
    .select('token, participante_id, is_admin, expires_at')
    .eq('token', session_token)
    .single()

  if (sErr || !session) return err('Sesión inválida', 401)
  if (new Date(session.expires_at) < new Date()) {
    await supabase.from('sessions').delete().eq('token', session_token)
    return err('Sesión expirada — vuelve a iniciar sesión', 401)
  }

  // ── 2. Validar tabla y operación ───────────────────────────────────────────
  const rule = TABLE_RULES[tabla]
  if (!rule) return err(`Tabla no permitida: ${tabla}`, 403)
  if (!rule.ops.includes(operation)) {
    return err(`Operación '${operation}' no permitida en '${tabla}'`, 403)
  }

  // ── 3. Validar permisos según tipo de sesión ───────────────────────────────
  if (rule.adminOnly && !session.is_admin) {
    return err('Se requiere sesión de admin', 403)
  }

  // ── 4. Para predicciones: verificar ownership ──────────────────────────────
  if (!rule.adminOnly) {
    const rows = Array.isArray(payload) ? payload : [payload]
    const ids  = [...new Set(rows.map((r: any) => r?.participante_id).filter(Boolean))]

    // Solo se puede escribir para el propio participante_id de la sesión
    if (!ids.length || ids.some(id => String(id) !== String(session.participante_id))) {
      return err('No puedes escribir predicciones de otro participante', 403)
    }

    // Para updates con eq: verificar que el eq.participante_id coincide
    if (eq?.participante_id && String(eq.participante_id) !== String(session.participante_id)) {
      return err('No puedes modificar predicciones de otro participante', 403)
    }
  }

  // ── 5. Ejecutar escritura con service role ─────────────────────────────────
  let result: any, dbError: any

  if (operation === 'insert') {
    ;({ data: result, error: dbError } = await supabase.from(tabla).insert(payload).select())
  } else if (operation === 'upsert') {
    ;({ data: result, error: dbError } = await supabase.from(tabla).upsert(payload).select())
  } else if (operation === 'update') {
    let q = supabase.from(tabla).update(payload)
    if (eq) {
      for (const [col, val] of Object.entries(eq)) q = (q as any).eq(col, val)
    }
    ;({ data: result, error: dbError } = await (q as any).select())
  }

  if (dbError) return err(dbError.message, 500)
  return ok(result)
})
