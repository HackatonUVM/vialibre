-- Migration 3: Row Level Security (BFF-only writes), Storage buckets, and atomic PostGIS/pgvector RPCs

-- 1. Enable RLS on every table in public
alter table public.barriers enable row level security;
alter table public.barrier_events enable row level security;
alter table public.public_briefs enable row level security;
alter table public.rate_limit_events enable row level security;

-- Least-privilege table grants (writes exclusively via Next.js BFF using service_role)
revoke all on public.barriers from public, anon, authenticated;
revoke all on public.barrier_events from public, anon, authenticated;
revoke all on public.public_briefs from public, anon, authenticated;
revoke all on public.rate_limit_events from public, anon, authenticated;

grant select on public.barriers to anon, authenticated;
grant select on public.public_briefs to anon, authenticated;
grant select on public.barrier_events to authenticated;

-- 2. RLS Policies
create policy barriers_public_active_select
  on public.barriers
  for select
  to anon, authenticated
  using (
    is_public = true
    and status = 'active'
    and (expires_at is null or expires_at > now())
  );

create policy barriers_own_select
  on public.barriers
  for select
  to authenticated
  using ((select auth.uid()) = reporter_id);

create policy barrier_events_own_select
  on public.barrier_events
  for select
  to authenticated
  using ((select auth.uid()) = reporter_id);

create policy public_briefs_public_select
  on public.public_briefs
  for select
  to anon, authenticated
  using (
    is_public = true
    and (expires_at is null or expires_at > now())
  );

create policy public_briefs_own_select
  on public.public_briefs
  for select
  to authenticated
  using ((select auth.uid()) = reporter_id);

-- 3. Private Storage buckets
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'barrier-evidence',
    'barrier-evidence',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'public-briefs',
    'public-briefs',
    false,
    10485760,
    array['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'audio/wav']
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy storage_barrier_evidence_own_insert
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'barrier-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_barrier_evidence_own_select
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'barrier-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_barrier_evidence_own_update
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'barrier-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'barrier-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_public_briefs_own_insert
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'public-briefs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_public_briefs_own_select
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'public-briefs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_public_briefs_own_update
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'public-briefs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'public-briefs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 4. Atomic BFF-only RPC: Idempotent spatial + semantic deduplication (25 m + cosine >= 0.85)
create or replace function public.upsert_or_confirm_barrier(
  p_reporter_id uuid,
  p_idempotency_key uuid,
  p_lat double precision,
  p_lng double precision,
  p_category text,
  p_title text,
  p_description text,
  p_severity smallint,
  p_confidence_score numeric,
  p_profile_flags jsonb default '{}'::jsonb,
  p_bounding_boxes jsonb default '[]'::jsonb,
  p_accuracy_meters numeric default null,
  p_input_mode text default 'photo',
  p_photo_path text default null,
  p_embedding extensions.vector(768) default null,
  p_ttl_hours integer default 168,
  p_radius_meters double precision default 25.0,
  p_similarity_threshold double precision default 0.85
)
returns table (
  barrier_id bigint,
  event_id bigint,
  action_taken text,
  confirmations_count integer,
  status text,
  is_public boolean
)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_existing_event public.barrier_events%rowtype;
  v_existing_barrier public.barriers%rowtype;
  v_point extensions.geography;
  v_matched_barrier_id bigint;
  v_new_barrier_id bigint;
  v_new_event_id bigint;
  v_next_expires timestamptz;
  v_promote_public boolean;
begin
  select *
  into v_existing_event
  from public.barrier_events
  where idempotency_key = p_idempotency_key;

  if found then
    select *
    into v_existing_barrier
    from public.barriers
    where id = v_existing_event.barrier_id;

    return query
    select
      v_existing_barrier.id,
      v_existing_event.id,
      'idempotent_replay'::text,
      v_existing_barrier.confirmations_count,
      v_existing_barrier.status,
      v_existing_barrier.is_public;
    return;
  end if;

  v_point := extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography;
  v_next_expires := case
    when p_ttl_hours is not null and p_ttl_hours > 0 then now() + make_interval(hours => p_ttl_hours)
    else null
  end;
  v_promote_public := coalesce(p_confidence_score, 0) >= 0.70;

  select b.id
  into v_matched_barrier_id
  from public.barriers b
  where b.status in ('unconfirmed', 'active', 'in_progress')
    and (b.expires_at is null or b.expires_at > now())
    and extensions.st_dwithin(b.location, v_point, p_radius_meters)
    and (
      (
        p_embedding is not null
        and b.embedding is not null
        and (1 - (b.embedding operator(extensions.<=>) p_embedding)) >= p_similarity_threshold
      )
      or (
        (p_embedding is null or b.embedding is null)
        and b.category = p_category
      )
    )
  order by
    case
      when p_embedding is not null and b.embedding is not null
        then b.embedding operator(extensions.<=>) p_embedding
      else 0
    end asc,
    extensions.st_distance(b.location, v_point) asc
  limit 1
  for update;

  if v_matched_barrier_id is not null then
    update public.barriers b
    set
      confirmations_count = b.confirmations_count + 1,
      severity = greatest(b.severity, p_severity),
      confidence_score = greatest(b.confidence_score, p_confidence_score),
      profile_flags = b.profile_flags || coalesce(p_profile_flags, '{}'::jsonb),
      status = case when b.status = 'unconfirmed' then 'active' else b.status end,
      is_public = true,
      last_confirmed_at = now(),
      expires_at = greatest(coalesce(b.expires_at, v_next_expires), coalesce(v_next_expires, b.expires_at))
    where b.id = v_matched_barrier_id
    returning b.id, b.confirmations_count, b.status, b.is_public
    into v_new_barrier_id, confirmations_count, status, is_public;

    insert into public.barrier_events (
      barrier_id, reporter_id, idempotency_key, event_type, input_mode,
      photo_path, ai_summary, ai_confidence, bounding_boxes, accuracy_meters
    )
    values (
      v_new_barrier_id, p_reporter_id, p_idempotency_key, 'confirm', p_input_mode,
      p_photo_path, p_description, p_confidence_score, coalesce(p_bounding_boxes, '[]'::jsonb), p_accuracy_meters
    )
    returning id into v_new_event_id;

    return query
    select v_new_barrier_id, v_new_event_id, 'confirmed_existing'::text, confirmations_count, status, is_public;
    return;
  end if;

  insert into public.barriers (
    location, embedding, category, title, description, severity, confidence_score,
    profile_flags, bounding_boxes, accuracy_meters, status, is_public, reporter_id, expires_at
  )
  values (
    v_point, p_embedding, p_category, p_title, p_description, p_severity, p_confidence_score,
    coalesce(p_profile_flags, '{}'::jsonb), coalesce(p_bounding_boxes, '[]'::jsonb), p_accuracy_meters,
    case when v_promote_public then 'active' else 'unconfirmed' end,
    v_promote_public, p_reporter_id, v_next_expires
  )
  returning id, public.barriers.confirmations_count, public.barriers.status, public.barriers.is_public
  into v_new_barrier_id, confirmations_count, status, is_public;

  insert into public.barrier_events (
    barrier_id, reporter_id, idempotency_key, event_type, input_mode,
    photo_path, ai_summary, ai_confidence, bounding_boxes, accuracy_meters
  )
  values (
    v_new_barrier_id, p_reporter_id, p_idempotency_key, 'report', p_input_mode,
    p_photo_path, p_description, p_confidence_score, coalesce(p_bounding_boxes, '[]'::jsonb), p_accuracy_meters
  )
  returning id into v_new_event_id;

  return query
  select v_new_barrier_id, v_new_event_id, 'created_new'::text, confirmations_count, status, is_public;
end;
$$;

revoke all on function public.upsert_or_confirm_barrier(
  uuid, uuid, double precision, double precision, text, text, text, smallint, numeric,
  jsonb, jsonb, numeric, text, text, extensions.vector, integer, double precision, double precision
) from public, anon, authenticated;

grant execute on function public.upsert_or_confirm_barrier(
  uuid, uuid, double precision, double precision, text, text, text, smallint, numeric,
  jsonb, jsonb, numeric, text, text, extensions.vector, integer, double precision, double precision
) to service_role;

-- 5. Atomic BFF-only RPC: Community resolution vote
create or replace function public.record_barrier_resolution(
  p_barrier_id bigint,
  p_reporter_id uuid,
  p_idempotency_key uuid,
  p_note text default null,
  p_photo_path text default null,
  p_resolution_threshold integer default 2
)
returns table (
  barrier_id bigint,
  status text,
  resolution_votes integer
)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_existing_event public.barrier_events%rowtype;
  v_barrier public.barriers%rowtype;
begin
  select * into v_existing_event
  from public.barrier_events
  where idempotency_key = p_idempotency_key;

  if found then
    select * into v_barrier from public.barriers where id = v_existing_event.barrier_id;
    return query select v_barrier.id, v_barrier.status, v_barrier.resolution_votes;
    return;
  end if;

  update public.barriers b
  set
    resolution_votes = b.resolution_votes + 1,
    status = case
      when (b.resolution_votes + 1) >= p_resolution_threshold then 'resolved'
      else b.status
    end
  where b.id = p_barrier_id
  returning * into v_barrier;

  if not found then
    raise exception 'Barrier % not found', p_barrier_id;
  end if;

  insert into public.barrier_events (
    barrier_id, reporter_id, idempotency_key, event_type, input_mode, photo_path, ai_summary
  )
  values (
    p_barrier_id, p_reporter_id, p_idempotency_key, 'resolve',
    case when p_photo_path is not null then 'photo' else 'text' end,
    p_photo_path, p_note
  );

  return query select v_barrier.id, v_barrier.status, v_barrier.resolution_votes;
end;
$$;

revoke all on function public.record_barrier_resolution(
  bigint, uuid, uuid, text, text, integer
) from public, anon, authenticated;

grant execute on function public.record_barrier_resolution(
  bigint, uuid, uuid, text, text, integer
) to service_role;

-- 6. Atomic BFF-only RPC: Sliding-window rate limiter with hashed actor
create or replace function public.check_and_record_rate_limit(
  p_actor_hash text,
  p_action text,
  p_window_seconds integer default 60,
  p_max_requests integer default 12
)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_recent_count integer;
begin
  delete from public.rate_limit_events
  where created_at < now() - make_interval(secs => greatest(p_window_seconds * 2, 300));

  select count(*)
  into v_recent_count
  from public.rate_limit_events
  where actor_hash = p_actor_hash
    and action = p_action
    and created_at >= now() - make_interval(secs => p_window_seconds);

  if v_recent_count >= p_max_requests then
    return false;
  end if;

  insert into public.rate_limit_events (actor_hash, action)
  values (p_actor_hash, p_action);

  return true;
end;
$$;

revoke all on function public.check_and_record_rate_limit(text, text, integer, integer)
  from public, anon, authenticated;

grant execute on function public.check_and_record_rate_limit(text, text, integer, integer)
  to service_role;

-- 7. Read-only spatial RPCs
create or replace function public.find_barriers_along_route(
  p_route_wkt text,
  p_buffer_meters double precision default 20.0,
  p_profile text default null
)
returns table (
  id bigint,
  category text,
  title text,
  description text,
  severity smallint,
  profile_flags jsonb,
  lat double precision,
  lng double precision,
  distance_to_route_m double precision,
  confirmations_count integer,
  last_confirmed_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  with route_geom as (
    select extensions.st_setsrid(extensions.st_geomfromtext(p_route_wkt), 4326)::extensions.geography as geog
  )
  select
    b.id, b.category, b.title, b.description, b.severity, b.profile_flags,
    extensions.st_y(b.location::extensions.geometry) as lat,
    extensions.st_x(b.location::extensions.geometry) as lng,
    extensions.st_distance(b.location, r.geog) as distance_to_route_m,
    b.confirmations_count, b.last_confirmed_at
  from public.barriers b
  cross join route_geom r
  where b.is_public = true
    and b.status = 'active'
    and (b.expires_at is null or b.expires_at > now())
    and extensions.st_dwithin(b.location, r.geog, p_buffer_meters)
    and (
      p_profile is null
      or (b.profile_flags ->> p_profile)::boolean is true
    )
  order by b.severity desc, distance_to_route_m asc
  limit 100;
$$;

grant execute on function public.find_barriers_along_route(text, double precision, text)
  to anon, authenticated, service_role;

create or replace function public.find_nearby_barriers(
  p_lat double precision,
  p_lng double precision,
  p_radius_meters double precision default 500.0
)
returns table (
  id bigint,
  category text,
  title text,
  description text,
  severity smallint,
  profile_flags jsonb,
  lat double precision,
  lng double precision,
  distance_meters double precision,
  confirmations_count integer,
  last_confirmed_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  with origin_pt as (
    select extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography as geog
  )
  select
    b.id, b.category, b.title, b.description, b.severity, b.profile_flags,
    extensions.st_y(b.location::extensions.geometry) as lat,
    extensions.st_x(b.location::extensions.geometry) as lng,
    extensions.st_distance(b.location, o.geog) as distance_meters,
    b.confirmations_count, b.last_confirmed_at
  from public.barriers b
  cross join origin_pt o
  where b.is_public = true
    and b.status = 'active'
    and (b.expires_at is null or b.expires_at > now())
    and extensions.st_dwithin(b.location, o.geog, p_radius_meters)
  order by distance_meters asc
  limit 100;
$$;

grant execute on function public.find_nearby_barriers(double precision, double precision, double precision)
  to anon, authenticated, service_role;
