# Helix Analysis — Polla Mundial 2026 LaSalle
> Actualizado: 2026-06-29 | Modo: file | Actualizar con: /helix-actualiza
> ⚠️ Si este archivo tiene >30 días, ejecutar /helix-actualiza

## Resumen ejecutivo
Quiniela online para el Mundial 2026 (grupo LaSalle). Single HTML file (~955 líneas) con vanilla JS/CSS y Supabase como backend. Auth por PIN server-side via RPC (`verify_pin`, `verify_admin_pin`). Admin PIN almacenado en tabla `configuracion`. Integración con football-data.org via Supabase Edge Function (Deno). Auto-sync cada 2 min cuando hay partidos `en_curso`. Tres mejoras UX activas: badge EN VIVO flotante, toast de resultados, cuenta regresiva, scroller HOY. `polla-mundial copy.html` sigue con credenciales en plain text — riesgo latente pero en `.gitignore`.

## Stack (resumen)
Backend: Supabase (PostgreSQL REST API + RPC + Edge Functions Deno) | Frontend: Vanilla HTML + CSS custom properties + JS ES2020 | DB: PostgreSQL (Supabase) | Auth: PIN 4 dígitos via RPC server-side | Infra: GitHub Pages (static)

## Agentes prioritarios para este proyecto
- `frontend-developer` → cambios de UI, componentes, lógica JS en index.html
- `security-auditor` → revisión auth, RLS Supabase, exposure de credenciales
- `code-reviewer` → SIEMPRE antes de declarar tarea completa
- `error-detective` → ante cualquier bug inesperado (primer paso)

## Skills críticas
- `polla-lasalle-design-system` → disponible en `.claude/skills/`
- `frontend-design` → global, disponible

## MCPs recomendados
- `context7` → Supabase docs, Deno Edge Functions — falta en .mcp.json
- `puppeteer` → verificación visual UI 375px/768px/1280px — falta en .mcp.json

## Zonas de riesgo actualizadas
- `polla-mundial copy.html` → ALTO → credenciales Supabase + ADMIN_PIN en plain text (mitigado: .gitignore)
- Bloque JS ofuscado → MEDIO → no tocar jamás; usar solo override en bloque 3
- `sincronizarResultados()` → MEDIO → llama Edge Function con service key client-side
- `estado` en DB → BAJO → mezcla valores API ('SCHEDULED') y valores internos ('pendiente') — normalizar en Edge Function pendiente
- Auto-sync IIFE → BAJO → setInterval sin cleanup, memory leak si se recarga sin cerrar
