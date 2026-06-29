# Helix Team — Polla Mundial 2026 LaSalle
> Actualizado: 2026-06-29 por /helix-analiza | Actualizar con: /helix-actualiza

## Equipo Activo

| Rol | Agente | Dominio | Archivos típicos |
|---|---|---|---|
| Frontend Lead | frontend-developer | HTML, CSS, JS, lógica UI, scroller, badges | index.html (bloques 1 y 3) |
| Edge Functions | backend-developer | Supabase Edge Functions, Deno, API football-data.org | supabase/functions/sync-results/index.ts |
| Seguridad | security-auditor | Auth PIN RPC, RLS Supabase, credenciales | index.html (fetch interceptor), DB functions |
| QA | code-reviewer | Revisión antes de cierre, bugs, calidad | index.html |
| Design | ui-designer | Design system, tokens CSS, layout responsivo | index.html (sección :root) |
| Bugs | error-detective | Diagnóstico de errores, root cause, cascadas | Primer paso ante cualquier error |

## MCPs Activos para este proyecto

| MCP | Para qué | Estado |
|---|---|---|
| context7 | Docs Supabase, Deno Edge Functions, vanilla JS | Falta — agregar a .mcp.json |
| puppeteer | Verificación visual UI 375px/768px/1280px | Falta — agregar a .mcp.json |

## Output Contracts

| Agente productor | Produce | Lo consume |
|---|---|---|
| frontend-developer | index.html actualizado (bloque 3 plain-text) | code-reviewer |
| backend-developer | Edge Function Deno actualizada | frontend-developer (sincronizarResultados) |
| security-auditor | Reporte de riesgos + SQL de mitigación | frontend-developer, admin BD |
| ui-designer | Tokens CSS, specs visuales | frontend-developer |

## Definition of Done

- [ ] code-reviewer aprobó antes de cerrar
- [ ] Sin credenciales en plain text en archivos del repo (excl. .gitignore)
- [ ] Bloque JS ofuscado intacto — cambios solo en bloque 3
- [ ] Verificado en móvil 375px (proyecto mayormente móvil)
- [ ] Funcionalidad probada: login PIN + predicciones + ranking + sync

## Protocolo de Despacho

Proyecto single-file — casi todas las tareas son 1 dominio → Capa 1 directa.

| Tarea | Agente |
|-------|--------|
| UI / lógica JS / scroller / badges | `frontend-developer` |
| Edge Function / API football | `backend-developer` |
| Bug inesperado | `error-detective` PRIMERO |
| Cambio de auth / endpoints | `security-auditor` |
| Antes de cerrar cualquier tarea | `code-reviewer` |

## Regla crítica — bloque JS ofuscado
El bloque `<script>` #2 (líneas ~423-426) es ofuscado y contiene credenciales.
**NUNCA modificarlo.** Todos los overrides van en el bloque #3 (plain-text, línea 427+).
Patrón: definir función con el mismo nombre en bloque 3 → sobreescribe la del bloque 2.
