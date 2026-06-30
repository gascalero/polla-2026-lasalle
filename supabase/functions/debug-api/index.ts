const FOOTBALL_API_KEY = Deno.env.get('FOOTBALL_DATA_API_KEY')!

Deno.serve(async () => {
  const res = await fetch('https://api.football-data.org/v4/competitions/WC/matches', {
    headers: { 'X-Auth-Token': FOOTBALL_API_KEY }
  })
  const data = await res.json()
  const match = (data.matches || []).find((m: any) =>
    (m.homeTeam?.name === 'Germany' || m.awayTeam?.name === 'Germany') &&
    (m.homeTeam?.name === 'Paraguay' || m.awayTeam?.name === 'Paraguay')
  )
  return new Response(JSON.stringify({ score: match?.score, status: match?.status }, null, 2), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
  })
})
