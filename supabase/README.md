# Base de datos y Storage (`supabase/`)

Configuración de PostgreSQL en Supabase para **VíaLibre**:

- Extensiones `postgis` y `vector` (`pgvector`) aisladas en el esquema `extensions`.
- Tablas principales en `public`: `barriers`, `barrier_evidence` y `public_briefs`.
- Índices: `GiST` parcial en `barriers(location)`, `HNSW (vector_cosine_ops)` en `barriers(embedding)` y `GIN (jsonb_path_ops)` en `profile_flags`.
- Función RPC atómica `upsert_or_confirm_barrier(...)` para deduplicación en un radio de 25 metros con similitud coseno `>= 0.85`.
- Políticas RLS activas (`TO authenticated` con `(select auth.uid()) = reporter_id`) compatibles con `signInAnonymously()`.
