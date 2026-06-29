import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL        = Deno.env.get('SUPABASE_URL')!
const SERVICE_KEY         = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const WRITE_TOKEN         = Deno.env.get('WRITE_TOKEN')!
const ADMIN_PIN           = Deno.env.get('ADMIN_PIN')!

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-admin-pin',
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
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

function ok(data: unknown) {
  return new Response(JSON.stringify(data ?? null), {
    status: 200,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: CORS })
  if (req.method !== 'POST') return err('Method not allowed', 405)

  // ── 1. Parsear body ────────────────────────────────────────────────────────
  let body: any
  try { body = await req.json() } catch { return err('Invalid JSON') }

  const { operation, tabla, body: payload, eq, write_token } = body

  // ── 2. Validar WRITE_TOKEN ─────────────────────────────────────────────────
  if (!write_token || write_token !== WRITE_TOKEN) {
    return err('Unauthorized', 401)
  }

  // ── 3. Validar tabla y operación ───────────────────────────────────────────
  const rule = TABLE_RULES[tabla]
  if (!rule) return err(`Tabla no permitida: ${tabla}`, 403)
  if (!rule.ops.includes(operation)) {
    return err(`Operación '${operation}' no permitida en '${tabla}'`, 403)
  }

  // ── 4. Validar admin PIN para operaciones de admin ─────────────────────────
  if (rule.adminOnly) {
    const adminPin = req.headers.get('x-admin-pin')
    if (!adminPin || adminPin !== ADMIN_PIN) {
      return err('Admin PIN requerido', 403)
    }
  }

  // ── 5. Validar participante_id para predicciones ───────────────────────────
  if (!rule.adminOnly) {
    const rows = Array.isArray(payload) ? payload : [payload]
    const ids  = [...new Set(rows.map((r: any) => r?.participante_id).filter(Boolean))]

    if (!ids.length) return err('participante_id requerido')

    // Verificar que todos los IDs existen en la tabla participantes
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY)
    const { data: parts, error } = await supabase
      .from('participantes')
      .select('id')
      .in('id', ids)

    if (error) return err('Error verificando participante')
    if (!parts || parts.length !== ids.length) {
      return err('participante_id inválido', 403)
    }
  }

  // ── 6. Ejecutar escritura con service role ─────────────────────────────────
  const supabase = createClient(SUPABASE_URL, SERVICE_KEY)
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
  } else if (operation === 'delete') {
    let q = supabase.from(tabla).delete()
    if (eq) {
      for (const [col, val] of Object.entries(eq)) q = (q as any).eq(col, val)
    }
    ;({ data: result, error: dbError } = await (q as any).select())
  }

  if (dbError) return err(dbError.message, 500)
  return ok(result)
})
