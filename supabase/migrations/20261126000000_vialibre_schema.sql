-- ============================================================================
-- VíaLibre: Esquema de Base de Datos Geoespacial y Multimodal (Supabase)
-- Reto 2: Ciudad para todas y todos (ODS 10 y 11)
-- ============================================================================

-- 1. EXTENSIONES EN ESQUEMA AISLADO
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- 2. TABLA PRINCIPAL DE BARRERAS Y OBSTÁCULOS PEATONALES
CREATE TABLE IF NOT EXISTS public.barriers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location extensions.geography(Point, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    embedding extensions.vector(768),
    category TEXT NOT NULL,
    category_code TEXT NOT NULL, -- Compatible con Open311 / a11yjson.org
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    title TEXT NOT NULL,
    description TEXT,
    profile_flags JSONB NOT NULL DEFAULT '{
        "wheelchairBlocked": false,
        "blindHazard": false,
        "strollerBlocked": false,
        "reducedMobilityBlocked": false
    }'::jsonb,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'expired')),
    confirmations INTEGER NOT NULL DEFAULT 1,
    reporter_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days')
);

-- 3. TABLA DE EVIDENCIA CIUDADANA (FOTOS Y AUDIOS)
CREATE TABLE IF NOT EXISTS public.barrier_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barrier_id UUID NOT NULL REFERENCES public.barriers(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('photo', 'audio')),
    media_url TEXT,
    bounding_box JSONB, -- [ymin, xmin, ymax, xmax] coordenadas normalizadas 0-1000
    summary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. TABLA DE AVISOS PÚBLICOS MUNICIPALES EN LENGUAJE CLARO (ISO 24495-1)
CREATE TABLE IF NOT EXISTS public.public_briefs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doc_sha256 TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    plain_summary JSONB NOT NULL, -- { quePaso, aQuienAfecta, queHacerHoy }
    audio_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. ÍNDICES ESPACIALES, VECTORIALES Y JSON
CREATE INDEX IF NOT EXISTS idx_barriers_location
    ON public.barriers USING gist (location)
    WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_barriers_embedding
    ON public.barriers USING hnsw (embedding extensions.vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_barriers_profile_flags
    ON public.barriers USING gin (profile_flags jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_evidence_barrier_id
    ON public.barrier_evidence (barrier_id);

CREATE INDEX IF NOT EXISTS idx_barriers_status_expires
    ON public.barriers (status, expires_at);

-- 6. FUNCIÓN RPC ATÓMICA DE INSERCIÓN Y DEDUPLICACIÓN EN RADIO DE 25 METROS
CREATE OR REPLACE FUNCTION public.upsert_or_confirm_barrier(
    p_reporter_id UUID,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_category TEXT,
    p_category_code TEXT,
    p_severity TEXT,
    p_title TEXT,
    p_description TEXT,
    p_profile_flags JSONB,
    p_embedding extensions.vector(768),
    p_radius_meters DOUBLE PRECISION DEFAULT 25.0,
    p_similarity_threshold DOUBLE PRECISION DEFAULT 0.85
)
RETURNS TABLE (
    id UUID,
    is_duplicate BOOLEAN,
    confirmations INTEGER,
    title TEXT,
    category TEXT,
    severity TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_point extensions.geography;
    v_matched_id UUID;
    v_confirmations INTEGER;
    v_title TEXT;
    v_category TEXT;
    v_severity TEXT;
BEGIN
    -- Crear punto geográfico con SRID 4326 (WGS84)
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

    -- Buscar coincidencia dentro del radio p_radius_meters con similitud coseno >= p_similarity_threshold
    SELECT b.id, b.confirmations, b.title, b.category, b.severity
    INTO v_matched_id, v_confirmations, v_title, v_category, v_severity
    FROM public.barriers b
    WHERE b.status = 'active'
      AND extensions.ST_DWithin(b.location, v_point, p_radius_meters)
      AND (
          b.embedding IS NULL OR p_embedding IS NULL
          OR (1 - (b.embedding OPERATOR(extensions.<=>) p_embedding)) >= p_similarity_threshold
      )
    ORDER BY extensions.ST_Distance(b.location, v_point) ASC
    LIMIT 1;

    IF v_matched_id IS NOT NULL THEN
        -- Barrera coincidente encontrada: sumar confirmación y extender expiración
        UPDATE public.barriers
        SET confirmations = confirmations + 1,
            updated_at = now(),
            expires_at = now() + interval '7 days'
        WHERE public.barriers.id = v_matched_id
        RETURNING public.barriers.confirmations INTO v_confirmations;

        -- Registrar evidencia adicional del ciudadano
        INSERT INTO public.barrier_evidence (barrier_id, reporter_id, media_type, summary)
        VALUES (v_matched_id, p_reporter_id, 'photo', p_description);

        RETURN QUERY SELECT v_matched_id, TRUE, v_confirmations, v_title, v_category, v_severity;
    ELSE
        -- Nueva barrera: insertar registro original
        INSERT INTO public.barriers (
            location, latitude, longitude, embedding, category, category_code,
            severity, title, description, profile_flags, reporter_id
        )
        VALUES (
            v_point, p_lat, p_lng, p_embedding, p_category, p_category_code,
            p_severity, p_title, p_description, p_profile_flags, p_reporter_id
        )
        RETURNING public.barriers.id, public.barriers.confirmations, public.barriers.title, public.barriers.category, public.barriers.severity
        INTO v_matched_id, v_confirmations, v_title, v_category, v_severity;

        INSERT INTO public.barrier_evidence (barrier_id, reporter_id, media_type, summary)
        VALUES (v_matched_id, p_reporter_id, 'photo', p_description);

        RETURN QUERY SELECT v_matched_id, FALSE, v_confirmations, v_title, v_category, v_severity;
    END IF;
END;
$$;

-- 7. FUNCIÓN RPC PARA CONSULTA DE BARRERAS CERCANAS
CREATE OR REPLACE FUNCTION public.get_nearby_barriers(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION DEFAULT 1000.0
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    category TEXT,
    category_code TEXT,
    severity TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    confirmations INTEGER,
    profile_flags JSONB,
    distance_meters DOUBLE PRECISION,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT
        b.id,
        b.title,
        b.category,
        b.category_code,
        b.severity,
        b.latitude,
        b.longitude,
        b.confirmations,
        b.profile_flags,
        extensions.ST_Distance(
            b.location,
            extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography
        ) AS distance_meters,
        b.expires_at,
        b.created_at
    FROM public.barriers b
    WHERE b.status = 'active'
      AND extensions.ST_DWithin(
          b.location,
          extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography,
          p_radius_meters
      )
    ORDER BY distance_meters ASC;
$$;

-- 8. POLÍTICAS DE SEGURIDAD POR FILA (RLS)
ALTER TABLE public.barriers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barrier_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_briefs ENABLE ROW LEVEL SECURITY;

-- Lectura abierta para visualización ciudadana
CREATE POLICY "Lectura pública de barreras activas"
    ON public.barriers FOR SELECT
    TO authenticated, anon
    USING (status = 'active');

CREATE POLICY "Lectura pública de evidencias"
    ON public.barrier_evidence FOR SELECT
    TO authenticated, anon
    USING (true);

CREATE POLICY "Lectura pública de avisos"
    ON public.public_briefs FOR SELECT
    TO authenticated, anon
    USING (true);

-- Inserción permitida a usuarios autenticados (incluye sesiones anónimas con Bearer JWT)
CREATE POLICY "Creación de reportes de barreras"
    ON public.barriers FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

CREATE POLICY "Creación de evidencias"
    ON public.barrier_evidence FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

-- 9. CONFIGURACIÓN DE STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public)
VALUES
    ('evidence', 'evidence', true),
    ('notices', 'notices', true)
ON CONFLICT (id) DO NOTHING;
