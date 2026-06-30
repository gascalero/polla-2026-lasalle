import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FOOTBALL_API_KEY = Deno.env.get('FOOTBALL_DATA_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Mapeo: nombre API (inglés) → nombre en la DB (español)
const TEAM_MAP: Record<string, string> = {
  'Mexico': 'México',
  'United States': 'Estados Unidos',
  'USA': 'Estados Unidos',
  'Canada': 'Canadá',
  'Germany': 'Alemania',
  'France': 'Francia',
  'Spain': 'España',
  'Brazil': 'Brasil',
  'Argentina': 'Argentina',
  'England': 'Inglaterra',
  'Netherlands': 'Países Bajos',
  'Holland': 'Países Bajos',
  'Portugal': 'Portugal',
  'Belgium': 'Bélgica',
  'Croatia': 'Croacia',
  'Japan': 'Japón',
  'South Korea': 'Corea del Sur',
  'Korea Republic': 'Corea del Sur',
  'Morocco': 'Marruecos',
  'Switzerland': 'Suiza',
  'Uruguay': 'Uruguay',
  'Colombia': 'Colombia',
  'Ecuador': 'Ecuador',
  'Senegal': 'Senegal',
  'Tunisia': 'Túnez',
  'Australia': 'Australia',
  'Serbia': 'Serbia',
  'Poland': 'Polonia',
  'Denmark': 'Dinamarca',
  'Sweden': 'Suecia',
  'Norway': 'Noruega',
  'Austria': 'Austria',
  'Turkey': 'Turquía',
  'Türkiye': 'Turquía',
  'Egypt': 'Egipto',
  'Iran': 'Irán',
  'Saudi Arabia': 'Arabia Saudí',
  'Qatar': 'Catar',
  'Cameroon': 'Camerún',
  'Ghana': 'Ghana',
  'Ivory Coast': 'Costa de Marfil',
  'Côte d\'Ivoire': 'Costa de Marfil',
  'Senegal': 'Senegal',
  'Algeria': 'Argelia',
  'DR Congo': 'RD Congo',
  'Panama': 'Panamá',
  'Paraguay': 'Paraguay',
  'Bolivia': 'Bolivia',
  'Chile': 'Chile',
  'Peru': 'Perú',
  'Venezuela': 'Venezuela',
  'Costa Rica': 'Costa Rica',
  'Honduras': 'Honduras',
  'Guatemala': 'Guatemala',
  'Jamaica': 'Jamaica',
  'Haiti': 'Haití',
  'Curacao': 'Curazao',
  'New Zealand': 'Nueva Zelanda',
  'Scotland': 'Escocia',
  'Wales': 'Gales',
  'Czechia': 'Chequia',
  'Czech Republic': 'Chequia',
  'Jordan': 'Jordania',
  'Iraq': 'Irak',
  'Uzbekistan': 'Uzbekistán',
  'Cape Verde': 'Cabo Verde',
  'Bosnia and Herzegovina': 'Bosnia y Herzegovina',
  'South Africa': 'Sudáfrica',
}

const STATUS_MAP: Record<string, string> = {
  'SCHEDULED': 'pendiente',
  'TIMED': 'pendiente',
  'IN_PLAY': 'en_curso',
  'PAUSED': 'en_curso',
  'FINISHED': 'finalizado',
  'SUSPENDED': 'pendiente',
  'POSTPONED': 'pendiente',
  'CANCELLED': 'pendiente',
}

const KNOCKOUT_STAGES = ['LAST_32', 'ROUND_OF_32', 'ROUND_OF_16', 'QUARTER_FINALS', 'SEMI_FINALS', 'THIRD_PLACE', 'FINAL']

Deno.serve(async (req) => {
  // CORS para llamadas desde el browser
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      }
    })
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // 0. Cooldown server-side: solo llamar a la API si pasaron ≥30s desde el último sync
    const COOLDOWN_S = 30
    const { data: cfg } = await supabase
      .from('configuracion')
      .select('valor')
      .eq('clave', 'last_api_sync')
      .single()

    if (cfg?.valor) {
      const secsSince = (Date.now() - new Date(cfg.valor).getTime()) / 1000
      if (secsSince < COOLDOWN_S) {
        return new Response(JSON.stringify({ updated: 0, message: `Cooldown — próximo sync en ${Math.ceil(COOLDOWN_S - secsSince)}s` }), {
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
        })
      }
    }

    // Registrar timestamp ANTES de la llamada (evita race conditions)
    await supabase.from('configuracion').upsert({ clave: 'last_api_sync', valor: new Date().toISOString() })

    // 1. Traer partidos de eliminatorias de football-data.org
    const apiRes = await fetch('https://api.football-data.org/v4/competitions/WC/matches', {
      headers: { 'X-Auth-Token': FOOTBALL_API_KEY }
    })

    if (!apiRes.ok) {
      const err = await apiRes.text()
      return new Response(JSON.stringify({ error: `API error: ${apiRes.status} — ${err}` }), {
        status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      })
    }

    const apiData = await apiRes.json()
    const allStages = [...new Set((apiData.matches || []).map((m: any) => m.stage))]
    const knockoutMatches = (apiData.matches || []).filter((m: any) =>
      KNOCKOUT_STAGES.includes(m.stage)
    )

    // Solo devolver datos en vivo para el banner — sin escribir nada en la BD
    const live = knockoutMatches
      .filter((m: any) => m.status === 'IN_PLAY' || m.status === 'PAUSED' || m.status === 'FINISHED')
      .map((m: any) => {
        const duration = m.score?.duration
        let home: number | null = null
        let away: number | null = null
        if (duration === 'EXTRA_TIME' || duration === 'PENALTY_SHOOTOUT') {
          const rtH = m.score?.regularTime?.home
          const rtA = m.score?.regularTime?.away
          if (rtH != null) { home = rtH + (m.score?.extraTime?.home ?? 0); away = rtA + (m.score?.extraTime?.away ?? 0) }
        } else {
          home = m.score?.fullTime?.home ?? null
          away = m.score?.fullTime?.away ?? null
        }
        return {
          local:    TEAM_MAP[m.homeTeam.name] || m.homeTeam.name,
          visita:   TEAM_MAP[m.awayTeam.name] || m.awayTeam.name,
          estado:   STATUS_MAP[m.status] || m.status,
          goles_local:  home,
          goles_visita: away,
          penaltis: m.score?.duration === 'PENALTY_SHOOTOUT',
        }
      })

    return new Response(JSON.stringify({ live, all_stages: allStages }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })

  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }
})
