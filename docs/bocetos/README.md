# VíaLibre — Boceto y Documentación con IA

## Contexto del proyecto

- **Nombre del equipo:** Grupo Xiuh
- **Campus:** UVM Campus Lomas Verdes
- **Integrantes:**
  - Julio Abraham Miguel Pedro
  - Jose Pablo Ferrari Martinez
  - Sebastian Rosales Ocampo
- **Nombre de la app:** VíaLibre
- **Reto:** Hackatón Nacional de Innovación con IA Aplicada — Ingenio Incluyente (ODS 10 y 11)
- **Enlace al boceto visual (Google Stitch):** https://stitch.google.com/projects/11135309563401328808
- **Repositorio GitHub:** https://github.com/HackatonUVM/vialibre
- **Enlace de descarga Android (APK Release):** [Descargar app-release.apk (v1.0.0-mvp)](https://github.com/HackatonUVM/vialibre/releases/download/v1.0.0-mvp/app-release.apk) · [Ver Release en GitHub](https://github.com/HackatonUVM/vialibre/releases/tag/v1.0.0-mvp)
- **App Móvil Web (PWA para iPhone & Android):** https://bff-steel.vercel.app/app
- **Backend BFF en Vercel:** https://bff-steel.vercel.app

---

## Galería de bocetos y sistema de diseño (`docs/bocetos/`)

| Archivo | Descripción |
| --- | --- |
| [01-sistema-de-diseno-colores-tipografia.jpg](01-sistema-de-diseno-colores-tipografia.jpg) | Sistema de diseño: paleta de alto contraste (`#0A192F`, `#FFB300`, `#281400`, `#0F172A`), tipografía `Inter`, botones y componentes |
| [02-pantalla-elige-tu-perfil.jpg](02-pantalla-elige-tu-perfil.jpg) | Pantalla inicial de selección de perfil de accesibilidad (*Silla de ruedas / Carriola*, *Baja visión*, *Lectura clara*) |
| [03-pantalla-mapa-ruta-accesible.jpg](03-pantalla-mapa-ruta-accesible.jpg) | Mapa y ruta peatonal accesible evitando pendientes y banquetas rotas, con lectura de indicaciones |
| [04-pantalla-reportar-obstaculo.jpg](04-pantalla-reportar-obstaculo.jpg) | Flujo de reporte ciudadano en un toque con detección visual de obstáculos y protección de privacidad (limpieza EXIF) |
| [05-pantalla-avisos-lenguaje-claro.jpg](05-pantalla-avisos-lenguaje-claro.jpg) | Traductor de avisos públicos en Lenguaje Claro por pasos y resumen en audio |
| [06-logo-vialibre.jpg](06-logo-vialibre.jpg) | Logotipo e ícono de la aplicación VíaLibre |

---

## 1. Resumen ejecutivo

VíaLibre es una aplicación móvil para Android, desarrollada en Flutter, que ayuda a personas con discapacidad motriz, baja visión, adultos mayores, personas neurodivergentes y familias con carriolas a desplazarse con seguridad y entender avisos públicos. A diferencia de los mapas convencionales o plataformas aisladas, integra rutas peatonales que consideran pendientes y obstáculos reales, reportes ciudadanos mediante una fotografía o nota de voz breve, y traducción de comunicados municipales a Lenguaje Claro y audio mediante Google Gemini.

---

## 2. Boceto, planteamiento y justificación

### Planteamiento del problema y justificación (Qué, Cómo y Por qué)

#### ¿Qué problema resuelve?
Las ciudades y la información pública suelen diseñarse pensando en un usuario promedio sin restricciones físicas, sensoriales ni cognitivas. En la vida diaria esto excluye a personas en silla de ruedas o con movilidad reducida, adultos mayores, personas con discapacidad visual o auditiva, personas neurodivergentes y familias con carriolas, manifestándose en cuatro barreras concretas:
1. **Rutas que ignoran el estado real de la calle:** los mapas tradicionales calculan el camino más corto sin advertir banquetas rotas, rampas bloqueadas, pendientes pronunciadas o elevadores descompuestos.
2. **Datos desactualizados sobre lugares públicos:** es difícil confirmar con anticipación si una clínica, oficina gubernamental o estación de transporte cuenta con acceso sin escalones o baño adaptado funcional.
3. **Información pública difícil de entender:** los avisos de desvíos, trámites municipales o alertas se difunden en documentos extensos con lenguaje administrativo o legal poco accesible para personas mayores, neurodivergentes o usuarias de lectores de pantalla.
4. **Barreras para reportar fallas urbanas:** reportar un desperfecto suele exigir formularios largos, ubicación exacta por calle y portales web incompatibles con tecnología asistiva desde el celular.

#### ¿Cómo lo resuelve VíaLibre?
VíaLibre conecta tres flujos simples en una aplicación móvil Android diseñada para operarse con una mano o con TalkBack, sin registro obligatorio:
1. **Enrutamiento peatonal adaptado:** combina perfiles de accesibilidad (*Silla de ruedas / Carriola*, *Baja visión*, *Lectura clara*) con datos de elevación y reportes ciudadanos activos para advertir pendientes u obstáculos e indicar el recorrido por voz.
2. **Reporte ciudadano en un toque con IA:** permite capturar una foto o grabar un audio corto; Gemini clasifica el obstáculo en formato abierto Open311, lo ubica en la imagen y lo compara vectorialmente en un radio de 25 metros para evitar duplicados antes de publicarlo en el mapa.
3. **Traductor de avisos públicos a Lenguaje Claro y audio:** procesa PDFs o fotos de comunicados oficiales y los resume en tres bloques accionables (*Qué pasó*, *A quién afecta*, *Qué hacer hoy*) con lectura en voz alta en español.

#### ¿Por qué es necesaria y relevante esta solución?
Las herramientas actuales atienden el problema de manera aislada: las apps de mapas no integran reportes ciudadanos accesibles en la ruta, los portales cívicos exigen formularios complejos y no traducen avisos administrativos, y muchas apps de accesibilidad dependen de balizas físicas instaladas en edificios. VíaLibre unifica navegación, participación ciudadana sin fricción y comprensión lectora en una sola app gratuita, protegiendo la privacidad (sin cuenta obligatoria y eliminando metadatos EXIF antes de guardar fotos) y usando estándares abiertos para interoperar con municipios.

### Boceto conceptual de interfaz
El diseño visual completo de las pantallas y el sistema de diseño de alto contraste están disponibles en **Google Stitch**:
- **Enlace al boceto en Google Stitch:** https://stitch.google.com/projects/11135309563401328808

```text
+--------------------------------------------------+
| PANTALLA 1: INICIO Y PERFIL DE ACCESIBILIDAD     |
+--------------------------------------------------+
| Perfil: [ Silla de ruedas ] [ Baja visión ]      |
|         [ Lectura clara ]                        |
| Acción principal: [ Buscar ruta accesible ]      |
| Accesos: [ Reportar obstáculo ] [ Avisos ]       |
+--------------------------------------------------+

+--------------------------------------------------+
| PANTALLA 2: MAPA Y RUTA ACCESIBLE                |
+--------------------------------------------------+
| Buscar: [ Clínica cercana sin escalones   ] [Voz]|
| Perfil activo: Silla de ruedas                   |
| +----------------------------------------------+ |
| | Mapa Android con ruta peatonal               | |
| | (Pin accesible: forma geométrica + color)    | |
| | Alerta: Pendiente 8 % · Banqueta obstruida   | |
| +----------------------------------------------+ |
| [ Escuchar indicaciones ]                        |
+--------------------------------------------------+

+--------------------------------------------------+
| PANTALLA 3: REPORTE EN UN TOQUE                  |
+--------------------------------------------------+
| [ Tomar foto ]   o   [ Grabar nota de voz ]      |
| +----------------------------------------------+ |
| | Vista previa (EXIF eliminado y rostros dif.) | |
| | [Recuadro IA: Rampa bloqueada]               | |
| +----------------------------------------------+ |
| Categoría IA: Banqueta obstruida · Prioridad Alta|
| [ Confirmar y publicar ]                         |
+--------------------------------------------------+

+--------------------------------------------------+
| PANTALLA 4: AVISOS EN LENGUAJE CLARO             |
+--------------------------------------------------+
| [ Subir PDF o foto del aviso municipal ]         |
| - Qué pasó: Ruta 4 desviada por obras.           |
| - A quién afecta: Quienes viajan al centro.      |
| - Qué hacer hoy: Tomar parada Norte (100 m).     |
| [ Escuchar resumen en audio ]                    |
+--------------------------------------------------+
```

### Justificación alineada a los ODS 10 y 11

| ODS y meta | Desigualdad o barrera urbana que atiende | Cómo la atiende VíaLibre | Impacto buscado |
| :--- | :--- | :--- | :--- |
| **ODS 10 — Reducción de las desigualdades (Meta 10.2)** | Exclusión social, digital y cognitiva que enfrentan personas con discapacidad motriz, visual o auditiva, adultos mayores y personas neurodivergentes al desplazarse o intentar comprender avisos públicos técnicos. | Elimina el requisito de cuenta/contraseña, adapta la interfaz al perfil de lectura o visión, traduce comunicados legales/administrativos a **Lenguaje Claro (ISO 24495-1)** con audio en español y habilita reportes cívicos por voz o foto en un toque. | Garantizar igualdad de acceso a la información pública, los servicios urbanos y la participación ciudadana sin barreras técnicas ni cognitivas. |
| **ODS 11 — Ciudades y comunidades sostenibles (Metas 11.2 y 11.7)** | Infraestructura peatonal deteriorada, rampas bloqueadas, pendientes severas y falta de datos confiables sobre accesibilidad en transporte público, clínicas y oficinas gubernamentales. | Cruza rutas peatonales y datos de elevación con reportes ciudadanos georreferenciados en tiempo real (evitando duplicados en 25 m) y adopta estándares cívicos abiertos (**Open311**, **OpenStreetMap**, **GTFS-Pathways**, **`a11yjson.org`**). | Facilitar traslados peatonales seguros, accesibles y autónomos hacia el transporte y espacios públicos inclusivos. |

---

## 3. Documentación funcional

1. **Perfil de accesibilidad persistente:** permite elegir necesidades principales (movilidad en silla de ruedas o carriola, baja visión, lectura clara) una sola vez para adaptar rutas, alertas y escala visual sin volver a pedir datos.
2. **Búsqueda y ruta peatonal adaptada:** interpreta destinos o consultas en lenguaje natural, muestra lugares cercanos con atributos de accesibilidad verificados y advierte sobre pendientes pronunciadas u obstáculos activos en el trayecto.
3. **Reporte ciudadano por foto o nota de voz:** permite capturar una fotografía o grabar un audio corto de una barrera urbana; la IA identifica el tipo de obstáculo, ubica su posición en la imagen, agrupa reportes repetidos cercanos (radio de 25 m) y publica el pin en el mapa.
4. **Traductor de información pública y lectura en audio:** convierte comunicados municipales, avisos de transporte o alertas de emergencia (PDF o fotografía) en tres bloques breves en Lenguaje Claro con reproducción directa en voz alta.
5. **Borradores sin conexión en el teléfono:** si el usuario pierde señal en la calle al capturar un reporte, la aplicación guarda el borrador en una base local del dispositivo y lo sincroniza al recuperar conectividad.
6. **Asistente guiado en vivo por voz y cámara (Post-MVP — `[PENDIENTE]`):** módulo futuro planeado para responder preguntas habladas sobre cruces u obstáculos inmediatos en tiempo real.

---

## 4. Documentación técnica

*(El detalle ampliado de endpoints, tablas y configuración se encuentra también en `DOCUMENTACION_TECNICA.md` del repositorio.)*

### 4.1 Arquitectura general
La aplicación adopta una arquitectura **Cliente Móvil Flutter (Android) + BFF (Backend for Frontend) en Next.js**, manteniendo Next.js exclusivamente como capa de API (`app/api/...`) sin frontend web duplicado, conectado a **Supabase** y **Google Cloud / Google Maps Platform**:

```text
[App Móvil Flutter (Dart, Android minSdk 24+)]
 ├── Sesión anónima (supabase_flutter signInAnonymously -> JWT Bearer)
 ├── Limpieza EXIF y compresión en dispositivo (< 1.5 MB)
 ├── Mapa nativo Android (google_maps_flutter + mapId + AdvancedMarker)
 ├── Audio/Voz (record + audioplayers WAV) y cola offline (sqflite)
 │
 ├──► HTTPS + Bearer JWT (< 1.5 MB) ──► [BFF Next.js App Router (Node.js + Zod)]
 │       ├── Verificación JWT (supabase.auth.getUser(token))
 │       ├──► [@google/genai] ───────────► Gemini (visión, clasificación, embeddings, texto, TTS WAV)
 │       ├──► [Google Maps Server Key] ──► Routes API, Places API (New), Elevation API
 │       └──► [@supabase/supabase-js] ───► Supabase Postgres RPC (PostGIS + pgvector)
 │
 └──► Signed Upload URL (> 2 MB / PDFs) ──► [Supabase Storage (uploadToSignedUrl)]
```

**Decisiones técnicas de esta integración:**
- **Por qué Flutter (Android) sobre Kotlin/Compose puro:** `google_maps_flutter` utiliza el renderizado nativo del Maps SDK for Android y expone directamente `Semantics` para TalkBack, reduciendo el tiempo de desarrollo frente a implementar manualmente capas de red, cámara, audio y SQLite en Kotlin durante un hackatón.
- **Separación limpia frente al entorno web:** Next.js actúa únicamente como BFF seguro validando `Authorization: Bearer <JWT>`, protegiendo las llaves de Gemini y Google Maps sin mantener dos frontends.
- **Límite de payload y archivos grandes:** las fotos se comprimen en el teléfono (`< 1.5 MB`) antes de enviarse al Route Handler; los PDFs o archivos mayores a `2 MB` se suben directo a Supabase Storage mediante *Signed Upload URLs* (`uploadToSignedUrl`).
- **Runtimes y modo en vivo:** los endpoints de Gemini usan Node.js runtime. El modo conversacional en vivo por WebSocket (`BidiGenerateContent`) requiere conexiones largas persistentes, por lo que queda acotado a un microservicio futuro en **Google Cloud Run** (`[PENDIENTE]`).

### 4.2 Stack tecnológico y justificación de cumplimiento con las Bases

El stack fue seleccionado para cumplir estrictamente con las herramientas obligatorias y permitidas en las **Bases Generales del Hackatón (pp. 9 y 13)**, evitando plataformas o servicios de IA/nube ajenos o no autorizados (sin Azure, OpenAI ni Bing Maps):

| Categoría en las Bases | Tecnología elegida | Justificación técnica y de cumplimiento |
| :--- | :--- | :--- |
| **Herramienta obligatoria (IA)** | **Google Gemini** (`@google/genai`) | Es el motor central de toda la solución (análisis visual de barreras, clasificación Open311, embeddings multimodales, Lenguaje Claro y TTS en español). |
| **Herramienta obligatoria (Colaboración)** | **Google Workspace** (Docs / Drive) | Usada para redacción, respaldo y colaboración documental del equipo. |
| **Herramienta de apoyo Google** | **Google Stitch** y **Google Maps Platform** | Recomendadas expresamente por las bases: Stitch para el boceto de interfaz y Google Maps (`Maps SDK for Android`, `Routes API`, `Places API New`, `Elevation API`) para georreferenciación real. |
| **Framework móvil permitido** | **Flutter (Dart, Android `minSdk 24+`)** | Mencionado explícitamente en el stack permitido de las bases (`Flutter/Android`); permite accesibilidad nativa con TalkBack (`Semantics`) y rápida iteración. |
| **Control de versiones permitido** | **GitHub** | Incluido explícitamente en el stack complementario de las bases para alojar el código fuente y `README.md`. |
| **Backend BFF y base de datos complementaria** | **Next.js (TypeScript)** + **Supabase (PostgreSQL + PostGIS + pgvector)** | Capa BFF ligera en Node/TypeScript para ocultar llaves de API y validar esquemas con `zod`, respaldada por PostgreSQL con índices espaciales (`GiST`) y vectoriales (`HNSW`). *(Nota: desplegable en **Google Cloud Run** o **Vercel** según requerimiento final de sede — `[PENDIENTE]`.)* |

#### Paquetes Flutter (Android) e integraciones de servidor
*(Las versiones exactas se fijarán en `pubspec.yaml` y `package.json` al inicializar los repositorios — `[PENDIENTE]`.)*

| Componente | Paquete / Servicio | Rol técnico |
| :--- | :--- | :--- |
| **Mapa en Flutter** | `google_maps_flutter` | Renderiza `GoogleMap` con `mapId`, `AdvancedMarker`, `AssetMapBitmap`, `Polyline` y `ClusterManager` |
| **Cliente Supabase móvil** | `supabase_flutter` | Maneja `signInAnonymously()`, provee el `accessToken` Bearer hacia el BFF y ejecuta `uploadToSignedUrl` |
| **Compresión y limpieza EXIF** | `flutter_image_compress` | Elimina metadatos EXIF (`keepExif: false`) y reduce fotos por debajo de `1.5 MB` antes de enviar |
| **Audio, voz y permisos** | `record`, `audioplayers`, `geolocator`, `permission_handler` | Grabación de notas de voz, reproducción en memoria de audio WAV y permisos en tiempo de ejecución |
| **Cola offline** | `sqflite` + `connectivity_plus` | Guarda borradores locales en SQLite y dispara sincronización al reanudar la app |
| **IA Generativa (BFF)** | Google Gen AI SDK (`@google/genai`) | SDK oficial unificado en TypeScript para visión, clasificación, embeddings, Lenguaje Claro y TTS |
| **Mapas servidor (BFF)** | Google Maps Platform | `Routes API (computeRoutes)`, `Places API (New)` y `Elevation API` mediante `fetch` seguro desde servidor |
| **Estándares abiertos** | Open311 (GeoReport v2), OpenStreetMap, `a11yjson.org`, `GTFS-Pathways`, WCAG 2.2 AA, ISO 24495-1, W3C COGA | Interoperabilidad cívica, accesibilidad móvil y redacción en Lenguaje Claro |

### 4.3 Integración de APIs externas y flujo de Gemini

#### Google Maps Platform (Flutter Android + BFF)
1. **Llave exclusiva de Android (`com.google.android.geo.API_KEY`):** el Maps SDK for Android exige una llave de Google Cloud con facturación habilitada configurada en `AndroidManifest.xml`, restringida por nombre de paquete Android + huella SHA-1.
2. **Reglas del widget `GoogleMap`:** se usa `mapId` para habilitar marcadores avanzados, `AssetMapBitmap` para íconos con forma y color diferenciados, `EagerGestureRecognizer` cuando convive con listas desplazables y solicitud previa de permisos vía `geolocator`/`permission_handler`.
3. **Llave de servidor (`GOOGLE_MAPS_SERVER_KEY`):** restringida por API en el BFF para consultar:
   - **Routes API (`computeRoutes`):** calcula rutas con `travelMode: "WALK"` y el BFF cruza la polilínea con los obstáculos activos en PostGIS.
   - **Places API (New):** solicita `places.accessibilityOptions` mediante `X-Goog-FieldMask` sin espacios para controlar facturación y payload.
   - **Elevation API:** muestrea elevación sobre la ruta para advertir pendientes pronunciadas.
4. **Cumplimiento ToS:** el caché de coordenadas (`lat/lng`) se limita a un máximo de 30 días naturales (solo `place_id` puede persistirse indefinidamente), y ningún dato de Google Maps se utiliza para entrenar modelos de IA.

#### Google Gen AI SDK (`@google/genai`) — Integración por caso de uso
*(Nota: validar los IDs exactos de modelos activos en Google AI Studio con la API key del equipo antes de pasar a producción — `[PENDIENTE]`.)*

| Problema del usuario | Modelo en propuesta | Flujo entre Flutter y el BFF | Controles de seguridad y salida |
| :--- | :--- | :--- | :--- |
| **Incertidumbre sobre accesibilidad física de una calle o entrada** | `gemini-4-hydrogen` | Flutter limpia EXIF, comprime la foto (`< 1.5 MB`) y la envía al BFF; Gemini detecta obstáculos y devuelve recuadros (*bounding boxes* de `0` a `1000`) con evaluación por perfil. | Esquema JSON estricto (`response_schema`). Si la imagen es borrosa u oscura, solicita confirmación al usuario antes de publicar. |
| **Dificultad para llenar formularios de reporte** | `gemini-3.5-flash-lite` y `gemini-embedding-2` | Flutter envía nota de voz o foto al BFF; `gemini-3.5-flash-lite` clasifica según Open311/`a11yjson` y `gemini-embedding-2` genera vector de 768 dimensiones (`output_dimensionality: 768`). | El audio crudo se descarta tras extraer el ticket; no se publican datos personales del ciudadano. |
| **Documentos y avisos públicos complejos** | `gemini-4-hydrogen` y `gemini-3.8-flash-lite-tts` | Flutter sube PDFs grandes por Signed URL o fotos comprimidas al BFF; `gemini-4-hydrogen` resume en tres bloques de Lectura Fácil y `gemini-3.8-flash-lite-tts` devuelve bytes WAV (`responseModalities: ["AUDIO"]`) para `audioplayers`. | Prompt restringido estrictamente al documento cargado; prohíbe inventar fechas, direcciones o teléfonos. |
| **Consultas naturales de rutas y lugares accesibles** | `gemini-4-hydrogen` (Function Calling) | Interpreta la consulta enviada desde Flutter y ejecuta llamadas verificadas a Routes API, Places API (New) y Elevation API en el BFF cruzando con PostGIS. | Prohibido generar lugares, horarios o coordenadas desde la memoria del modelo. |
| **Guía conversacional manos libres (Post-MVP)** | `gemini-3.8-live` | Sesión bidireccional WebSocket (`BidiGenerateContent`) en microservicio Cloud Run (`[PENDIENTE]`). | Aviso explícito de herramienta complementaria; no sustituye bastón blanco ni señalización vial. |

### 4.4 Base de datos y seguridad en Supabase
- **Validación de sesión Bearer en BFF:** cada petición desde Flutter incluye `Authorization: Bearer <accessToken>` emitido por `signInAnonymously()`. El Route Handler verifica la identidad mediante `supabase.auth.getUser(token)`.
- **Acceso a datos desde el BFF:** los endpoints invocan funciones SQL RPC por HTTPS (`supabase.rpc(...)`) para evitar agotamiento de conexiones TCP.
- **Aislamiento de extensiones:** `postgis` y `vector` (`pgvector`) se instalan en el esquema `extensions` (nunca en `public`).
- **Esquema e índices principales:**
  - `barriers`: `id`, `location` (`extensions.geography(POINT, 4326)`), `embedding` (`extensions.vector(768)`), `category`, `severity`, `profile_flags` (`jsonb`), `status`, `confirmations`, `expires_at`, `reporter_id` (`uuid`).
  - `barrier_evidence`: `id`, `barrier_id` (índice B-tree en llave foránea), `reporter_id`, `photo_path`, `summary`, `created_at`.
  - `public_briefs`: `id`, `doc_sha256` (`unique`), `plain_summary` (`jsonb`), `audio_path`, `created_at`.
  - **Índices:** `GiST` parcial en `barriers (location) WHERE status = 'active'`, `HNSW` (`vector_cosine_ops`) en `barriers (embedding)` y `GIN` (`jsonb_path_ops`) en `profile_flags`.
- **Deduplicación atómica vía SQL RPC:** la función `upsert_or_confirm_barrier(...)` (con `SET search_path = ''` y calificación explícita `extensions.st_dwithin(...)` y `OPERATOR(extensions.<=>)`) busca incidentes activos en un radio de **25 metros** con similitud coseno `>= 0.85`; si existe coincidencia suma confirmación y extiende `expires_at`, y si no, inserta el nuevo obstáculo.
- **Políticas RLS y Storage:** todas las tablas en `public` habilitan RLS con políticas `TO authenticated` y `(select auth.uid()) = reporter_id`. Las subidas directas de archivos grandes usan `createSignedUploadUrl` en el BFF y `uploadToSignedUrl` en Flutter.

### 4.5 Configuración local y variables de entorno
- **Instalación y comandos de ejecución:** `[PENDIENTE]`
- **Configuración en Flutter Android (`[PENDIENTE]` valores reales):**
  - `android/app/src/main/AndroidManifest.xml`: `com.google.android.geo.API_KEY` y permisos `ACCESS_FINE_LOCATION`, `CAMERA`, `RECORD_AUDIO`, `INTERNET`.
  - Variables `--dart-define`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BFF_BASE_URL`, `GOOGLE_MAPS_MAP_ID`.
- **Variables de entorno del BFF (`.env.local`, valores `[PENDIENTE]`):**
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `GOOGLE_API_KEY` (o configuración de proyecto Google Cloud según el modo usado), `GOOGLE_MAPS_SERVER_KEY`.

---

## 5. Manual de usuario

VíaLibre funciona en tu teléfono Android sin necesidad de crear cuentas ni recordar contraseñas.

### Paso 1: Instalar y abrir la aplicación en Android
1. Descarga e instala la aplicación **VíaLibre** en tu teléfono Android desde el enlace compartido por el equipo (`[PENDIENTE: enlace de descarga / APK]`).
2. Al abrirla por primera vez, acepta los permisos de **Ubicación**, **Cámara** y **Micrófono** para que pueda mostrarte rutas cercanas, analizar fotos de obstáculos y escuchar tus reportes por voz.

### Paso 2: Elegir tu perfil de movilidad o lectura
1. En la pantalla inicial, selecciona el perfil que mejor se ajuste a tus necesidades: **Silla de ruedas / Carriola**, **Baja visión** o **Lectura clara**.
2. La aplicación guardará esta preferencia automáticamente para tus siguientes consultas.

### Paso 3: Buscar una ruta o lugar accesible
1. Escribe o dicta tu destino en el cuadro de búsqueda (por ejemplo: *"farmacia cercana sin escalones"*).
2. Revisa en el mapa la ruta sugerida y las alertas sobre pendientes pronunciadas u obstáculos reportados por otros vecinos.
3. Toca **Escuchar indicaciones** si prefieres oír el recorrido en voz alta sin mirar la pantalla.

### Paso 4: Reportar un obstáculo en la calle
1. Toca el botón principal **Reportar obstáculo**.
2. Elige **Tomar foto** del problema (como una rampa tapada o una banqueta rota) o **Grabar nota de voz** explicando qué hay en el lugar.
3. Revisa la descripción resumida que aparece en pantalla y toca **Confirmar y publicar**.
4. Si en ese momento no tienes internet, la aplicación guardará tu reporte en el teléfono y lo enviará automáticamente cuando vuelvas a abrirla con señal.

### Paso 5: Entender un aviso público en Lenguaje Claro
1. Entra a la pestaña **Avisos públicos**.
2. Toma una foto al cartel o selecciona el archivo PDF del comunicado desde tu teléfono.
3. Lee los tres recuadros cortos (**Qué pasó**, **A quién afecta** y **Qué hacer hoy**) o toca **Escuchar resumen** para oír la explicación en voz clara.

> **Aviso importante:** VíaLibre es una herramienta de apoyo informativo y orientación. No sustituye el bastón blanco, perros guía ni la señalización vial física.

---

## 6. Accesibilidad e impacto

### Qué hace inclusiva a VíaLibre
- **Accesibilidad nativa en Android:** la interfaz Flutter incorpora etiquetas y jerarquía semántica (`Semantics`) compatibles con **TalkBack**, anuncios dinámicos (`liveRegion`), botones de al menos **48×48 dp** (estándar táctil de Android bajo WCAG 2.2 AA), contraste mínimo **4.5:1** en texto y **3:1** en elementos visuales, adaptación al tamaño de letra del sistema y desactivación automática de animaciones cuando el teléfono tiene activo el modo de movimiento reducido.
- **Sin depender únicamente del color:** cada pin en el mapa combina color, forma geométrica distinta y etiqueta descriptiva.
- **Lectura Fácil y privacidad:** los avisos siguen principios de Lenguaje Claro (**ISO 24495-1**) y accesibilidad cognitiva (**W3C COGA**). Las fotografías eliminan metadatos ocultos de cámara y ubicación privada en el propio teléfono antes de enviarse, y los obstáculos temporales caducan automáticamente si no reciben nuevas confirmaciones.

### Impacto esperado y cómo se evaluará
VíaLibre busca reducir el aislamiento urbano de personas con discapacidad, personas mayores y comunidades con menor cobertura de datos municipales, permitiéndoles desplazarse con mayor autonomía, entender información pública sin intermediarios y participar en la mejora de su ciudad.

El impacto del prototipo se evaluará mediante pruebas prácticas con usuarios antes y durante la presentación del proyecto:
- Medir el tiempo y número de pasos para completar un reporte con foto o voz usando TalkBack en Android frente a un portal municipal tradicional.
- Validar con personas mayores o neurodivergentes la comprensión directa de los resúmenes en Lenguaje Claro y su audio.
- Comprobar que múltiples reportes de un mismo obstáculo en un radio de 25 metros se agrupan correctamente sin duplicar pines y auditar todas las pantallas en Android respecto a contraste, foco de TalkBack y tamaño de áreas táctiles.

---

## 7. Declaración de uso de IA y herramientas de terceros

*(Sección obligatoria conforme a las Bases Generales del Hackatón — Secciones 5 y 8 de la Convocatoria).*

### Uso de Inteligencia Artificial generativa
- **En el producto (VíaLibre):** integración de **Google Gemini** mediante el SDK oficial `@google/genai` para análisis visual de accesibilidad urbana, clasificación y deduplicación semántica de reportes ciudadanos, traducción de avisos públicos a Lenguaje Claro con síntesis de voz (TTS) y consulta asistida de rutas accesibles.
- **En el diseño, boceto y documentación:**
  - **Logotipo conceptual:** generado con **Google Gemini**.
  - **Boceto de pantallas y sistema de diseño:** generado y estructurado con **Google Stitch** ([ver proyecto](https://stitch.google.com/projects/11135309563401328808)).
  - **Documentación (`README.md` y `DOCUMENTACION_TECNICA.md`):** redactada y estructurada con asistencia de **Google Gemini / Antigravity** a partir de la propuesta técnica del equipo y la plantilla oficial del Hackatón, revisada y validada por los integrantes.
  - **Asistencia en código fuente:** `[PENDIENTE: declarar qué módulos o archivos fueron asistidos con IA antes de la entrega final]`.

### Librerías, APIs y recursos de terceros con licencia
- **Frontend móvil:** Flutter SDK (BSD-3-Clause), `google_maps_flutter`, `supabase_flutter`, `flutter_image_compress`, `record`, `audioplayers`, `geolocator`, `permission_handler`, `sqflite`, `connectivity_plus` (`[PENDIENTE: confirmar lista final y licencias tras generar pubspec.yaml]`).
- **Backend y base de datos:** Next.js (MIT), React (MIT), TypeScript (Apache-2.0), `@google/genai` (Apache-2.0), `@supabase/supabase-js` (MIT), `zod` (MIT), PostgreSQL + PostGIS + pgvector.
- **Servicios externos:** Google Maps Platform (`Maps SDK for Android`, `Routes API`, `Places API New`, `Elevation API`) y Supabase.
