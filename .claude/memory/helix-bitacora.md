# Helix Bitácora — Polla Mundial 2026 LaSalle
> Iniciada: 2026-06-28
> Propósito: Registro continuo. Helix actualiza automáticamente tras cambios significativos.

## 📝 Cambios Realizados
| Fecha | Archivo(s) | Cambio | Sesión |
|-------|-----------|--------|--------|
| 2026-06-28 | .claude/memory/* | Inicialización Helix — análisis inicial del proyecto | /helix-analiza |

## 💡 Recomendaciones
| Fecha | Recomendación | Estado |
|-------|--------------|--------|
| 2026-06-28 | Eliminar o git-ignorar `polla-mundial copy.html` — expone credenciales Supabase en plain text | Pendiente |
| 2026-06-28 | Evaluar Supabase RLS para que el servidor valide PINs, no el browser | Pendiente |

## 🐛 Errores Cometidos
| Fecha | Error | Solución | Aprendizaje |
|-------|-------|----------|-------------|

## 🧠 Decisiones de Diseño Validadas
| Fecha | Decisión | Por qué |
|-------|---------|---------|
| 2026-06-28 | Arquitectura single-file (index.html) | Proyecto personal/grupal sin infraestructura de build — simplicidad máxima |
| 2026-06-28 | Supabase como backend | Evita servidor propio; provee DB + REST + auth gratuito en tier free |
| 2026-06-28 | JS ofuscado en producción | Protege credenciales y ADMIN_PIN del inspector de elementos casual |
