const FOOTBALL_API_KEY = Deno.env.get('FOOTBALL_DATA_API_KEY')!

Deno.serve(async () => {
  const res = await fetch('https://api.football-data.org/v4/competitions/WC/matches', {
    headers: { 'X-Auth-Token': FOOTBALL_API_KEY }
  })
  const data = await res.json()
  const targets = [
    ['Netherlands','Morocco'], ['Germany','Paraguay']
  ]
  const results = targets.map(([h, a]) => {
    const m = (data.matches || []).find((m: any) =>
      (m.homeTeam?.name === h || m.awayTeam?.name === h) &&
      (m.homeTeam?.name === a || m.awayTeam?.name === a)
    )
    if (!m) return { match: `${h} vs ${a}`, found: false }
    return {
      match: `${m.homeTeam?.name} vs ${m.awayTeam?.name}`,
      status: m.status,
      winner: m.score?.winner,
      duration: m.score?.duration,
      regularTime: m.score?.regularTime,
      extraTime: m.score?.extraTime,
      penalties: m.score?.penalties,
      fullTime: m.score?.fullTime,
      lastUpdated: m.lastUpdated
    }
  })
  return new Response(JSON.stringify(results, null, 2), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
  })
})
