-- Migration 1: Isolated extensions schema for PostGIS and pgvector
-- Standard: supabase / supabase-postgres-best-practices (never install PostGIS/vector in public)

create schema if not exists extensions;
grant usage on schema extensions to postgres, anon, authenticated, service_role;
create extension if not exists postgis with schema extensions;
create extension if not exists vector with schema extensions;
