-- Migration 4 (forward-only): Consolidate SELECT RLS policies
-- and lock down Supabase's preinstalled public.rls_auto_enable() helper.

drop policy if exists barriers_public_active_select on public.barriers;
drop policy if exists barriers_own_select on public.barriers;

create policy barriers_anon_select
  on public.barriers
  for select
  to anon
  using (
    is_public = true
    and status = 'active'
    and (expires_at is null or expires_at > now())
  );

create policy barriers_authenticated_select
  on public.barriers
  for select
  to authenticated
  using (
    (
      is_public = true
      and status = 'active'
      and (expires_at is null or expires_at > now())
    )
    or (select auth.uid()) = reporter_id
  );

drop policy if exists public_briefs_public_select on public.public_briefs;
drop policy if exists public_briefs_own_select on public.public_briefs;

create policy public_briefs_anon_select
  on public.public_briefs
  for select
  to anon
  using (
    is_public = true
    and (expires_at is null or expires_at > now())
  );

create policy public_briefs_authenticated_select
  on public.public_briefs
  for select
  to authenticated
  using (
    (
      is_public = true
      and (expires_at is null or expires_at > now())
    )
    or (select auth.uid()) = reporter_id
  );

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on p.pronamespace = n.oid
    where n.nspname = 'public'
      and p.proname = 'rls_auto_enable'
  ) then
    execute 'revoke all on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end $$;
