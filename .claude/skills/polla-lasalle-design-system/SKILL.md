---
name: polla-lasalle-design-system
description: "Design system de Polla Mundial 2026 LaSalle. Stack: Vanilla HTML + CSS custom properties. Usar cuando: construyas componentes, estilos o modifiques la UI de index.html. Define tokens reales extraídos del proyecto."
---

# Polla Mundial 2026 LaSalle — Design System

> Skill específico de este proyecto. Generado por /helix-analiza (2026-06-28).
> Stack: Vanilla HTML + CSS variables (custom properties) + JS puro. Sin framework UI.
> ⚠️ Todos los tokens están en la sección `:root` de index.html línea ~8-18.

## Stack UI
Vanilla HTML5 + CSS custom properties + JavaScript ES2020 (sin framework)

## Cuándo aplicar este skill
- Al construir cualquier sección, modal o componente nuevo en index.html
- Al revisar consistencia visual
- Al definir colores, spacing o tipografía
- Al agregar un nuevo tab o vista

---

## Tokens de Color (extraídos de :root en index.html)

```css
:root {
  --verde:        #006845;   /* Color primario — header, botones principales, títulos de sección */
  --verde-claro:  #e8f5f0;   /* Fondo de tags de éxito, alertas ok */
  --verde-mid:    #00a86b;   /* Confirmaciones temporales (botón guardado) */
  --dorado:       #C9A84C;   /* Empates, tags especiales */
  --dorado-claro: #fdf6e3;   /* Fondo de tags dorado */
  --rojo:         #c0392b;   /* Errores, botones destructivos */
  --rojo-claro:   #fdecea;   /* Fondo de errores inline */
  --gris-bg:      #f4f4f2;   /* Fondo de página */
  --gris-borde:   #e2e2de;   /* Bordes de cards y inputs */
  --gris-texto:   #777;      /* Labels, texto secundario */
  --texto:        #1a1a1a;   /* Texto principal */
  --blanco:       #ffffff;   /* Fondo de cards, modales */
  --radio:        10px;      /* Border-radius estándar de cards */
  --sombra:       0 1px 4px rgba(0,0,0,.08);  /* Sombra estándar de cards */
}
```

## Tipografía

| Uso | Fuente | Tamaño | Peso |
|---|---|---|---|
| Body principal | 'Segoe UI', system-ui, sans-serif | 13px | 400 |
| Labels uppercase | Hereda | 11px | 600 |
| Títulos de sección (.sec-titulo) | Hereda | 14px | 700 |
| H1 header | Hereda | 17px | 700 |
| Inputs móvil | Hereda | **≥16px** (evita zoom iOS) | 400 |

## Componentes del Proyecto

| Componente | Clase/ID | Cuándo usar | Variantes |
|---|---|---|---|
| Card sección | `.sec` | Agrupar contenido relacionado | — |
| Título de sección | `.sec-titulo` | Encabezado dentro de .sec | Con icono emoji |
| Botón primario | `.btn .btn-v` | Acción principal (verde) | `.btn-sm` (compacto) |
| Botón destructivo | `.btn .btn-r` | Eliminar, cancelar (rojo) | `.btn-sm` |
| Botón neutro | `.btn .btn-g` | Acciones secundarias (gris) | — |
| Campo de formulario | `.campo` | Input + label | Con label uppercase |
| Tag de estado | `.tag .tag-v` | Indicadores (verde) | `.tag-d` (dorado) |
| Alerta inline | `.alerta .al-ok` | Feedback sin alert() | — |
| Spinner loading | `.loading > .spinner` | Estados de carga | — |
| Tab de navegación | `.tab` | Navegación principal | `.active` |
| Modal overlay | Inline styles + display:flex | PIN, confirmaciones | — |
| Empty state | `.empty` | Listas vacías | — |

## Reglas de Este Proyecto

- **Mobile-first siempre** — el proyecto es mayormente móvil (partido en mano)
- **Touch targets ≥ 44×44px** — especialmente botones de partidos y predicciones
- **font-size ≥ 16px en inputs** — evita zoom iOS (score inputs usan 13px en desktop → verificar en móvil)
- **Nunca información solo por hover** — los participantes usan móvil
- **Feedback inline, nunca alert()** — ya corregido en commit 6df715b, mantener esta regla
- **sticky header + modo-bar** — respetar z-index 100/99 del header y barra de modo
- **max-width: 860px** en `.vista` — contenido centrado en desktop
- **Color semántico**: verde = éxito/ok, rojo = error/destructivo, dorado = empate/especial

## ❌ Anti-patrones Prohibidos

- No usar `alert()` ni `confirm()` del browser — usar `.alerta` inline
- No hardcodear colores hex — siempre `var(--token)`
- No agregar dependencias externas (CDN, npm) — el proyecto es zero-dependency
- No romper la estructura de single-file — todo en index.html
- No exponer credenciales en código no ofuscado

## Estructura de Vistas

```
header (sticky, z-index:100) — tabs de navegación
modo-bar (sticky, z-index:99) — selector Grupos / Eliminatorias
.vista#vista-partidos       — lista de partidos
.vista#vista-predicciones   — predicciones del usuario
.vista#vista-ranking        — tabla de ranking
.vista#vista-reglas         — sistema de puntos
.vista#vista-admin          — panel administrador
```

## Recursos

- Design system global: `~/.claude/memory/design-system.md`
- Skill global de diseño: `frontend-design` (estilos generales, paletas)
- Para animaciones: `motion-designer` agent
