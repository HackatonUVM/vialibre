-- Migration 2: Core tables, constraints, triggers, and performance indexes

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- 1. Active & historical urban accessibility barriers
create table public.barriers (
  id bigint generated always as identity primary key,
  location extensions.geography(point, 4326) not null,
  embedding extensions.vector(768),
  category text not null check (
    category in (
      'blocked_ramp',
      'broken_sidewalk',
      'steep_slope',
      'broken_elevator',
      'missing_tactile',
      'missing_curb_cut',
      'audible_signal_issue',
      'other'
    )
  ),
  title text not null check (char_length(title) between 3 and 140),
  description text not null check (char_length(description) between 3 and 2000),
  severity smallint not null check (severity between 1 and 5),
  confidence_score numeric(4, 3) not null default 0.800 check (confidence_score >= 0 and confidence_score <= 1),
  profile_flags jsonb not null default '{}'::jsonb,
  bounding_boxes jsonb not null default '[]'::jsonb,
  accuracy_meters numeric(6, 2) check (accuracy_meters is null or accuracy_meters >= 0),
  status text not null default 'unconfirmed' check (
    status in ('unconfirmed', 'active', 'in_progress', 'resolved', 'expired', 'hidden')
  ),
  open311_status text generated always as (
    case
      when status in ('resolved', 'expired') then 'closed'
      else 'open'
    end
  ) stored,
  is_public boolean not null default false,
  confirmations_count integer not null default 1 check (confirmations_count >= 1),
  resolution_votes integer not null default 0 check (resolution_votes >= 0),
  source_type text not null default 'citizen' check (
    source_type in ('citizen', 'open311', 'osm', 'municipal')
  ),
  external_request_id text,
  sync_state text not null default 'none' check (
    sync_state in ('none', 'pending', 'synced', 'failed')
  ),
  reporter_id uuid not null,
  last_confirmed_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger barriers_set_updated_at
  before update on public.barriers
  for each row
  execute function public.set_updated_at();

-- 2. Immutable event & evidence log (supports offline queue idempotency + staleness decay)
create table public.barrier_events (
  id bigint generated always as identity primary key,
  barrier_id bigint not null references public.barriers(id) on delete cascade,
  reporter_id uuid not null,
  idempotency_key uuid not null unique,
  event_type text not null check (
    event_type in ('report', 'confirm', 'resolve', 'reopen', 'expire')
  ),
  input_mode text not null default 'photo' check (
    input_mode in ('photo', 'voice', 'text', 'system')
  ),
  photo_path text,
  ai_summary text,
  ai_confidence numeric(4, 3) check (ai_confidence is null or (ai_confidence >= 0 and ai_confidence <= 1)),
  bounding_boxes jsonb not null default '[]'::jsonb,
  accuracy_meters numeric(6, 2) check (accuracy_meters is null or accuracy_meters >= 0),
  created_at timestamptz not null default now()
);

-- 3. Plain-language municipal briefs cache & TTS WAV metadata
create table public.public_briefs (
  id bigint generated always as identity primary key,
  doc_sha256 text not null unique,
  source_mime_type text not null,
  source_path text,
  issuer text,
  estimated_duration text,
  plain_summary jsonb not null,
  audio_path text,
  audio_duration_seconds integer check (audio_duration_seconds is null or audio_duration_seconds >= 0),
  reporter_id uuid,
  is_public boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

-- 4. Privacy-preserving sliding-window rate limits (hashed_ip / reporter_id, never raw IPs)
create table public.rate_limit_events (
  id bigint generated always as identity primary key,
  actor_hash text not null,
  action text not null,
  created_at timestamptz not null default now()
);

-- Spatial, vector, JSONB, partial, and FK indexes
create index barriers_active_location_gist_idx
  on public.barriers using gist (location)
  where is_public = true and status = 'active';

create index barriers_embedding_hnsw_idx
  on public.barriers using hnsw (embedding extensions.vector_cosine_ops)
  where embedding is not null;

create index barriers_profile_flags_gin_idx
  on public.barriers using gin (profile_flags jsonb_path_ops);

create index barriers_active_expires_at_idx
  on public.barriers (expires_at)
  where status = 'active' and expires_at is not null;

create index barriers_reporter_id_idx
  on public.barriers (reporter_id);

create index barrier_events_barrier_id_idx
  on public.barrier_events (barrier_id);

create index barrier_events_reporter_id_idx
  on public.barrier_events (reporter_id);

create index public_briefs_reporter_id_idx
  on public.public_briefs (reporter_id)
  where reporter_id is not null;

create index public_briefs_active_expires_idx
  on public.public_briefs (expires_at)
  where is_public = true;

create index rate_limit_events_lookup_idx
  on public.rate_limit_events (actor_hash, action, created_at desc);
