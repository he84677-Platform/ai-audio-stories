-- 004_schema_updates.sql
-- Schema updates for seasons, episode images and the spoiler-aware story wiki.
-- Run once after 001_initial_schema.sql, 002_story_read_policy.sql and 003_seed_story.sql.

begin;

-- -----------------------------------------------------------------------------
-- Story and episode fields used by the application and wiki.
-- -----------------------------------------------------------------------------

alter table public.stories
  add column if not exists banner_image_path text,
  add column if not exists cover_image_path text,
  add column if not exists wiki_enabled boolean not null default false;

alter table public.episodes
  add column if not exists season_number integer not null default 1,
  add column if not exists cover_image_path text;

update public.episodes
set season_number = 1
where season_number is null;

create index if not exists idx_episodes_story_season_number
  on public.episodes (story_id, season_number, episode_number);

-- -----------------------------------------------------------------------------
-- Wiki lookup and settings.
-- -----------------------------------------------------------------------------

create table if not exists public.wiki_entry_types (
  code text primary key,
  display_name text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.story_wiki_settings (
  story_id uuid primary key references public.stories(id) on delete cascade,
  wiki_enabled boolean not null default false,
  wiki_title text,
  wiki_introduction text,
  allow_spoiler_toggle boolean not null default true,
  show_locked_placeholders boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wiki_entries (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories(id) on delete cascade,
  entry_type text not null references public.wiki_entry_types(code),
  slug text not null,
  title text not null,
  short_description text,
  introduction text,
  image_path text,
  reveal_episode_id uuid references public.episodes(id) on delete set null,
  spoiler_level integer not null default 0,
  is_public boolean not null default true,
  content_status text not null default 'draft'
    check (content_status in ('draft', 'published', 'archived')),
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (story_id, slug)
);

create table if not exists public.wiki_entry_sections (
  id uuid primary key default gen_random_uuid(),
  wiki_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
  section_key text not null,
  heading text,
  content text not null,
  reveal_episode_id uuid references public.episodes(id) on delete set null,
  spoiler_level integer not null default 0,
  is_public boolean not null default true,
  content_status text not null default 'published'
    check (content_status in ('draft', 'published', 'archived')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (wiki_entry_id, section_key)
);

create table if not exists public.wiki_entry_internal (
  wiki_entry_id uuid primary key references public.wiki_entries(id) on delete cascade,
  ai_context text,
  internal_notes text,
  continuity_rules text,
  future_arc_notes text,
  source_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wiki_character_profiles (
  wiki_entry_id uuid primary key references public.wiki_entries(id) on delete cascade,
  role_in_story text,
  personality text,
  strengths text,
  weaknesses text,
  motivations text,
  fears text,
  speech_style text,
  appearance text,
  habits_and_mannerisms text,
  moral_boundaries text,
  current_state text,
  character_arc_notes text,
  ai_generation_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wiki_entry_relationships (
  id uuid primary key default gen_random_uuid(),
  source_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
  target_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
  relationship_type text not null,
  public_description text,
  reveal_episode_id uuid references public.episodes(id) on delete set null,
  spoiler_level integer not null default 0,
  is_public boolean not null default true,
  content_status text not null default 'published'
    check (content_status in ('draft', 'published', 'archived')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.episode_wiki_entries (
  episode_id uuid not null references public.episodes(id) on delete cascade,
  wiki_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
  appearance_type text not null default 'mentioned',
  public_notes text,
  reveal_episode_id uuid references public.episodes(id) on delete set null,
  spoiler_level integer not null default 0,
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (episode_id, wiki_entry_id)
);

create table if not exists public.story_canon_rules (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories(id) on delete cascade,
  rule_key text not null,
  rule_category text not null,
  rule_text text not null,
  importance text,
  active_from_episode_id uuid references public.episodes(id) on delete set null,
  active_to_episode_id uuid references public.episodes(id) on delete set null,
  reveal_episode_id uuid references public.episodes(id) on delete set null,
  spoiler_level integer not null default 0,
  is_public boolean not null default false,
  content_status text not null default 'published'
    check (content_status in ('draft', 'published', 'archived')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (story_id, rule_key)
);

create table if not exists public.story_canon_rule_internal (
  canon_rule_id uuid primary key references public.story_canon_rules(id) on delete cascade,
  source_notes text,
  ai_context text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.character_knowledge (
  id uuid primary key default gen_random_uuid(),
  character_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
  fact_entry_id uuid references public.wiki_entries(id) on delete cascade,
  knowledge_text text not null,
  certainty_level text,
  learned_in_episode_id uuid references public.episodes(id) on delete set null,
  superseded_in_episode_id uuid references public.episodes(id) on delete set null,
  reveal_episode_id uuid references public.episodes(id) on delete set null,
  is_secret boolean not null default true,
  spoiler_level integer not null default 0,
  is_public boolean not null default false,
  content_status text not null default 'published'
    check (content_status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_wiki_entries_story_type
  on public.wiki_entries (story_id, entry_type, sort_order);
create index if not exists idx_wiki_sections_entry
  on public.wiki_entry_sections (wiki_entry_id, sort_order);

-- Public reads are performed through 006_public_wiki_api.sql.  Keep the tables
-- private by default; do not grant direct anonymous access to story-bible data.
alter table public.story_wiki_settings enable row level security;
alter table public.wiki_entries enable row level security;
alter table public.wiki_entry_sections enable row level security;
alter table public.wiki_entry_internal enable row level security;
alter table public.wiki_character_profiles enable row level security;
alter table public.wiki_entry_relationships enable row level security;
alter table public.episode_wiki_entries enable row level security;
alter table public.story_canon_rules enable row level security;
alter table public.story_canon_rule_internal enable row level security;
alter table public.character_knowledge enable row level security;

commit;
