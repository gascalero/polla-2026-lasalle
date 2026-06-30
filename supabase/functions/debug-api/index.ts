const FOOTBALL_API_KEY = Deno.env.get('FOOTBALL_DATA_API_KEY')!

Deno.serve(async () => {
  const res = await fetch('https://api.football-data.org/v4/competitions/WC/matches?status=IN_PLAY,PAUSED,LIVE', {
    headers: { 'X-Auth-Token': FOOTBALL_API_KEY }
  })
  const data = await res.json()
  const matches = (data.matches || []).map((m: any) => ({
    home: m.homeTeam?.name,
    away: m.awayTeam?.name,
    status: m.status,
    duration: m.score?.duration,
    fullTime: m.score?.fullTime,
    regularTime: m.score?.regularTime,
    extraTime: m.score?.extraTime,
    penalties: m.score?.penalties,
  }))
  return new Response(JSON.stringify({ matches }, null, 2), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
  })
})
