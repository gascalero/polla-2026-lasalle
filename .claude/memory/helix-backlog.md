# Helix Backlog — Polla Mundial 2026 LaSalle
> Iniciado: 2026-06-28 | Helix actualiza automáticamente al completar requerimientos.

## 🔵 En Progreso
| ID | Requerimiento | Agentes | Inicio |
|----|--------------|---------|--------|

## 🟡 Pendiente
| ID | Requerimiento | Prioridad | Notas |
|----|--------------|-----------|-------|
| B-001 | Eliminar o proteger `polla-mundial copy.html` | Alta | Credenciales en plain text — en .gitignore pero existe en disco |
| B-006 | Normalizar campo `estado` en Edge Function | Media | DB mezcla 'SCHEDULED'/'FINISHED' (API) con 'pendiente'/'finalizado' (interno) — el scroller ya lo maneja pero el resto del app no |

## 🟢 Completado
| ID | Requerimiento | Fecha | Resultado |
|----|--------------|-------|-----------|
| B-007 | Scroller horizontal partidos del día | 2026-06-29 | Strip HOY con cards 180px, filtro UTC→local, scroll snap |
| B-003 | Badge EN VIVO flotante | 2026-06-29 | Pill roja pulsante en bottom-right, click va a Partidos |
| B-004 | Toast de resultados en sync | 2026-06-29 | Notificación verde cuando auto-sync actualiza ≥1 resultado |
| B-005 | Cuenta regresiva cierre predicciones | 2026-06-29 | Barra amarilla sticky <2h antes de partido |
| B-002 | PIN verificado server-side (Supabase RPC) | 2026-06-28 | fetch interceptor + sbRpc + verify_pin() en PostgreSQL |
| — | Auto-sync cada 2 min partidos en curso | 2026-06-28 | setInterval polling + sincronizarResultados() |
| — | Integración football-data.org (Edge Function) | 2026-06-28 | Deno function sync-results con TEAM_MAP + STATUS_MAP |
| — | Fix PIN admin input + feedback inline | 2026-06-28 | commit 6df715b |
| — | Agregar pestaña Reglas con sistema de puntos | 2026-06-28 | commit 920e528 |
| — | Eliminar sección 'Detalle por participante' del ranking | 2026-06-28 | commit a72b0fa |
| — | Opción para cambiar PIN propio | 2026-06-28 | commit 20e2386 |
| — | Autenticación por PIN de 4 dígitos | 2026-06-28 | commit 29adfdf |

## 🔴 Bloqueado
| ID | Requerimiento | Bloqueado por | Desde |
|----|--------------|---------------|-------|
