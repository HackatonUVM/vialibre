# VíaLibre

> **Reto 2 — Ciudad para todas y todos** · Alineado a **ODS 10** (Meta 10.2) y **ODS 11** (Metas 11.2 y 11.7).

Aplicación móvil para **Android (Flutter)** enfocada en navegación peatonal accesible, reporte ciudadano de barreras urbanas mediante fotografía o nota de voz, y traducción de avisos públicos a **Lenguaje Claro** y audio con **Google Gemini**.

---

## Flujos principales del MVP

1. **Búsqueda y ruta peatonal accesible por perfil**: Selección de perfil (silla de ruedas / carriola, baja visión o lectura clara), rutas peatonales considerando pendientes y obstáculos reportados, y lectura por voz.
2. **Reporte ciudadano en un toque**: Captura de foto (con limpieza de metadatos EXIF y compresión en el dispositivo) o nota de voz breve; clasificación compatible con Open311 / `a11yjson.org` y deduplicación espacial + vectorial en un radio de 25 metros.
3. **Traductor de avisos públicos a Lenguaje Claro**: Carga de PDF o foto de comunicados municipales para generar un resumen en tres bloques (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) y reproducción en audio WAV en español.

## Arquitectura y estructura del repositorio

```text
vialibre/
├── docs/          # Propuesta Reto 2 y Documentación Técnica / Boceto (Fase 2)
├── mobile/        # Cliente móvil Flutter (Dart, Android minSdk 24+)
├── bff/           # Backend for Frontend en Next.js App Router (TypeScript + Zod) para Vercel
├── supabase/      # Esquema SQL, migraciones (PostGIS + pgvector), RPCs y políticas RLS
└── .github/       # Plantillas de Issues y Pull Requests
```

### Stack técnico

| Capa | Tecnología | Rol |
| --- | --- | --- |
| **Cliente móvil** | Flutter (Dart, Android `minSdk 24+`) | Interfaz nativa accesible (`Semantics` / TalkBack), `google_maps_flutter`, cámara, audio y cola offline (`sqflite`) |
| **Backend (BFF)** | Next.js App Router (TypeScript + Zod) en Vercel | API REST segura (`app/api/...`) con validación Bearer JWT, `@google/genai` y Google Maps Platform |
| **Base de datos y Storage** | Supabase (PostgreSQL + PostGIS + `pgvector`) | Persistencia geoespacial (`GiST`), similitud vectorial (`HNSW`), deduplicación RPC, RLS y Auth anónimo |
| **IA Generativa** | Google Gen AI SDK (`@google/genai`) | Visión de obstáculos, clasificación, embeddings multimodales, Lenguaje Claro y TTS |
| **Mapas y rutas** | Google Maps Platform | Maps SDK for Android, Routes API, Places API (New) y Elevation API |

## Estándares abiertos y accesibilidad

- **Accesibilidad móvil y lectura**: WCAG 2.2 nivel AA, EN 301 549, W3C COGA e ISO 24495-1 (Lenguaje Claro).
- **Datos cívicos y geoespaciales**: Open311 (GeoReport v2), OpenStreetMap (`wheelchair`, `tactile_paving`, `kerb`, `incline`), `a11yjson.org` y GTFS-Pathways.
- **Privacidad desde el diseño**: Uso sin cuenta obligatoria (sesión anónima), eliminación de metadatos EXIF antes de subir imágenes y expiración temporal de obstáculos pasajeros.

## Documentación

- [Propuesta Reto 2 - VíaLibre (Ciudad para todas y todos - ODS 11)](docs/Propuesta%20Reto%202%20-%20V%C3%ADaLibre%20(Ciudad%20para%20todas%20y%20todos%20-%20ODS%2011).pdf)

## Equipo

- **Julio Abraham Miguel Pedro**
- **Jose Pablo Ferrari Martinez**
- **Sebastian Rosales Ocampo**

## Licencia

Este proyecto se distribuye bajo la licencia [MIT](LICENSE).
