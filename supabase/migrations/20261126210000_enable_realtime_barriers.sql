-- Migration 5: Ensure public.barriers is published to supabase_realtime for instant mobile map updates

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'barriers'
  ) then
    alter publication supabase_realtime add table public.barriers;
  end if;
end $$;
