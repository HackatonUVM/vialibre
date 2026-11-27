# VíaLibre

> **Reto 2 — Ciudad para todas y todos** · Alineado a **ODS 10** (Meta 10.2) y **ODS 11** (Metas 11.2 y 11.7).

Aplicación móvil para **Android (Flutter)** enfocada en navegación peatonal y en transporte público accesible, reporte ciudadano de barreras urbanas mediante fotografía o nota de voz, evaluación visual de accesibilidad arquitectónica y traducción de avisos públicos a **Lenguaje Claro** y audio con **Google Gemini**.

---

## Acceso y Despliegue en Vivo

- **Descarga directa Android (APK):** [Descargar `app-release.apk` (`v1.0.0-mvp`)](https://github.com/HackatonUVM/vialibre/releases/download/v1.0.0-mvp/app-release.apk)
- **App Web Móvil (PWA para iPhone y Android):** https://bff-steel.vercel.app/app *(en iOS Safari: Compartir > Agregar a pantalla de inicio)*
- **Backend BFF (Next.js en Vercel):** https://bff-steel.vercel.app
- **GitHub Releases:** [Ver Release `v1.0.0-mvp`](https://github.com/HackatonUVM/vialibre/releases/tag/v1.0.0-mvp)

---

## Flujos principales del MVP

1. **Búsqueda y ruta multimodal accesible por perfil**: Selección de perfil (*Silla de ruedas / Carriola*, *Baja visión*, *Lectura clara*), rutas peatonales y en transporte público (`WALK` y `TRANSIT`) cruzadas con barreras activas en PostGIS, guía paso a paso **"Primera vez en transporte público"** y lectura por voz (`flutter_tts` / audio).
2. **Reporte ciudadano en un toque con cola offline**: Captura de fotografía (limpieza de metadatos EXIF y compresión `< 1.5 MB` en el dispositivo mediante `flutter_image_compress`) o nota de voz breve (`record`); análisis visual con recuadros (*bounding boxes*) en Gemini, clasificación compatible con Open311 / `a11yjson.org`, deduplicación espacial + vectorial (`768` dimensiones) en un radio de 25 metros, validación comunitaria de resolución y cola offline local en SQLite (`sqflite`) con sincronización automática al recuperar red.
3. **Copiloto IA y Evaluador Visual ("¿Puedo entrar aquí?")**: Asistente conversacional adaptado al perfil de accesibilidad para resolver dudas de movilidad y transporte, junto con análisis fotográfico de entradas, rampas y accesos (`accessible`, `caution`, `inaccessible`).
4. **Traductor de avisos públicos a Lenguaje Claro**: Carga de comunicados municipales (imagen, PDF o texto) para resumirlos en tres bloques accionables (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) bajo lineamientos **ISO 24495-1** con reproducción en audio.

---

## Sistema de Diseño y Paleta de Colores ("Calma Urbana")

La interfaz evolucionó del esquema inicial oscuro de los bocetos (`#0A192F` / `#FFB300`) al sistema adaptativo **"Calma Urbana"** (`mobile/lib/app/theme/vialibre_theme.dart`), diseñado bajo **WCAG 2.2 AA** y **W3C COGA** para uso real en la vía pública:

| Token | Modo Claro | Modo Oscuro | Rol y justificación de accesibilidad |
| :--- | :--- | :--- | :--- |
| `canvas` / `card` | `#FAF8F5` / `#FFFFFF` | `#141416` / `#1D1D1F` | Fondo marfil cálido que evita reflejos y fatiga visual en exteriores bajo luz solar, y superficie oscura confortable de noche. |
| `ink` / `muted` | `#18181B` / `#52525B` | `#FAF8F5` / `#B8B8C4` | Alto contraste tipográfico sobre superficies claras y oscuras. |
| `coral` / `ctaBg` | `#C83E4D` / `#18181B` | `#EF4756` / `#FAF8F5` | Acento activo y botones principales claramente distinguibles de las alertas de peligro vial. |
| `mintSoft` / `mintInk` | `#DCFCE7` / `#166534` | `#163525` / `#86EFAC` | Indica rutas o accesos libres/verificados sin depender solo del color (acompañado de íconos y etiquetas). |
| `amberSoft` / `amberInk` | `#FEF3C7` / `#92400E` | `#3B2D14` / `#FDE68A` | Reserva el ámbar exclusivamente para advertencias de precaución y pendientes moderadas. |
| `alertRedSoft` / `alertRed` | `#FEE2E2` / `#B91C1C` | `#421C20` / `#FCA5A5` | Señaliza barreras críticas u obstáculos bloqueantes. |
| `lavender` / `lavenderInk` | `#E6E6FA` / `#3730A3` | `#292A44` / `#DCE0FF` | Etiquetas informativas y guías de apoyo (*Lectura clara* / *Primera vez*). |

- **Modo Alto Contraste (`highContrast`)**: configurable desde *Perfil* para baja visión; lleva el fondo a `#FFFFFF` o `#000000` puros, reemplaza textos atenuados por `ink` y aumenta los bordes a `2.0 px`.
- **Ícono adaptativo Android**: alineado en `values/colors.xml` (`#F9F5EE`) y `values-night/colors.xml` (`#1D1D1F`).

---

## Arquitectura y estructura del repositorio

```text
vialibre/
├── .github/
│   ├── ISSUE_TEMPLATE/        # Plantillas de Issues
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       └── build-apk.yml      # CI/CD: compila APK Release y actualiza el binario en v1.0.0-mvp
├── docs/
│   ├── BACKEND_SPEC.md        # Contrato completo de API, RPCs y reglas de seguridad BFF ↔ Supabase
│   ├── Propuesta Reto 2 - VíaLibre (Ciudad para todas y todos - ODS 11).pdf
│   └── bocetos/               # Sistema de diseño, pantallas Stitch y documentación de diseño
├── mobile/                    # Cliente móvil Flutter (Dart, Android minSdk 24+, Riverpod + GoRouter)
├── bff/                       # Backend for Frontend en Next.js App Router (TypeScript) + PWA (/app)
└── supabase/                  # Migraciones SQL (PostGIS + pgvector), RLS, Storage y RPCs
```

### Stack técnico

| Capa | Tecnología | Rol |
| --- | --- | --- |
| **Cliente móvil** | Flutter (Dart `>=3.5.0 <4.0.0`, Android `minSdk 24+`) | Arquitectura modular por *features* (`explore`, `map_routes`, `report_barrier`, `public_briefs`, `gemini_assistant`, `profile`), `flutter_riverpod`, `go_router`, `google_maps_flutter`, `Semantics` / TalkBack, `flutter_image_compress`, `record`, `audioplayers`, `flutter_tts` y cola offline (`sqflite` + `connectivity_plus`) |
| **Backend (BFF) y PWA** | Next.js `^15.1.7` App Router (`TypeScript`, `zod ^3.24.2`) en Vercel | API REST en `bff/src/app/api/` (16 rutas) que protege llaves de Google/Supabase, además de PWA móvil en `bff/src/app/app/page.tsx` |
| **Base de datos, Auth y Storage** | Supabase (`@supabase/supabase-js ^2.49.1`, `supabase_flutter ^2.8.0`) | PostgreSQL + PostGIS (`GiST`) + `pgvector` (`HNSW` 768d), deduplicación atómica por RPC, Realtime en `public.barriers`, buckets privados (`barrier-evidence`, `public-briefs`) y Auth anónimo (`signInAnonymously`) |
| **IA Generativa** | Google Gen AI SDK (`@google/genai ^3.6.1`) | Visión de obstáculos (`bounding_boxes`), clasificación Open311, evaluador visual de entradas, Copiloto accesible, embeddings de 768 dimensiones y resúmenes en Lenguaje Claro |
| **Mapas y rutas** | Google Maps Platform | Maps SDK for Android, Routes API, Places API (New) y Elevation API |

---

## Backend BFF (`bff/`) y Base de Datos (`supabase/`)

> Consulta el detalle de configuración en [`bff/README.md`](bff/README.md), [`supabase/README.md`](supabase/README.md) y la especificación de contrato completa en [`docs/BACKEND_SPEC.md`](docs/BACKEND_SPEC.md).

### Rutas activas en `bff/src/app/api/`

| Método y ruta | Propósito |
| :--- | :--- |
| `GET /api/health` | Verificación de estado del servicio (`vialibre-bff`). |
| `GET` / `PUT` / `DELETE /api/profile/me` | Lectura, actualización y restablecimiento de preferencias de accesibilidad del usuario. |
| `POST /api/routes/accessible` | Cálculo de rutas peatonales y de transporte público cruzadas con barreras activas y guía paso a paso para primera vez. |
| `POST /api/places/nearby` | Búsqueda de lugares cercanos con opciones de accesibilidad (`Places API New`) y barreras próximas. |
| `POST /api/places/assess-photo` | Evaluador visual *"¿Puedo entrar aquí?"* sobre fotos sin metadatos EXIF para determinar si un acceso es libre, con precaución o inaccesible. |
| `POST /api/assistant/chat` | Copiloto conversacional de accesibilidad con acciones sugeridas hacia el mapa, guía, reporte o avisos. |
| `POST /api/barriers/upload-url` | Generación de *Signed Upload URL* hacia el bucket privado `barrier-evidence`. |
| `POST /api/barriers/analyze` | Análisis preliminar de foto/nota con Gemini (categoría Open311, severidad, *bounding boxes* y dependencia canalizadora). |
| `POST /api/barriers/report` | Registro o confirmación ciudadana de barreras con soporte de *idempotencyKey* y deduplicación espacial/vectorial vía RPC. |
| `POST /api/barriers/resolve` | Voto ciudadano de despeje o reparación (`record_barrier_resolution`). |
| `GET /api/barriers/nearby` | Consulta de barreras activas por radio geográfico (`find_nearby_barriers`). |
| `GET /api/barriers/mine` | Historial de barreras reportadas por el usuario autenticado. |
| `GET /api/barriers/[id]` | Consulta de detalle de una barrera específica. |
| `POST /api/briefs/upload-url` | Generación de *Signed Upload URL* hacia el bucket privado `public-briefs`. |
| `POST /api/briefs/simplify` | Traducción de avisos públicos a 3 bloques en Lenguaje Claro (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*). |
| `POST /api/notices/simplify` y `POST /api/storage/signed-url` | Rutas heredadas mantenidas por compatibilidad con el cliente PWA inicial. |

### Migraciones de base de datos (`supabase/migrations/`)

1. `20261126203359_extensions_and_schema_setup.sql` — Esquema aislado `extensions` (`postgis`, `vector`).
2. `20261126203740_core_tables_and_indexes.sql` — Tablas principales (`barriers`, `barrier_events`, `public_briefs`, `rate_limit_events`) e índices `GiST`, `HNSW` (`vector_cosine_ops`) y `GIN`.
3. `20261126203742_rls_storage_and_rpcs.sql` — Políticas RLS, buckets privados (`barrier-evidence`, `public-briefs`) y funciones RPC (`check_and_record_rate_limit`, `upsert_or_confirm_barrier`, `record_barrier_resolution`, `find_barriers_along_route`, `find_nearby_barriers`).
4. `20261126203947_optimize_rls_policies.sql` — Consolidación de políticas `SELECT` y protección de `rls_auto_enable()`.
5. `20261126210000_enable_realtime_barriers.sql` — Publicación de `public.barriers` en `supabase_realtime` para actualización en vivo en el mapa.

---

## Ejecución y verificación local

### Backend (`bff/`)

```bash
cd bff
cp .env.example .env.local   # Completar llaves reales (nunca subir a Git)
npm install
npm run lint
npm run build
npm run dev                  # Inicia en http://localhost:3000
```

### App móvil (`mobile/`)

```bash
cd mobile
cp .env.example .env.json    # Completar SUPABASE_ANON_KEY y GOOGLE_MAPS_MAP_ID
flutter pub get
flutter analyze --no-pub
flutter run --dart-define-from-file=.env.json
```

> **Compilación CI/CD:** Cada `push` a `main` que modifique `mobile/**` o `.github/workflows/build-apk.yml` ejecuta el workflow **Compilar APK Android (VíaLibre)** con `--dart-define=BFF_BASE_URL=https://bff-steel.vercel.app` y actualiza el APK del Release `v1.0.0-mvp`.

---

## Estándares abiertos y accesibilidad

- **Accesibilidad móvil y lectura**: WCAG 2.2 nivel AA, EN 301 549, W3C COGA e ISO 24495-1 (Lenguaje Claro).
- **Datos cívicos y geoespaciales**: Open311 (GeoReport v2), OpenStreetMap (`wheelchair`, `tactile_paving`, `kerb`, `incline`), `a11yjson.org` y GTFS-Pathways.
- **Privacidad desde el diseño**: Uso sin registro obligatorio (sesión anónima), eliminación de metadatos EXIF antes de subir fotografías, expiración temporal de obstáculos pasajeros y exclusión de llaves/secretos en el repositorio (`.gitignore`).

## Documentación

- [Propuesta Reto 2 - VíaLibre (Ciudad para todas y todos - ODS 11)](docs/Propuesta%20Reto%202%20-%20V%C3%ADaLibre%20(Ciudad%20para%20todas%20y%20todos%20-%20ODS%2011).pdf)
- [Bocetos y sistema de diseño de la app](docs/bocetos/README.md)
- [Especificación técnica de Backend (`docs/BACKEND_SPEC.md`)](docs/BACKEND_SPEC.md)
- [Detalle del servidor (`bff/README.md`)](bff/README.md) · [Detalle de base de datos (`supabase/README.md`)](supabase/README.md)

## Equipo — Grupo Xiuh

- **Julio Abraham Miguel Pedro**
- **Jose Pablo Ferrari Martinez**
- **Sebastian Rosales Ocampo**

## Licencia

Este proyecto se distribuye bajo la licencia [MIT](LICENSE).
