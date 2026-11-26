# Especificación Completa de Backend (`bff/` y `supabase/`) — VíaLibre

Documento de referencia para el desarrollo del **BFF (Next.js App Router + TypeScript + Zod)** y su integración con **Supabase**, **Google Gemini (`@google/genai`)** y **Google Maps Platform**.

> Todos los nombres de tablas, columnas, `CHECK` constraints, buckets y funciones RPC de este documento corresponden exactamente al dump actual de PostgreSQL en Supabase.

---

## 1. Arquitectura y Reglas de Seguridad

1. **Acceso libre sin login obligatorio + login opcional:**
   - La app Flutter inicia sesión automáticamente con `supabase.auth.signInAnonymously()` (rol Postgres `authenticated` con `auth.uid()`).
   - Si el usuario decide iniciar sesión opcionalmente en *Perfil* (para guardar su historial entre dispositivos), seguirá enviando un JWT válido en el mismo formato.
   - **Todo endpoint protegido del BFF** debe validar el header `Authorization: Bearer <access_token>` mediante `supabaseAdmin.auth.getUser(token)` y usar el `user.id` verificado como `p_reporter_id`. **Nunca aceptar `reporter_id` desde el body.**
2. **Escrituras exclusivas desde el BFF:**
   - Los roles `anon` y `authenticated` tienen revocado `INSERT`/`UPDATE`/`DELETE` en `public.barriers`, `public.barrier_events`, `public.public_briefs` y `public.rate_limit_events`.
   - Toda escritura debe pasar por el BFF usando `SUPABASE_SERVICE_ROLE_KEY` e invocando las funciones **SQL RPC** por HTTPS (`supabaseAdmin.rpc(...)`).
3. **Límite de 4.5 MB en Vercel:**
   - Las fotos de reportes llegan comprimidas desde Flutter (`< 1.5 MB`).
   - Los PDFs o archivos `> 2 MB` **no** se envían al Route Handler: primero Flutter pide una *Signed Upload URL* (`POST /api/briefs/upload-url`), sube directo a Supabase Storage (`public-briefs`), y luego llama a `POST /api/briefs/simplify` pasando solo `storagePath`.
4. **Cero datos geográficos inventados por IA:**
   - Nombres de paradas, rutas de Metro/Metrobús/Camión, coordenadas, horarios y opciones de accesibilidad de lugares deben provenir siempre de **Google Maps Platform** o **Supabase**, nunca de memoria del LLM.

---

## 2. Variables de entorno del BFF (`bff/.env.local`)

```env
# Supabase
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key

# Google Gen AI (@google/genai)
GOOGLE_API_KEY=tu-gemini-api-key
# IDs de modelos configurables (validar en Google AI Studio con tu API Key):
GEMINI_VISION_MODEL=gemini-2.5-flash
GEMINI_TEXT_MODEL=gemini-2.5-flash
GEMINI_EMBEDDING_MODEL=gemini-embedding-001
GEMINI_TTS_MODEL=gemini-2.5-flash-preview-tts

# Google Maps Platform (Server Key restringida por API: Routes, Places New, Elevation)
GOOGLE_MAPS_SERVER_KEY=tu-google-maps-server-key
```

---

## 3. Esquema y RPCs ya existentes en Supabase

### 3.1 Tablas y restricciones exactas

1. **`public.barriers`**
   - `category` (`CHECK` estricto):
     - `'blocked_ramp'` | `'broken_sidewalk'` | `'steep_slope'` | `'broken_elevator'` | `'missing_tactile'` | `'missing_curb_cut'` | `'audible_signal_issue'` | `'other'`
   - `title`: `text` (3 a 140 caracteres)
   - `description`: `text` (3 a 2000 caracteres)
   - `severity`: `smallint` (`1` a `5`)
   - `confidence_score`: `numeric(4,3)` (`0` a `1`)
   - `profile_flags`: `jsonb` — ejemplo: `{"wheelchair": true, "low_vision": true, "stroller": true, "plain_language": false}`
   - `bounding_boxes`: `jsonb` — arreglo de detecciones `[{"label": "...", "box_2d": [ymin, xmin, ymax, xmax]}]` (escala `0..1000`)
   - `status` (`CHECK`): `'unconfirmed'` | `'active'` | `'in_progress'` | `'resolved'` | `'expired'` | `'hidden'`
   - `open311_status` (generada): `'closed'` si `status in ('resolved', 'expired')`, si no `'open'`
   - `location`: `extensions.geography(Point, 4326)`
   - `embedding`: `extensions.vector(768)`
2. **`public.barrier_events`**
   - `idempotency_key`: `uuid unique not null` (para reintentos offline de Flutter)
   - `event_type`: `'report'` | `'confirm'` | `'resolve'` | `'reopen'` | `'expire'`
   - `input_mode`: `'photo'` | `'voice'` | `'text'` | `'system'`
3. **`public.public_briefs`**
   - `doc_sha256`: `text unique not null` (caché para evitar reprocesar el mismo PDF/foto)
   - `plain_summary`: `jsonb not null`
   - `audio_path`: `text` (ruta dentro del bucket `public-briefs`)
4. **Buckets de Storage (privados):**
   - `barrier-evidence` (límite `5 MB`, MIME: `image/jpeg`, `image/png`, `image/webp`)
   - `public-briefs` (límite `10 MB`, MIME: `application/pdf`, `image/jpeg`, `image/png`, `image/webp`, `audio/wav`)
   - *Regla RLS de Storage:* la carpeta raíz del objeto debe coincidir con el `auth.uid()` del usuario: `<uid>/<archivo>`.

### 3.2 Funciones RPC que el BFF debe invocar (`supabaseAdmin.rpc(...)`)

| RPC | Quién puede llamarla | Parámetros exactos y propósito |
| :--- | :--- | :--- |
| `check_and_record_rate_limit` | `service_role` | `(p_actor_hash text, p_action text, p_window_seconds int DEFAULT 60, p_max_requests int DEFAULT 12) -> boolean`. Llamar antes de endpoints costosos de Gemini/Maps. Usar `sha256(userId + salt)` en `p_actor_hash`. |
| `upsert_or_confirm_barrier` | `service_role` | `(p_reporter_id uuid, p_idempotency_key uuid, p_lat float8, p_lng float8, p_category text, p_title text, p_description text, p_severity int2, p_confidence_score numeric, p_profile_flags jsonb, p_bounding_boxes jsonb, p_accuracy_meters numeric, p_input_mode text, p_photo_path text, p_embedding vector(768), p_ttl_hours int DEFAULT 168, p_radius_meters float8 DEFAULT 25.0, p_similarity_threshold float8 DEFAULT 0.85)`. Deduplica en 25 m + similitud coseno >= 0.85 e inserta o confirma atómicamente. |
| `record_barrier_resolution` | `service_role` | `(p_barrier_id bigint, p_reporter_id uuid, p_idempotency_key uuid, p_note text, p_photo_path text, p_resolution_threshold int DEFAULT 2)`. Registra voto de "ya fue reparado"; al alcanzar el umbral cambia `status = 'resolved'`. |
| `find_barriers_along_route` | `anon`, `authenticated`, `service_role` | `(p_route_wkt text, p_buffer_meters float8 DEFAULT 20.0, p_profile text DEFAULT NULL)`. Recibe `LINESTRING(lng1 lat1, lng2 lat2, ...)` y devuelve barreras activas en el corredor de la ruta. |
| `find_nearby_barriers` | `anon`, `authenticated`, `service_role` | `(p_lat float8, p_lng float8, p_radius_meters float8 DEFAULT 500.0)`. Devuelve barreras activas cercanas ordenadas por distancia. |

> **Importante para Tiempo Real (Supabase Realtime):**
> Asegúrate de aplicar la migración `20261126210000_enable_realtime_barriers.sql` (`alter publication supabase_realtime add table public.barriers;`). Con eso, cada `INSERT`/`UPDATE` que haga `upsert_or_confirm_barrier` o `record_barrier_resolution` se reflejará inmediatamente en el mapa de todos los celulares conectados.

---

## 4. Contrato de Endpoints REST (`bff/src/app/api/`)

Todos los endpoints (excepto `GET /api/health`) requieren header:
`Authorization: Bearer <supabase_jwt>`

---

### 4.1 `GET /api/health`
- **Público** (sin auth).
- **Respuesta `200`:** `{ "ok": true, "service": "vialibre-bff", "timestamp": "ISO-8601" }`.

---

### 4.2 `POST /api/routes/accessible`
Calcula **todas las opciones de ruta** (caminando y transporte público: Metro, Metrobús, Camión/Autobús, Tren Ligero), mide pendientes, cruza con barreras activas de PostGIS y, si se solicita, genera la **Guía "Primera Vez en Transporte Público"** con Gemini + audio.

- **Request JSON (Zod):**
```json
{
  "origin": { "lat": 19.4326, "lng": -99.1332 },
  "destinationQuery": "Clínica San Rafael",
  "destination": { "lat": 19.4362, "lng": -99.1546 },
  "profile": "wheelchair",
  "modes": ["WALK", "TRANSIT"],
  "includeFirstTimerGuide": true,
  "includeAudio": false
}
```
*(Si viene `destinationQuery` sin `destination`, el BFF primero usa `Places API (New)` `searchText` para resolver coordenadas reales del lugar, nunca desde memoria del LLM).*

- **Lógica interna en el BFF:**
  1. Verificar JWT + `check_and_record_rate_limit(actorHash, "routes_accessible", 60, 20)`.
  2. Llamar a **Google Routes API v2** (`https://routes.googleapis.com/directions/v2:computeRoutes`):
     - Una llamada para `travelMode: "WALK"` (`computeAlternativeRoutes: true`).
     - Una llamada para `travelMode: "TRANSIT"` (`computeAlternativeRoutes: true`, `languageCode: "es-419"`, solicitando `legs.steps.transitDetails`, `legs.steps.travelMode`, `polyline.encodedPolyline` vía `X-Goog-FieldMask` sin espacios).
  3. Para tramos peatonales:
     - Muestrear puntos de la ruta en **Elevation API** para calcular la pendiente máxima (`maxSlopePercent`) y advertir si excede el umbral del perfil (ej. > 8 % para silla de ruedas).
     - Construir `LINESTRING(lng lat, ...)` en WKT e invocar `supabaseAdmin.rpc("find_barriers_along_route", { p_route_wkt, p_buffer_meters: 25, p_profile })`.
  4. **Guía "Primera Vez en Transporte Público" (si `includeFirstTimerGuide: true` y hay rutas `TRANSIT`):**
     - Pasar a Gemini (`GEMINI_TEXT_MODEL`, `response_schema` JSON fijo) **exclusivamente los pasos reales devueltos por `Routes API`** (línea, agencia, parada de subida, parada de bajada, número de paradas, transbordos y tramos a pie).
     - Prompt estricto: explicar en **Lenguaje Claro** para alguien que nunca ha usado transporte público cómo abordar paso a paso (dónde ubicarse, qué dirección/letrero revisar, qué señales de accesibilidad buscar como elevador/rampa/asiento preferente y cómo avisar para bajar). Prohibido inventar tarifas, horarios no recibidos o nombres de paradas distintos a los de `Routes API`.
     - Si `includeAudio: true`, sintetizar el resumen paso a paso con `GEMINI_TTS_MODEL` (`responseModalities: ["AUDIO"]`) y devolver `audioBase64` (WAV).

- **Response `200`:**
```json
{
  "resolvedDestination": {
    "placeId": "ChIJ...",
    "name": "Clínica San Rafael",
    "lat": 19.4362,
    "lng": -99.1546,
    "accessibilityOptions": {
      "wheelchairAccessibleEntrance": true,
      "wheelchairAccessibleRestroom": true
    }
  },
  "routes": [
    {
      "id": "route-transit-0",
      "mode": "TRANSIT",
      "summaryLabel": "Metrobús Línea 1 + caminata (18 min)",
      "durationSeconds": 1080,
      "distanceMeters": 3400,
      "maxSlopePercent": 3.2,
      "encodedPolyline": "...",
      "barriersOnRoute": [],
      "steps": [
        {
          "stepMode": "WALK",
          "instruction": "Camina 240 m hacia estación Reforma",
          "distanceMeters": 240,
          "durationSeconds": 210
        },
        {
          "stepMode": "TRANSIT",
          "vehicleType": "BUS",
          "lineName": "Línea 1",
          "headsign": "Indios Verdes",
          "departureStop": "Reforma",
          "arrivalStop": "Plaza de la República",
          "numStops": 2
        }
      ],
      "firstTimerGuide": {
        "checklistBeforeBoarding": [
          "Ten lista tu tarjeta o forma de pago local.",
          "Verifica el letrero con dirección Indios Verdes."
        ],
        "stepByStep": [
          {
            "stepNumber": 1,
            "title": "Camina a la estación Reforma",
            "plainInstruction": "Avanza 240 metros hasta la entrada de la estación.",
            "accessibilityTip": "Busca el acceso por rampa o elevador señalizado."
          }
        ],
        "spokenSummaryText": "Primero camina 240 metros hacia la estación Reforma..."
      },
      "audioBase64": null
    }
  ]
}
```

---

### 4.3 `POST /api/places/nearby`
Busca lugares cercanos con información de accesibilidad real (rampas de entrada, baños adaptados, estacionamiento, estaciones de Metro/Metrobús/hospitales/oficinas) y los cruza con barreras reportadas cerca.

- **Request JSON:**
```json
{
  "lat": 19.4326,
  "lng": -99.1332,
  "radiusMeters": 800,
  "query": "farmacia o clínica",
  "onlyWheelchairAccessible": false
}
```
- **Lógica interna:**
  1. Llamar a **Places API (New)** (`places:searchText` o `places:searchNearby`) con header `X-Goog-FieldMask` incluyendo `places.id,places.displayName,places.formattedAddress,places.location,places.types,places.accessibilityOptions`.
  2. Invocar `supabaseAdmin.rpc("find_nearby_barriers", { p_lat, p_lng, p_radius_meters })`.
  3. Devolver los lugares combinados con `accessibilityOptions` y las barreras cercanas para mostrar en el mapa.
  - *Nota ToS:* No cachear `lat/lng` de Places más de 30 días (solo `placeId`).

---

### 4.4 `POST /api/barriers/upload-url`
Genera URL firmada para subir evidencia fotográfica al bucket privado `barrier-evidence`.

- **Request JSON:** `{ "mimeType": "image/jpeg", "fileExt": "jpg" }`
- **Lógica interna:**
  1. Construir `objectPath = "${user.id}/${randomUUID()}.${fileExt}"`.
  2. Llamar `supabaseAdmin.storage.from("barrier-evidence").createSignedUploadUrl(objectPath)`.
- **Response `200`:** `{ "bucket": "barrier-evidence", "path": "<objectPath>", "signedUrl": "...", "token": "..." }`.

---

### 4.5 `POST /api/barriers/analyze`
Analiza una fotografía antes de publicar el reporte (detecta si hay obstáculos, marca coordenadas y avisa si la foto es oscura/borrosa). **No escribe en base de datos.**

- **Request JSON:**
```json
{
  "imageBase64": "...",
  "mimeType": "image/jpeg",
  "profile": "wheelchair"
}
```
*(El tamaño de `imageBase64` tras comprimir en Flutter debe mantenerse `< 1.5 MB` para cumplir el límite de Vercel).*

- **Lógica interna (Gemini Vision con `response_schema` fijo):**
  - `isImageClear` (`boolean`) y `ambiguityReason` (`string | null`)
  - `category` (una de las 8 categorías del `CHECK` de `public.barriers`)
  - `title` (<= 140 chars), `description` (Lenguaje Claro)
  - `severity` (`1..5`), `confidenceScore` (`0..1`)
  - `profileFlags`: `{ "wheelchair": bool, "low_vision": bool, "stroller": bool, "plain_language": bool }`
  - `boundingBoxes`: `[{ "label": string, "box_2d": [ymin, xmin, ymax, xmax] }]` (`0..1000`)

---

### 4.6 `POST /api/barriers/report`
Procesa el reporte ciudadano final (desde foto, nota de voz o texto), genera embedding de 768 dimensiones y ejecuta la deduplicación atómica en Supabase.

- **Request JSON:**
```json
{
  "idempotencyKey": "uuid-v4-generado-en-flutter",
  "lat": 19.4326,
  "lng": -99.1332,
  "accuracyMeters": 6.5,
  "inputMode": "photo",
  "photoPath": "<userId>/<uuid>.jpg",
  "audioBase64": null,
  "audioMimeType": null,
  "textNote": "Rampa tapada por puesto ambulante",
  "preAnalyzed": {
    "category": "blocked_ramp",
    "title": "Rampa bloqueada en esquina",
    "description": "...",
    "severity": 4,
    "confidenceScore": 0.92,
    "profileFlags": { "wheelchair": true, "stroller": true },
    "boundingBoxes": [{ "label": "Rampa bloqueada", "box_2d": [200, 150, 780, 820] }]
  }
}
```
- **Lógica interna:**
  1. Verificar JWT + `check_and_record_rate_limit(actorHash, "barrier_report", 60, 10)`.
  2. Si `inputMode === "voice"` (o no viene `preAnalyzed`), enviar el audio/texto/foto a `GEMINI_TEXT_MODEL` para transcribir, redactar en Lenguaje Claro (sin PII) y clasificar en una de las 8 categorías exactas de `public.barriers`. **Descartar el audio original de memoria inmediatamente** (no guardarlo en Storage).
  3. Generar vector de **768 dimensiones** con `GEMINI_EMBEDDING_MODEL` (`outputDimensionality: 768`).
  4. Llamar a `supabaseAdmin.rpc("upsert_or_confirm_barrier", { ... })`.
- **Response `200`:**
```json
{
  "barrierId": 15,
  "eventId": 42,
  "actionTaken": "created_new",
  "confirmationsCount": 1,
  "status": "active",
  "isPublic": true
}
```

---

### 4.7 `POST /api/barriers/resolve`
Permite que la comunidad marque un obstáculo o rampa como ya despejado/reparado.

- **Request JSON:**
```json
{
  "barrierId": 15,
  "idempotencyKey": "uuid-v4",
  "note": "Ya quitaron el obstáculo de la rampa",
  "photoPath": null
}
```
- **Lógica interna:** invocar `supabaseAdmin.rpc("record_barrier_resolution", { p_barrier_id, p_reporter_id: user.id, p_idempotency_key, p_note, p_photo_path, p_resolution_threshold: 2 })`.
- **Response `200`:** `{ "barrierId": 15, "status": "resolved", "resolutionVotes": 2 }`.

---

### 4.8 `POST /api/briefs/upload-url`
Genera URL firmada para subir PDFs o imágenes de avisos públicos al bucket privado `public-briefs`.

- **Request JSON:** `{ "mimeType": "application/pdf", "fileExt": "pdf" }`
- **Lógica interna:** `objectPath = "${user.id}/${randomUUID()}.${fileExt}"` -> `createSignedUploadUrl(objectPath)`.

---

### 4.9 `POST /api/briefs/simplify`
Traduce un aviso municipal (PDF en Storage o imagen comprimida) a **Lenguaje Claro** en 3 bloques y genera audio WAV en español.

- **Request JSON:**
```json
{
  "storagePath": "<userId>/<uuid>.pdf",
  "mimeType": "application/pdf",
  "imageBase64": null,
  "generateAudio": true
}
```
- **Lógica interna:**
  1. Obtener los bytes del documento (descargando de `public-briefs` vía `supabaseAdmin.storage` si viene `storagePath`, o decodificando `imageBase64` si es foto pequeña).
  2. Calcular `docSha256 = sha256(bytes)`. Consultar `public.public_briefs` por `doc_sha256`: **si ya existe en caché**, generar una *Signed Download URL* para `audio_path` y devolver inmediatamente sin gastar tokens de Gemini.
  3. Si no existe en caché:
     - Verificar `check_and_record_rate_limit(actorHash, "brief_simplify", 60, 10)`.
     - Enviar el documento a `GEMINI_TEXT_MODEL` con `response_schema` estricto y prompt restringido al contenido del archivo (prohibido inventar fechas, direcciones, teléfonos o rutas):
       ```json
       {
         "issuer": "Movilidad Urbana",
         "estimatedDuration": "Hoy hasta las 20:00 h",
         "whatHappened": "Cerraron la calle Benito Juárez...",
         "whoIsAffected": "Personas que viajan en la Ruta 4 hacia el centro.",
         "whatToDoToday": "Toma la parada Norte a 100 metros."
       }
       ```
     - Si `generateAudio`: generar audio WAV en español con `GEMINI_TTS_MODEL` (`responseModalities: ["AUDIO"]`), subir el `.wav` a `public-briefs/${user.id}/${docSha256}.wav` e insertar la fila en `public.public_briefs`.
     - Devolver el resumen + `audioSignedUrl` o `audioBase64`.


---

### 4.10 `POST /api/assistant/chat` *(Nuevo — Copiloto Multimodal VíaLibre)*
Asistente conversacional personalizado al perfil accesible para resolver dudas de transporte público (*Primera vez*), rutas sin escalones o reportes mediante texto o nota de voz.

- **Request JSON:**
```json
{
  "message": "¿Cómo subo al Metrobús en silla de ruedas?",
  "audioBase64": null,
  "audioMimeType": null,
  "profile": "wheelchair",
  "location": { "lat": 19.4326, "lng": -99.1332 },
  "generateAudio": true
}
```
- **Response `200`:**
```json
{
  "replyText": "El Metrobús tiene acceso a nivel de banqueta. Espera frente al símbolo azul...",
  "suggestedAction": {
    "type": "open_first_timer_guide",
    "label": "Abrir guía paso a paso",
    "query": null
  },
  "quickFollowUps": ["¿Dónde está la estación más cercana?"],
  "audioSignedUrl": null
}
```
*(Valores válidos para `suggestedAction.type`: `open_map_route`, `open_first_timer_guide`, `open_report`, `open_briefs`, `none`.)*

---

### 4.11 `POST /api/places/assess-photo` *(Nuevo — Evaluador Visual "¿Puedo entrar aquí?")*
Evalúa la accesibilidad de un acceso, entrada o parada a partir de una fotografía comprimida sin metadatos EXIF.

- **Request JSON:** `{ "imageBase64": "<base64>", "mimeType": "image/jpeg", "profile": "wheelchair" }`
- **Response `200`:**
```json
{
  "assessment": {
    "verdict": "caution",
    "verdictLabel": "Acceso con precaución",
    "summary": "Hay rampa lateral pero el ancho de puerta es estrecho (~78 cm).",
    "featuresDetected": ["Rampa peatonal", "Sin escalones", "Puerta estrecha"],
    "recommendation": "Solicita apertura de doble hoja en recepción.",
    "boundingBoxes": [{ "label": "Rampa", "box_2d": [420, 120, 880, 620] }]
  }
}
```
- **Extensiones recomendadas en endpoints existentes:**
  - En `POST /api/barriers/analyze`: devolver `"dispatchAgency": "Obras Públicas / Movilidad / Mantenimiento Metro"` para mostrar canalización inteligente.
  - En `POST /api/routes/accessible`: incluir `"recommendationReason"` en cada candidato explicando en Lenguaje Claro por qué conviene según el perfil.
