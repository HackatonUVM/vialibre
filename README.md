# VíaLibre

> **Reto 2 — Ciudad para todas y todos** · Alineado a **ODS 10** (Meta 10.2) y **ODS 11** (Metas 11.2 y 11.7) · **Grupo Xiuh (UVM Campus Lomas Verdes)**.

Plataforma móvil para **Android (Flutter)** y **Web Móvil (PWA)** enfocada en navegación peatonal y en transporte público accesible, reporte ciudadano de barreras urbanas mediante fotografía o nota de voz, evaluación visual de accesibilidad arquitectónica y traducción de avisos públicos a **Lenguaje Claro (ISO 24495-1)** y audio con **Google Gemini (Google AI Studio)**.

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

1. **Búsqueda y ruta multimodal accesible por perfil**: Selección persistente de perfil (*Silla de ruedas / Carriola*, *Baja visión*, *Lectura clara*) sin registro obligatorio (`signInAnonymously`); geocodificación y búsqueda de lugares vía **Photon (Komoot)** y **Nominatim (OpenStreetMap)**, cálculo de rutas peatonales y accesibles con **Valhalla**, **OSRM** y **OpenRouteService** (opcional), cruzadas en tiempo real con barreras activas en **PostGIS** (`ST_DWithin` en 25 m) y análisis de pendientes topográficas (**Open-Meteo Elevation API**, DEM 90 m), más guía paso a paso **"Primera vez en transporte público"** generada con **Google Gemini (Google AI Studio)** bajo *grounding* estricto y lectura por voz (`flutter_tts` / audio).
2. **Reporte ciudadano en un toque con cola offline**: Captura de fotografía (con limpieza automática de metadatos EXIF mediante `flutter_image_compress` `keepExif: false` y compresión `< 1.45 MB` en el teléfono) o nota de voz breve (`.m4a` descartada inmediatamente de memoria tras transcribirse); análisis visual con *bounding boxes* (`0..1000`) en **Google Gemini (Google AI Studio)**, clasificación compatible con **Open311** / `a11yjson.org`, deduplicación atómica espacial + vectorial (`768` dimensiones, similitud coseno `>= 0.85`) en un radio de **25 metros**, votación comunitaria de despeje/reparación (`record_barrier_resolution`) y cola offline en SQLite (`sqflite` con `idempotency_key` UUIDv4) sincronizada automáticamente al recuperar conectividad.
3. **Copiloto IA y Evaluador Visual ("¿Puedo entrar aquí?")**: Asistente conversacional con **Google AI Studio (`gemini-2.5-flash`)** adaptado al perfil de accesibilidad para resolver dudas de movilidad y transporte urbano con acciones directas hacia mapa, guía o reporte, junto con evaluación fotográfica de entradas, puertas y rampas (`accessible`, `caution`, `inaccessible`).
4. **Traductor de avisos públicos a Lenguaje Claro y audio**: Carga de comunicados municipales (PDF `<= 10 MB` mediante *Signed Upload URL*, fotografía o texto) para resumirlos con *grounding* estricto en tres bloques accionables (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) bajo lineamientos **ISO 24495-1** y **W3C COGA**, con caché criptográfico por `doc_sha256` y reproducción en audio.

---

## Impacto de inclusión y alineación con los ODS 10 y 11

### 1. Diagnóstico cuantitativo del problema (Fuentes oficiales)

Las barreras físicas en la vía pública y las barreras digitales/cognitivas en la información gubernamental excluyen de forma sistemática a millones de personas de su derecho a la movilidad y a la participación ciudadana:

- **Magnitud global y nacional de la discapacidad:** De acuerdo con la **Organización Mundial de la Salud (OMS)**, cerca de **1,300 millones de personas** en el mundo (**16 %** de la población global) viven con una discapacidad importante. En México, la **ENADID 2023 del INEGI** estima **8.8 millones de personas** de 5 años y más con discapacidad (**7.2 %** de ese grupo; **53.5 % mujeres** y **46.5 % hombres**). Las dificultades más frecuentes son **ver, aun usando lentes (~45.4 % – 45.8 %)** y **caminar, subir o bajar (~40.2 % – 40.3 %)**.
- **Envejecimiento demográfico:** Según el **Censo de Población y Vivienda 2020 (INEGI)**, en México residen **15.1 millones de personas adultas mayores de 60 años y más** (**12 %** de la población total), grupo que concentra el **50.0 %** de la población con discapacidad según la **ENADID 2023**.
- **Déficit de infraestructura peatonal urbana:** El **Inventario Nacional de Viviendas (INEGI)** documenta que el **77.8 % de las manzanas urbanas del país no cuenta con rampas para silla de ruedas en ninguna vialidad** (solo **6.5 %** dispone de ellas en todas sus calles y **14.2 %** de forma parcial), mientras que el **27.9 %** carece de banquetas en todas sus vialidades.
- **Brecha de acceso al transporte público:** **ONU-Hábitat** (agencia custodia del indicador **ODS 11.2.1**) reporta que cerca del **40 % de la población urbana mundial** carece de acceso conveniente al transporte público.
- **Oportunidad tecnológica de inclusión:** Según la **ENDUTIH 2024 (INEGI)**, México alcanza **100.2 millones de personas usuarias de internet** (**83.1 %** de la población de 6 años y más), y el **97.2 %** se conecta mediante un **teléfono celular inteligente**. La infraestructura de bolsillo ya existe; el vacío está en el diseño accesible de las herramientas digitales.

---

### 2. Contribución directa a los Objetivos de Desarrollo Sostenible

| Objetivo y Meta | Barrera de exclusión que atiende | Solución implementada en VíaLibre | Impacto de inclusión esperado |
| :--- | :--- | :--- | :--- |
| **ODS 10 — Reducción de las desigualdades (Meta 10.2)** | Exclusión social, digital y cognitiva provocada por aplicaciones que exigen registro complejo, formularios ciudadanos inaccesibles y avisos oficiales redactados con lenguaje técnico o legal. | Acceso inmediato sin cuenta obligatoria (`signInAnonymously`), selección de perfil accesible (*Silla de ruedas / Carriola*, *Baja visión*, *Lectura clara*), reporte ciudadano en un toque por foto o nota de voz, interfaz **WCAG 2.2 AA / W3C COGA** con TalkBack y traducción de avisos públicos a **Lenguaje Claro (ISO 24495-1)** en tres bloques accionables (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) con audio en español. | Reduce la brecha de comprensión y participación cívica para personas con discapacidad, personas mayores, personas neurodivergentes y usuarios con baja alfabetización digital. |
| **ODS 11 — Ciudades y comunidades sostenibles (Metas 11.2 y 11.7)** | Calles sin rampas, obstáculos temporales no reflejados en mapas convencionales y falta de certeza previa sobre accesibilidad física en estaciones de transporte, clínicas y edificios públicos. | Rutas peatonales y de traslado calculadas con motores abiertos (**Valhalla / OSRM / OpenRouteService**) enriquecidas con pendientes reales (**Open-Meteo Elevation**), atributos de accesibilidad de **OpenStreetMap** (**Photon / Nominatim**), cruce geoespacial con barreras activas en **PostGIS**, guía paso a paso *"Primera vez en transporte público"* y evaluador visual *"¿Puedo entrar aquí?"* mediante fotografía con **Google AI Studio**. | Aumenta la autonomía y seguridad en desplazamientos hacia el transporte público y servicios esenciales, visibilizando barreras urbanas en tiempo real para su atención. |

---

### 3. Capacidades demostrables del prototipo y diseño inclusivo

Las siguientes medidas de inclusión, privacidad y calidad técnica se encuentran implementadas y verificables en la arquitectura actual del proyecto (Android APK + PWA móvil + BFF Next.js + Supabase):

1. **Accesibilidad móvil verificable desde el código:** Sistema visual adaptativo **"Calma Urbana"** (modos Claro, Oscuro y **Alto Contraste**), áreas táctiles mínimas de **48 × 54 dp** en botones principales (`AccessibleButton`), etiquetas semánticas (`Semantics`) para **TalkBack**, señalización que combina **color, forma geométrica y texto**, y soporte para escalado tipográfico y reducción de movimiento.
2. **Privacidad desde el diseño:** Limpieza de metadatos **EXIF** y compresión local (`< 1.5 MB`) en el dispositivo antes de enviar fotografías, descarte inmediato del audio crudo tras su transcripción, sesión anónima sin recopilación forzada de datos personales y almacenamiento en buckets privados aislados por identificador de sesión.
3. **Calidad y vigencia de datos comunitarios:** Cada reporte se clasifica en **8 categorías** compatibles con **Open311** y pasa por deduplicación atómica que combina proximidad espacial (**radio de 25 metros** en `PostGIS`) y similitud semántica (**similitud coseno ≥ 0.85** sobre vectores de **768 dimensiones** en `pgvector`). Los obstáculos temporales expiran automáticamente a las **168 horas (7 días)** si no reciben confirmaciones y pueden marcarse como resueltos mediante validación comunitaria (**2 votos**).
4. **Resiliencia ante baja conectividad:** Cola local en **SQLite (`sqflite`)** con llave de idempotencia única por evento para capturar reportes sin conexión y sincronizarlos automáticamente al recuperar señal.

---

### 4. Viabilidad y escalabilidad a más usuarios y comunidades

VíaLibre está diseñado para crecer desde un piloto local (campus universitario, colonia o clínica) hacia municipios y nuevas ciudades sin incrementar proporcionalmente sus costos ni requerir moderación manual intensiva:

- **Escalabilidad de adopción:** La disponibilidad simultánea en **Android nativo (APK)** y **PWA web móvil** elimina barreras de entrada entre dispositivos Android e iOS. Además, al beneficiar también a familias con carriolas, repartidores y adultos mayores, amplía la base de personas que reportan y validan obstáculos en beneficio de quienes más los necesitan.
- **Escalabilidad económica (control de costos de IA y mapas con APIs gratuitas):**
  - **Caché comunitario por hash (`doc_sha256`):** Un mismo comunicado municipal o aviso de desvío se resume y sintetiza en audio **una sola vez**, sirviéndose desde caché al resto de la comunidad sin consumo adicional de tokens de **Google AI Studio**.
  - **Cero facturación de APIs de rutas, elevación y geocodificación en el BFF:** El backend opera sobre infraestructura **Open Source** gratuita (**Valhalla**, **OSRM**, **Open-Meteo Elevation**, **Photon** y **Nominatim**), además de **Google AI Studio (`@google/genai`)** sin requerir Vertex AI ni cuentas de facturación de Google Cloud Platform, protegido por limitación de tasa en base de datos (`rate_limit_events`).
- **Escalabilidad operativa e institucional:** La expiración automática y la resolución colaborativa evitan cuellos de botella de moderación, mientras que la adopción de estándares abiertos (**Open311 GeoReport v2**, **OpenStreetMap**, **`a11yjson.org`**, **GTFS-Pathways**, **WCAG 2.2 AA** e **ISO 24495-1**) permite integrar los reportes ciudadanos directamente con sistemas municipales de atención ciudadana y redes de movilidad existentes.

---

### 5. Protocolo de evaluación de impacto (KPIs medibles en piloto y demo)

Para validar el impacto real con evidencia empírica durante la demostración y las pruebas de campo:

1. **Eficiencia de reporte ciudadano:** Comparar el tiempo (en segundos) y número de pasos necesarios para reportar una barrera mediante foto o voz en VíaLibre (usando TalkBack) frente a un portal municipal tradicional.
2. **Precisión de consolidación espacial/semántica:** Verificar que múltiples reportes sobre un mismo obstáculo dentro de un radio de **25 metros** se consoliden en un único incidente activo incrementando su contador de confirmaciones.
3. **Comprensión lectora y auditiva:** Evaluar con personas adultas mayores y neurodivergentes si el resumen en Lenguaje Claro y su audio permiten responder correctamente *qué ocurrió*, *a quién afecta* y *qué hacer hoy* sin consultar el documento original.
4. **Auditoría integral de accesibilidad:** Verificar el **100 %** de las pantallas activas respecto a contraste mínimo (**4.5:1** en texto y **3:1** en iconografía), orden de foco con lector de pantalla, tamaño de objetivos táctiles y funcionamiento de la cola sin conexión.

---

## Sistema de Diseño y Paleta de Colores ("Calma Urbana")

La interfaz evolucionó del esquema inicial de los bocetos en Google Stitch (`#0A192F` / `#FFB300`) al sistema adaptativo **"Calma Urbana"** (`mobile/lib/app/theme/vialibre_theme.dart`), diseñado bajo **WCAG 2.2 AA**, **EN 301 549** y **W3C COGA** para uso real en la vía pública:

| Token | Modo Claro | Modo Oscuro | Rol y justificación de accesibilidad |
| :--- | :--- | :--- | :--- |
| `canvas` / `card` | `#FAF8F5` / `#FFFFFF` | `#141416` / `#1D1D1F` | Fondo marfil cálido antirreflejo bajo luz solar en exteriores, y superficie oscura confortable de noche. |
| `ink` / `muted` | `#18181B` / `#52525B` | `#FAF8F5` / `#B8B8C4` | Contraste tipográfico `>= 4.5:1` sobre superficies claras y oscuras. |
| `coral` / `ctaBg` | `#C83E4D` / `#18181B` | `#EF4756` / `#FAF8F5` | Acento activo y botones primarios (mínimo `48x52 dp` / `48x48 dp`) claramente distinguibles de las alertas viales. |
| `mintSoft` / `mintInk` | `#DCFCE7` / `#166534` | `#163525` / `#86EFAC` | Indica rutas o accesos libres/verificados sin depender solo del color (acompañado de ícono y etiquetas). |
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
| **Cliente móvil** | Flutter (Dart `>=3.5.0 <4.0.0`, Android `minSdk 24+`) | Arquitectura modular por *features* (`explore`, `map_routes`, `report_barrier`, `public_briefs`, `gemini_assistant`, `profile`), `flutter_riverpod`, `go_router`, `google_maps_flutter` (visor base en Android v1.0.0-mvp alimentado con rutas y lugares OSM del BFF), `Semantics` / TalkBack, `flutter_image_compress`, `record`, `audioplayers`, `flutter_tts`, cola offline (`sqflite` + `connectivity_plus`) y 11 pruebas en `mobile/test/widget_test.dart` |
| **Backend (BFF) y PWA** | Next.js App Router (`TypeScript`, `Zod`) en Vercel | API REST segura (`bff/src/app/api/`) que protege `GOOGLE_API_KEY` (Google AI Studio) y `SUPABASE_SERVICE_ROLE_KEY`, orquesta APIs geoespaciales Open Source (`bff/src/lib/apis/open-maps.ts`), valida JWT Bearer y aplica *rate limiting* con `actor_hash`, además de PWA móvil responsiva (`430 px`) en `bff/src/app/app/page.tsx` con Web Speech API (`es-MX`) |
| **Base de datos, Auth y Storage** | Supabase (PostgreSQL 17 + PostGIS + `pgvector`) | Esquema aislado `extensions`, índices `GiST` parciales, `HNSW` (`768d`) y `GIN`, deduplicación atómica vía RPC, Realtime en `public.barriers`, buckets privados (`barrier-evidence` 5 MB, `public-briefs` 10 MB) y Auth anónimo/opcional (`signInAnonymously`) |
| **IA Generativa** | Google AI Studio (`@google/genai`, Gemini Developer API) | Sin Vertex AI ni facturación GCP: usa `gemini-2.5-flash` y `text-embedding-004` (`768d`) para visión de obstáculos (`bounding_boxes` `0..1000`), clasificación Open311 por foto/voz, evaluador visual de entradas, Copiloto accesible, resúmenes en Lenguaje Claro (ISO 24495-1), guía de transporte público y síntesis de audio |
| **Mapas, rutas y estándares** | APIs Open Source (OSM) + estándares cívicos | Enrutamiento peatonal en **Valhalla** (`valhalla1.openstreetmap.de`), **OSRM** (`router.project-osrm.org`) y **OpenRouteService** (opcional), elevación DEM 90 m con **Open-Meteo Elevation**, geocodificación/lugares con **Photon (Komoot)** y **Nominatim (OpenStreetMap)**, más **Open311 GeoReport v2**, `a11yjson.org` y `accessibility.cloud` |

---

## Backend BFF (`bff/`) y Base de Datos (`supabase/`)

> Consulta el detalle de configuración en [`bff/README.md`](bff/README.md), [`supabase/README.md`](supabase/README.md), la especificación de contrato en [`docs/BACKEND_SPEC.md`](docs/BACKEND_SPEC.md) y la ficha técnica integral en [`docs/VíaLibre — Ficha Técnica y Documentación Integral (Grupo XIUH).pdf`](docs/V%C3%ADaLibre%20%E2%80%94%20Ficha%20T%C3%A9cnica%20y%20Documentaci%C3%B3n%20Integral%20(Grupo%20XIUH).pdf).

### Rutas activas en `bff/src/app/api/`

| Método y ruta | Propósito |
| :--- | :--- |
| `GET /api/health` | Verificación pública de estado del servicio (`vialibre-bff`). |
| `GET` / `PUT` / `DELETE /api/profile/me` | Lectura, actualización y restablecimiento/anonimización de preferencias de accesibilidad del usuario. |
| `POST /api/routes/accessible` | Geocodificación vía **Photon/Nominatim (OSM)**, cálculo de rutas vía **OpenRouteService (opcional) / Valhalla / OSRM**, pendientes reales con **Open-Meteo Elevation**, cruce con barreras activas (`find_barriers_along_route`) y guía paso a paso con Google AI Studio. |
| `POST /api/places/nearby` | Búsqueda de lugares cercanos y etiquetas de accesibilidad OSM vía **Photon (Komoot) + Nominatim** y cruce con barreras próximas (`get_nearby_barriers`). |
| `POST /api/places/assess-photo` | Evaluador visual *"¿Puedo entrar aquí?"* con **Google AI Studio (`gemini-2.5-flash`)** sobre fotos sin metadatos EXIF para determinar si un acceso es libre, con precaución o inaccesible. |
| `POST /api/assistant/chat` | Copiloto conversacional de accesibilidad (**Google AI Studio**) con acciones sugeridas hacia el mapa, guía, reporte o avisos. |
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

> **Nota técnica sobre APIs y pendientes operativos:** El BFF (`bff/src/lib/apis/open-maps.ts` y `bff/src/lib/gemini.ts`) ya opera sin dependencia de facturación de Google Cloud Platform (`Routes API v2`, `Places API New`, `Elevation API` ni `Vertex AI`), utilizando exclusivamente **Google AI Studio (`GOOGLE_API_KEY`)** y APIs **Open Source** (**Valhalla**, **OSRM**, **Open-Meteo Elevation**, **Photon** y **Nominatim**). En el cliente Android (`mobile/`), `google_maps_flutter` permanece únicamente como visor de mapa base en `v1.0.0-mvp`. Antes de pruebas E2E completas desde cero, verificar únicamente la activación de *Allow anonymous sign-ins* en Supabase Auth (`aiztivgrynirvdkcdugd`).

---

## Ejecución y verificación local

### Backend (`bff/`)

```bash
cd bff
cp .env.example .env.local   # Completar GOOGLE_API_KEY (AI Studio) y llaves de Supabase (nunca subir a Git)
npm install
npm run lint
npm run build
npm run dev                  # Inicia en http://localhost:3000
```

### App móvil (`mobile/`)

```bash
cd mobile
cp .env.example .env.json    # Completar SUPABASE_ANON_KEY y llaves de configuración móvil
flutter pub get
flutter analyze --no-pub
flutter test                 # Ejecuta 11 pruebas unitarias y de widgets
flutter run --dart-define-from-file=.env.json
```

> **Compilación CI/CD:** Cada `push` a `main` que modifique `mobile/**` o `.github/workflows/build-apk.yml` ejecuta el workflow **Compilar APK Android (VíaLibre)** en `ubuntu-latest` (Java 17 + Flutter `3.29.0`) con `--dart-define=BFF_BASE_URL=https://bff-steel.vercel.app` y actualiza `app-release.apk` en el Release `v1.0.0-mvp`.

---

## Estándares abiertos y accesibilidad

- **Accesibilidad móvil y lectura**: WCAG 2.2 nivel AA, EN 301 549, W3C COGA e ISO 24495-1 (Lenguaje Claro).
- **Datos cívicos y geoespaciales**: Open311 (GeoReport v2), OpenStreetMap (licencia ODbL: `wheelchair`, `tactile_paving`, `kerb`, `incline`), Valhalla / OSRM, Open-Meteo Elevation, Photon / Nominatim, `a11yjson.org` y GTFS-Pathways.
- **Privacidad desde el diseño**: Uso sin registro obligatorio (sesión anónima), eliminación de metadatos EXIF antes de subir fotografías (`keepExif: false`), descarte inmediato de audio de reporte en memoria, expiración temporal de obstáculos pasajeros (`expires_at`) y exclusión de llaves/secretos en el repositorio (`.gitignore`).
- **Declaración de uso de IA (Bases del Hackatón)**: Uso de **Google Gemini vía Google AI Studio** (`@google/genai`) como motor central del producto y generación de logotipo, **Google Stitch** para bocetos de interfaz, y asistencia de **Google Gemini / Antigravity** en redacción documental y revisión técnica validada por el equipo.

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
