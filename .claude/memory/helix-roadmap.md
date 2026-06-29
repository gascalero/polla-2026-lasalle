# Helix Roadmap — Polla Mundial 2026 LaSalle
> Actualizado: 2026-06-29 por /helix-analiza | Actualizar: manualmente o con /helix-actualiza
> ⚠️ Este archivo NO se borra automáticamente. Es el mapa de ruta del equipo técnico.

## 🎯 Visión del Proyecto
Quiniela online para el grupo LaSalle del Mundial 2026. Participantes predicen resultados de la fase eliminatoria, ven ranking en tiempo real y compiten por puntos. Organizador administra partidos y resultados. Deploy: GitHub Pages (static).

## ✅ Completado
| Milestone | Descripción | Fecha |
|-----------|-------------|-------|
| MVP Inicial | HTML + Supabase conectado, partidos y predicciones fase grupos | Pre 2026-06-28 |
| Auth por PIN | Login por participante + cambio de PIN propio | 2026-06-28 |
| Predicciones eliminatorias | Goles + penaltis con ganador en fase KO | 2026-06-28 |
| Sistema de puntos | Reglas completas con pestaña explicativa | 2026-06-28 |
| Mejoras UX v1 | Feedback inline, hint penaltis, ranking limpio | 2026-06-28 |
| Seguridad PIN | verify_pin y verify_admin_pin via RPC server-side; admin PIN en DB | 2026-06-28 |
| Integración API | football-data.org via Edge Function Deno con auto-sync | 2026-06-28 |
| Mejoras EN VIVO | Badge flotante, toast resultados, cuenta regresiva | 2026-06-29 |
| Scroller HOY | Strip horizontal con partidos del día, hora en zona local | 2026-06-29 |

## 🔵 En Progreso
| Milestone | Descripción | Inicio | Avance |
|-----------|-------------|--------|--------|

## 🟡 Próximos Milestones
| Milestone | Descripción | Prioridad | Notas |
|-----------|-------------|-----------|-------|
| Normalización estados | Unificar 'SCHEDULED'/'pendiente' en Edge Function | Media | Afecta badge, countdown, renderizado |
| Cuartos de final | Asegurar que el flujo funciona cuando avance la competición | Alta | Verificar auto-creación de partidos en Edge Function |

## 🗺️ Arquitectura de Alto Nivel
```
Browser (GitHub Pages)
  └── index.html (~955 líneas)
        ├── <script> 1: fetch interceptor (strip PIN de responses)
        ├── <script> 2: JS ofuscado (credentials, ADMIN_PIN, core logic)
        └── <script> 3: plain-text overrides + mejoras
              ├── sbRpc() — llama Supabase RPC
              ├── verificarPin() — override server-side
              ├── checkPin() — override admin PIN server-side
              ├── sincronizarResultados() — llama Edge Function
              ├── mostrarToast() / actualizarEnVivo() / actualizarCuentaRegresiva()
              └── renderScrollerHoy() — scroller HOY

Supabase (PostgreSQL)
  ├── participantes (id, nombre, pin)
  ├── partidos_elim (id, local, visita, fecha, hora_inicio, estado, goles, penaltis...)
  ├── predicciones_elim (participante_id, partido_id, goles, pred_penaltis, pred_ganador_pen)
  └── configuracion (clave='admin_pin', valor=hashed)

Supabase Edge Function (Deno)
  └── sync-results → football-data.org API → UPDATE partidos_elim
```

## 📌 Decisiones Arquitectónicas
| Fecha | Decisión | Alternativa rechazada | Por qué |
|-------|----------|-----------------------|---------|
| 2026-06-28 | Single HTML file | React + Vite / Next.js | Cero build system, velocidad de iteración máxima |
| 2026-06-28 | Supabase backend | Firebase / servidor propio | Tier free, PostgreSQL real, REST + RPC + Edge Functions |
| 2026-06-28 | Override pattern para seguridad | Modificar bloque ofuscado | Preservar ofuscación de credentials intacta |
| 2026-06-28 | PIN server-side via RPC | JWT / sesión server-side | Simplicidad para grupo privado pequeño |
| 2026-06-29 | Hora en zona local del usuario | Forzar UTC-5 Colombia | Hay participantes fuera de Colombia |

## 🔴 Riesgos Conocidos
| Área | Riesgo | Mitigación | Estado |
|------|--------|------------|--------|
| Credentials | `polla-mundial copy.html` expone URL + KEY en plain text | .gitignore activo | Pendiente eliminar |
| Estado DB | Mezcla 'SCHEDULED' (API) y 'pendiente' (interno) | Normalización en Edge Function | Pendiente |
| Auth | PINs de participantes llegan al browser (RLS no aplicado) | Aceptado — grupo privado | Abierto |
| Ofuscación | Si se extrae bloque 2, credentials quedan expuestas | Rotar keys si hay breach | Activo |

## 📋 Notas del Equipo
- Organizador: Gabriel (coordmejoracontinua@pharmaser.com.co)
- Los 16avos de final arrancaron el 2026-06-29
- Deploy automático: push a main → GitHub Pages (1-2 min)
- Nunca tocar el bloque `<script>` #2 (ofuscado) — solo agregar en bloque #3
