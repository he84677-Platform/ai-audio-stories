-- 001_initial_schema.sql
-- Initial database objects for the AI Audio Stories MVP.
-- Created in Supabase on 18 July 2026.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.stories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  short_description text,
  description text,
  cover_image_url text,
  content_status text not null default 'draft'
    check (content_status in ('draft', 'published', 'archived')),
  created_by uuid references auth.users(id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint stories_slug_lowercase check (slug = lower(slug))
);

create index idx_stories_status_published_at
  on public.stories (content_status, published_at desc);

create trigger set_stories_updated_at
before update on public.stories
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.stories enable row level security;