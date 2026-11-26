# Backend for Frontend (`bff/`)

API REST en **Next.js App Router (TypeScript + Zod)** desplegada en Vercel, actuando exclusivamente como capa BFF (`src/app/api/...`) sin frontend web duplicado.

## Responsabilidades

1. Verificar el `Authorization: Bearer <accessToken>` emitido por Supabase Auth anónimo (`supabase.auth.getUser(token)`).
2. Ejecutar llamadas al SDK oficial `@google/genai` (visión, clasificación Open311, embeddings de 768 dimensiones, resumen en Lenguaje Claro y TTS WAV).
3. Consultar Google Maps Platform (`Routes API`, `Places API (New)` con `X-Goog-FieldMask` y `Elevation API`) protegiendo `GOOGLE_MAPS_SERVER_KEY`.
4. Invocar funciones SQL RPC en Supabase (`supabase.rpc(...)`) y generar Signed Upload URLs para PDFs/archivos mayores a 2 MB.

## Configuración local

Copia `.env.example` a `.env.local` y completa tus credenciales antes de iniciar el servidor.
