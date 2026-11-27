# VíaLibre

> **Reto 2 — Ciudad para todas y todos** · Alineado a **ODS 10** (Meta 10.2) y **ODS 11** (Metas 11.2 y 11.7) · **Grupo Xiuh (UVM Campus Lomas Verdes)**.

Plataforma móvil para **Android (Flutter)** y **Web Móvil (PWA)** enfocada en navegación peatonal y en transporte público accesible, reporte ciudadano de barreras urbanas mediante fotografía o nota de voz, evaluación visual de accesibilidad arquitectónica y traducción de avisos públicos a **Lenguaje Claro (ISO 24495-1)** y audio con **Google Gemini**.

---

## Acceso y Despliegue en Vivo

- **Descarga directa Android (APK):** [Descargar `app-release.apk` (`v1.0.0-mvp`)](https://github.com/HackatonUVM/vialibre/releases/download/v1.0.0-mvp/app-release.apk)
- **App Web Móvil (PWA para iPhone y Android):** https://bff-steel.vercel.app/app *(en iOS Safari: Compartir > Agregar a pantalla de inicio)*
- **Backend BFF (Next.js en Vercel):** https://bff-steel.vercel.app
- **GitHub Releases:** [Ver Release `v1.0.0-mvp`](https://github.com/HackatonUVM/vialibre/releases/tag/v1.0.0-mvp)
- **Boceto Visual (Google Stitch):** https://stitch.google.com/projects/11135309563401328808
- **Ficha Técnica Integral (Google Docs — Grupo XIUH):** [Ver documento en Google Docs](https://docs.google.com/document/d/1eiAh3THeHomo15f_WfTTain3cQTX7IAQNAMgh8iY8Zs/edit)

---

## Flujos principales del MVP

1. **Búsqueda y ruta multimodal accesible por perfil**: Selección persistente de perfil (*Silla de ruedas / Carriola*, *Baja visión*, *Lectura clara*) sin registro obligatorio (`signInAnonymously`); rutas peatonales y en transporte público (`WALK` y `TRANSIT`) calculadas con **Google Routes API v2** y **Places API (New)**, cruzadas en tiempo real con barreras activas en **PostGIS** (`ST_DWithin` en 25 m) y análisis de pendientes topográficas (**Elevation API**), guía paso a paso **"Primera vez en transporte público"** con *grounding* estricto y lectura por voz (`flutter_tts` / audio WAV).
2. **Reporte ciudadano en un toque con cola offline**: Captura de fotografía (con limpieza automática de metadatos EXIF mediante `flutter_image_compress` `keepExif: false` y compresión `< 1.45 MB` en el teléfono) o nota de voz breve (`.m4a` descartada inmediatamente de memoria tras transcribirse); análisis visual con *bounding boxes* (`0..1000`) en **Google Gemini**, clasificación compatible con **Open311** / `a11yjson.org`, deduplicación atómica espacial + vectorial (`768` dimensiones, similitud coseno `>= 0.85`) en un radio de **25 metros**, votación comunitaria de despeje/reparación (`record_barrier_resolution`) y cola offline en SQLite (`sqflite` con `idempotency_key` UUIDv4) sincronizada automáticamente al recuperar conectividad.
3. **Copiloto IA y Evaluador Visual ("¿Puedo entrar aquí?")**: Asistente conversacional adaptado al perfil de accesibilidad para resolver dudas de movilidad y transporte urbano con acciones directas hacia mapa, guía o reporte, junto con evaluación fotográfica de entradas, puertas y rampas (`accessible`, `caution`, `inaccessible`).
4. **Traductor de avisos públicos a Lenguaje Claro y audio**: Carga de comunicados municipales (PDF `<= 10 MB` mediante *Signed Upload URL*, fotografía o texto) para resumirlos con *grounding* estricto en tres bloques accionables (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) bajo lineamientos **ISO 24495-1** y **W3C COGA**, con caché criptográfico por `doc_sha256` y reproducción en audio.

---

## Sistema de Diseño y Paleta de Colores ("Calma Urbana")

La interfaz evolucionó del esquema inicial de los bocetos en Google Stitch (`#0A192F` / `#FFB300`) al sistema adaptativo **"Calma Urbana"** (`mobile/lib/app/theme/vialibre_theme.dart`), diseñado bajo **WCAG 2.2 AA**, **EN 301 549** y **W3C COGA** para uso real en la vía pública:

| Token | Modo Claro | Modo Oscuro | Rol y justificación de accesibilidad |
| :--- | :--- | :--- | :--- |
| `canvas` / `card` | `#FAF8F5` / `#FFFFFF` | `#141416` / `#1D1D1F` | Fondo marfil cálido antirreflejo bajo luz solar en exteriores, y superficie oscura confortable de noche. |
| `ink` / `muted` | `#18181B` / `#52525B` | `#FAF8F5` / `#B8B8C4` | Contraste tipográfico `>= 4.5:1` sobre superficies claras y oscuras. |
| `coral` / `ctaBg` | `#C83E4D` / `#18181B` | `#EF4756` / `#FAF8F5` | Acento activo y botones principales (mínimo `48x52 dp` / `48x48 dp`) claramente distinguibles de las alertas viales. |
| `mintSoft` / `mintInk` | `#DCFCE7` / `#166534` | `#163525` / `#86EFAC` | Indica rutas o accesos libres/verificados sin depender solo del color (acompañado de íconos y etiquetas). |
| `amberSoft` / `amberInk` | `#FEF3C7` / `#92400E` | `#3B2D14` / `#FDE68A` | Reserva el ámbar exclusivamente para advertencias de precaución y pendientes moderadas. |
| `alertRedSoft` / `alertRed` | `#FEE2E2` / `#B91C1C` | `#421C20` / `#FCA5A5` | Señaliza barreras críticas u obstáculos bloqueantes. |
| `lavender` / `lavenderInk` | `#E6E6FA` / `#3730A3` | `#292A44` / `#DCE0FF` | Etiquetas informativas y guías cognitivas de apoyo (*Lectura clara* / *Primera vez*). |

- **Modo Alto Contraste (`highContrast`) y Texto Grande**: activado automáticamente al seleccionar *Baja visión*; lleva los fondos a `#FFFFFF` o `#000000` puros, elimina texto atenuado y aumenta bordes a `2.0 px`, además de soportar escalado de texto (`1.2x`).
- **Accesibilidad nativa y movimiento reducido**: etiquetas `Semantics` para TalkBack sin abreviaturas ni flechas, retroalimentación háptica (`HapticFeedback.selectionClick`), marcadores por forma geométrica + color (`assets/markers/`) y supresión automática de transiciones (`_NoTransitionsBuilder`) cuando `MediaQuery.disableAnimationsOf(context)` está activo.
- **Ícono adaptativo Android**: alineado en `values/colors.xml` (`#F9F5EE`) y `values-night/colors.xml` (`#1D1D1F`).

---

## Arquitectura y estructura del repositorio

```text
vialibre/
├── .github/
│   ├── ISSUE_TEMPLATE/        # Plantillas de Issues (bug_report, feature_request)
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       └── build-apk.yml      # CI/CD: compila APK Release (Flutter 3.29.0 + Java 17) y actualiza v1.0.0-mvp
├── docs/
│   ├── VíaLibre — Ficha Técnica y Documentación Integral (Grupo XIUH).pdf  # Ficha técnica completa (membretada XIUH)
│   ├── VíaLibre - Documentación Técnica Integral.pdf                        # Auditoría técnica del repositorio
│   ├── BACKEND_SPEC.md        # Contrato completo de API, RPCs y reglas de seguridad BFF ↔ Supabase
│   ├── Propuesta Reto 2 - VíaLibre (Ciudad para todas y todos - ODS 11).pdf
│   └── bocetos/               # Sistema de diseño, pantallas Google Stitch y logotipo
├── mobile/                    # Cliente móvil Flutter (Dart, Android minSdk 24+, compileSdk 36, Riverpod + GoRouter)
├── bff/                       # Backend for Frontend en Next.js App Router (TypeScript + Zod) + PWA (/app)
└── supabase/                  # Migraciones SQL (PostGIS + pgvector), RLS, Storage y RPCs
```

### Stack técnico

| Capa | Tecnología | Rol |
| --- | --- | --- |
| **Cliente móvil** | Flutter (Dart `>=3.5.0 <4.0.0`, Android `minSdk 24+`) | Arquitectura modular por *features* (`explore`, `map_routes`, `report_barrier`, `public_briefs`, `gemini_assistant`, `profile`), `flutter_riverpod`, `go_router`, `google_maps_flutter`, `Semantics` / TalkBack, `flutter_image_compress`, `record`, `audioplayers`, `flutter_tts`, cola offline (`sqflite` + `connectivity_plus`) y 11 pruebas en `mobile/test/widget_test.dart` |
| **Backend (BFF) y PWA** | Next.js App Router (`TypeScript`, `Zod`) en Vercel | API REST segura (`bff/src/app/api/`) que protege llaves de Google/Supabase, valida JWT Bearer y aplica *rate limiting* con `actor_hash`, además de PWA móvil responsiva (`430 px`) en `bff/src/app/app/page.tsx` con Web Speech API (`es-MX`) |
| **Base de datos, Auth y Storage** | Supabase (PostgreSQL 17 + PostGIS + `pgvector`) | Esquema aislado `extensions`, índices `GiST` parciales, `HNSW` (`768d`) y `GIN`, deduplicación atómica vía RPC, Realtime en `public.barriers`, buckets privados (`barrier-evidence` 5 MB, `public-briefs` 10 MB) y Auth anónimo/opcional (`signInAnonymously`) |
| **IA Generativa** | Google Gen AI SDK (`@google/genai`) | Visión de obstáculos (`bounding_boxes` `0..1000`), clasificación Open311 por foto/voz, evaluador visual de entradas, Copiloto accesible, embeddings de 768 dimensiones, resúmenes en Lenguaje Claro (ISO 24495-1), guía de transporte público y síntesis de audio WAV (`24 kHz`) |
| **Mapas, rutas y estándares** | Google Maps Platform + estándares cívicos | Maps SDK for Android (`MapsApiSettings` `gmp_git_agentskills_v1`), Routes API v2 (`WALK` y `TRANSIT`), Places API (New) con `places.accessibilityOptions`, Elevation API, Open311 GeoReport v2, `a11yjson.org` y `accessibility.cloud` |

---

## Backend BFF (`bff/`) y Base de Datos (`supabase/`)

> Consulta el detalle de configuración en [`bff/README.md`](bff/README.md), [`supabase/README.md`](supabase/README.md), la especificación de contrato en [`docs/BACKEND_SPEC.md`](docs/BACKEND_SPEC.md) y la ficha técnica integral en [`docs/VíaLibre — Ficha Técnica y Documentación Integral (Grupo XIUH).pdf`](docs/V%C3%ADaLibre%20%E2%80%94%20Ficha%20T%C3%A9cnica%20y%20Documentaci%C3%B3n%20Integral%20(Grupo%20XIUH).pdf).

### Rutas activas en `bff/src/app/api/`

| Método y ruta | Propósito |
| :--- | :--- |
| `GET /api/health` | Verificación pública de estado del servicio (`vialibre-bff`). |
| `GET` / `PUT` / `DELETE /api/profile/me` | Lectura, actualización y restablecimiento/anonimización de preferencias de accesibilidad del usuario. |
| `POST /api/routes/accessible` | Cálculo de rutas peatonales y de transporte público cruzadas con barreras activas (`find_barriers_along_route`), muestreo de elevación y guía paso a paso para primera vez. |
| `POST /api/places/nearby` | Búsqueda de lugares cercanos con opciones de accesibilidad (`Places API New`) y barreras próximas. |
| `POST /api/places/assess-photo` | Evaluador visual *"¿Puedo entrar aquí?"* sobre fotos sin metadatos EXIF para determinar si un acceso es libre, con precaución o inaccesible. |
| `POST /api/assistant/chat` | Copiloto conversacional de accesibilidad con acciones sugeridas hacia el mapa, guía, reporte o avisos. |
| `POST /api/barriers/upload-url` | Generación de *Signed Upload URL* hacia el bucket privado `barrier-evidence` (`<uid>/<uuid>.<ext>`). |
| `POST /api/barriers/analyze` | Análisis preliminar de foto (`< 1.5 MB`) con Gemini (categoría Open311, severidad `1..5`, `isImageClear`, *bounding boxes* `0..1000` y dependencia canalizadora) sin escritura en BD. |
| `POST /api/barriers/report` | Registro o confirmación ciudadana de barreras (foto, voz descartada de memoria o texto) con soporte de *idempotencyKey*, embedding `768d` y deduplicación espacial/vectorial vía RPC (`25 m`, coseno `>= 0.85`). |
| `POST /api/barriers/resolve` | Voto ciudadano de despeje o reparación (`record_barrier_resolution`, umbral de 2 confirmaciones). |
| `GET /api/barriers/nearby` | Consulta de barreras activas por radio geográfico (`find_nearby_barriers`) o formato GeoJSON / A11yJSON. |
| `GET /api/barriers/mine` | Historial de barreras reportadas por el usuario autenticado. |
| `GET /api/barriers/[id]` | Consulta de detalle de una barrera específica sin exponer `reporter_id`. |
| `POST /api/briefs/upload-url` | Generación de *Signed Upload URL* hacia el bucket privado `public-briefs`. |
| `POST /api/briefs/simplify` | Traducción de avisos públicos a 3 bloques en Lenguaje Claro (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) con caché por `doc_sha256` y audio. |
| `POST /api/notices/simplify` y `POST /api/storage/signed-url` | Rutas heredadas mantenidas por compatibilidad con el cliente PWA inicial. |

### Migraciones de base de datos (`supabase/migrations/`)

1. `20261126203359_extensions_and_schema_setup.sql` — Esquema aislado `extensions` (`postgis`, `vector`).
2. `20261126203740_core_tables_and_indexes.sql` — Tablas principales (`barriers` con columna generada `open311_status` y TTL `expires_at`, `barrier_events` con `idempotency_key` único, `public_briefs` con `doc_sha256` único, `rate_limit_events` con `actor_hash`) e índices `GiST` parcial, `HNSW` (`vector_cosine_ops`) y `GIN`.
3. `20261126203742_rls_storage_and_rpcs.sql` — Políticas RLS (escrituras exclusivas vía BFF `service_role`), buckets privados (`barrier-evidence`, `public-briefs`) y funciones RPC (`check_and_record_rate_limit`, `upsert_or_confirm_barrier`, `record_barrier_resolution`, `find_barriers_along_route`, `find_nearby_barriers`).
4. `20261126203947_optimize_rls_policies.sql` — Consolidación de políticas `SELECT` por rol y protección de `rls_auto_enable()`.
5. `20261126210000_enable_realtime_barriers.sql` — Publicación de `public.barriers` en `supabase_realtime` para actualización en vivo en el mapa.

> **Nota técnica y pendientes operativos:** En el entorno de desarrollo del BFF se documenta además el endurecimiento con 24 pruebas unitarias en Vitest, soporte de `user_profiles`, caché en `upsert_public_brief`, sincronización Open311 y `get_barriers_geojson`. Antes de pruebas E2E completas desde cero, verificar en consola la activación de *Allow anonymous sign-ins* en Supabase Auth (`aiztivgrynirvdkcdugd`) y la facturación GCP para `Elevation API` (el BFF degrada de forma segura si no está habilitada).

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
flutter test                 # Ejecuta 11 pruebas unitarias y de widgets
flutter run --dart-define-from-file=.env.json
```

> **Compilación CI/CD:** Cada `push` a `main` que modifique `mobile/**` o `.github/workflows/build-apk.yml` ejecuta el workflow **Compilar APK Android (VíaLibre)** en `ubuntu-latest` (Java 17 + Flutter `3.29.0`) con `--dart-define=BFF_BASE_URL=https://bff-steel.vercel.app` y actualiza `app-release.apk` en el Release `v1.0.0-mvp`.

---

## Estándares abiertos y accesibilidad

- **Accesibilidad móvil y lectura**: WCAG 2.2 nivel AA, EN 301 549, W3C COGA e ISO 24495-1 (Lenguaje Claro).
- **Datos cívicos y geoespaciales**: Open311 (GeoReport v2), OpenStreetMap (`wheelchair`, `tactile_paving`, `kerb`, `incline`), `a11yjson.org` y GTFS-Pathways.
- **Privacidad desde el diseño**: Uso sin registro obligatorio (sesión anónima), eliminación de metadatos EXIF antes de subir fotografías (`keepExif: false`), descarte inmediato de audio de reporte en memoria, expiración temporal de obstáculos pasajeros (`expires_at`), cumplimiento de ToS de Google Maps (sin caché de coordenadas >30 días ni entrenamiento de IA) y exclusión de llaves/secretos en el repositorio (`.gitignore`).
- **Declaración de uso de IA (Bases del Hackatón)**: Uso de **Google Gemini** (`@google/genai`) como motor central del producto y generación de logotipo, **Google Stitch** para bocetos de interfaz, y asistencia de **Google Gemini / Antigravity** en redacción documental y revisión técnica validada por el equipo.

## Documentación

- [VíaLibre — Ficha Técnica y Documentación Integral (Grupo XIUH) · PDF](docs/V%C3%ADaLibre%20%E2%80%94%20Ficha%20T%C3%A9cnica%20y%20Documentaci%C3%B3n%20Integral%20(Grupo%20XIUH).pdf) · [Versión viva en Google Docs](https://docs.google.com/document/d/1eiAh3THeHomo15f_WfTTain3cQTX7IAQNAMgh8iY8Zs/edit)
- [Documentación Técnica Integral del Repositorio (PDF)](docs/V%C3%ADaLibre%20-%20Documentaci%C3%B3n%20T%C3%A9cnica%20Integral.pdf)
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
