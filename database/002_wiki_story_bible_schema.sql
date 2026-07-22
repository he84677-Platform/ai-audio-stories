-- 002_wiki_story_bible_schema.sql
-- Database-driven wiki, story bible, continuity controls, user progress and spoiler filtering.
-- Designed for Supabase/PostgreSQL and the existing public.stories/public.episodes schema.
-- Run once in the Supabase SQL Editor, then commit this file to your repository.

begin;

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- PRE-FLIGHT CHECKS
-- -----------------------------------------------------------------------------

do $$
begin
    if to_regclass('public.stories') is null then
        raise exception 'Required table public.stories does not exist.';
    end if;

    if to_regclass('public.episodes') is null then
        raise exception 'Required table public.episodes does not exist.';
    end if;
end;
$$;

-- Reuse the same updated_at pattern as the rest of the application.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- LOOKUP TABLES
-- -----------------------------------------------------------------------------

create table public.wiki_entry_types (
    slug text primary key,
    name text not null unique,
    description text,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    constraint wiki_entry_types_slug_lowercase check (slug = lower(slug)),
    constraint wiki_entry_types_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

insert into public.wiki_entry_types (slug, name, description, sort_order)
values
    ('character', 'Characters', 'People, artificial intelligences and named beings.', 10),
    ('location', 'Locations', 'Places, districts, structures and environments.', 20),
    ('technology', 'Technology', 'Devices, systems, vehicles and scientific concepts.', 30),
    ('organisation', 'Organisations', 'Governments, companies, factions and institutions.', 40),
    ('event', 'Events', 'Historical events, discoveries and major incidents.', 50),
    ('concept', 'Concepts', 'Ideas, customs, social systems and world-building concepts.', 60),
    ('artefact', 'Artefacts', 'Important physical objects, archives and relics.', 70),
    ('species', 'Species', 'Species, biological groups and synthetic life forms.', 80)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    sort_order = excluded.sort_order;

create table public.wiki_relationship_types (
    slug text primary key,
    name text not null unique,
    inverse_name text,
    is_symmetric boolean not null default false,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    constraint wiki_relationship_types_slug_lowercase check (slug = lower(slug)),
    constraint wiki_relationship_types_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

insert into public.wiki_relationship_types
    (slug, name, inverse_name, is_symmetric, sort_order)
values
    ('related-to', 'Related to', 'Related to', true, 10),
    ('friend-of', 'Friend of', 'Friend of', true, 20),
    ('member-of', 'Member of', 'Has member', false, 30),
    ('located-in', 'Located in', 'Contains', false, 40),
    ('created-by', 'Created by', 'Created', false, 50),
    ('uses', 'Uses', 'Used by', false, 60),
    ('discovered-in', 'Discovered in', 'Discovery location of', false, 70),
    ('opposes', 'Opposes', 'Opposed by', false, 80)
on conflict (slug) do update
set name = excluded.name,
    inverse_name = excluded.inverse_name,
    is_symmetric = excluded.is_symmetric,
    sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- STORY-LEVEL WIKI SETTINGS
-- -----------------------------------------------------------------------------

create table public.story_wiki_settings (
    story_id uuid primary key references public.stories(id) on delete cascade,
    wiki_enabled boolean not null default true,
    wiki_title text not null default 'Wiki',
    wiki_introduction text,
    allow_spoiler_toggle boolean not null default true,
    show_locked_placeholders boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create or replace function public.create_story_wiki_settings()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.story_wiki_settings (story_id)
    values (new.id)
    on conflict (story_id) do nothing;

    return new;
end;
$$;

-- Create settings for stories that already exist.
insert into public.story_wiki_settings (story_id)
select s.id
from public.stories s
on conflict (story_id) do nothing;

drop trigger if exists create_story_wiki_settings_after_story_insert on public.stories;
create trigger create_story_wiki_settings_after_story_insert
after insert on public.stories
for each row execute function public.create_story_wiki_settings();

-- -----------------------------------------------------------------------------
-- PUBLIC WIKI CONTENT
-- Keep internal AI/story-bible material out of this table so public SELECT access
-- can never expose private notes merely by selecting additional columns.
-- -----------------------------------------------------------------------------

create table public.wiki_entries (
    id uuid primary key default gen_random_uuid(),
    story_id uuid not null references public.stories(id) on delete cascade,
    entry_type text not null references public.wiki_entry_types(slug),
    slug text not null,
    title text not null,
    short_description text,
    introduction text,
    primary_image_path text,
    banner_image_path text,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default true,
    content_status text not null default 'draft'
        check (content_status in ('draft', 'published', 'archived')),
    sort_order integer not null default 0,
    published_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint wiki_entries_story_slug_unique unique (story_id, slug),
    constraint wiki_entries_slug_lowercase check (slug = lower(slug)),
    constraint wiki_entries_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

create table public.wiki_entry_sections (
    id uuid primary key default gen_random_uuid(),
    wiki_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
    heading text,
    section_key text,
    content text not null,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default true,
    content_status text not null default 'draft'
        check (content_status in ('draft', 'published', 'archived')),
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint wiki_entry_sections_key_unique unique (wiki_entry_id, section_key),
    constraint wiki_entry_sections_key_format check (
        section_key is null or section_key ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    )
);

-- Internal material is deliberately separated from public wiki rows.
create table public.wiki_entry_internal (
    wiki_entry_id uuid primary key references public.wiki_entries(id) on delete cascade,
    ai_context text,
    internal_notes text,
    continuity_rules text,
    future_arc_notes text,
    source_notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Structured character details for generation and continuity checking.
-- This table is internal and is not exposed through public read policies.
create table public.wiki_character_profiles (
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

-- -----------------------------------------------------------------------------
-- LINKS BETWEEN EPISODES, ENTRIES, IMAGES AND OTHER ENTRIES
-- -----------------------------------------------------------------------------

create table public.episode_wiki_entries (
    episode_id uuid not null references public.episodes(id) on delete cascade,
    wiki_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
    appearance_type text not null default 'appears',
    public_notes text,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default true,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    primary key (episode_id, wiki_entry_id)
);

create table public.episode_wiki_entry_internal (
    episode_id uuid not null,
    wiki_entry_id uuid not null,
    internal_notes text,
    ai_context text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    primary key (episode_id, wiki_entry_id),
    foreign key (episode_id, wiki_entry_id)
        references public.episode_wiki_entries(episode_id, wiki_entry_id)
        on delete cascade
);

create table public.wiki_entry_relationships (
    id uuid primary key default gen_random_uuid(),
    source_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
    target_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
    relationship_type text not null references public.wiki_relationship_types(slug),
    public_description text,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default true,
    content_status text not null default 'draft'
        check (content_status in ('draft', 'published', 'archived')),
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint wiki_entry_relationships_no_self check (source_entry_id <> target_entry_id),
    constraint wiki_entry_relationships_unique
        unique (source_entry_id, target_entry_id, relationship_type)
);

create table public.wiki_relationship_internal (
    relationship_id uuid primary key
        references public.wiki_entry_relationships(id) on delete cascade,
    internal_notes text,
    ai_context text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.wiki_entry_images (
    id uuid primary key default gen_random_uuid(),
    wiki_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
    image_type text not null default 'gallery'
        check (image_type in ('portrait', 'banner', 'gallery', 'map', 'diagram', 'symbol')),
    storage_provider text not null default 'supabase'
        check (storage_provider in ('supabase', 'r2', 'external')),
    storage_path text,
    public_url text,
    alt_text text,
    caption text,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default true,
    content_status text not null default 'draft'
        check (content_status in ('draft', 'published', 'archived')),
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint wiki_entry_images_has_location check (
        storage_path is not null or public_url is not null
    )
);

-- -----------------------------------------------------------------------------
-- STORY BIBLE / CONTINUITY TABLES
-- -----------------------------------------------------------------------------

create table public.story_canon_rules (
    id uuid primary key default gen_random_uuid(),
    story_id uuid not null references public.stories(id) on delete cascade,
    rule_category text not null,
    rule_text text not null,
    importance text not null default 'normal'
        check (importance in ('low', 'normal', 'high', 'critical')),
    active_from_episode_id uuid references public.episodes(id) on delete set null,
    active_to_episode_id uuid references public.episodes(id) on delete set null,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default false,
    content_status text not null default 'draft'
        check (content_status in ('draft', 'published', 'archived')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.story_canon_rule_internal (
    canon_rule_id uuid primary key
        references public.story_canon_rules(id) on delete cascade,
    source_notes text,
    ai_context text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.character_knowledge (
    id uuid primary key default gen_random_uuid(),
    character_entry_id uuid not null references public.wiki_entries(id) on delete cascade,
    fact_entry_id uuid references public.wiki_entries(id) on delete set null,
    knowledge_text text not null,
    certainty_level text not null default 'knows'
        check (certainty_level in ('suspects', 'believes', 'knows', 'misunderstands')),
    learned_in_episode_id uuid references public.episodes(id) on delete set null,
    superseded_in_episode_id uuid references public.episodes(id) on delete set null,
    reveal_episode_id uuid references public.episodes(id) on delete set null,
    is_secret boolean not null default false,
    spoiler_level integer not null default 0 check (spoiler_level between 0 and 3),
    is_public boolean not null default false,
    content_status text not null default 'draft'
        check (content_status in ('draft', 'published', 'archived')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- USER PROGRESS AND SPOILER PREFERENCE
-- One row per user per story. The website can update this directly, and the
-- optional playback trigger below keeps it aligned with completed episodes.
-- -----------------------------------------------------------------------------

create table public.user_story_progress (
    user_id uuid not null references auth.users(id) on delete cascade,
    story_id uuid not null references public.stories(id) on delete cascade,
    highest_episode_completed integer not null default 0
        check (highest_episode_completed >= 0),
    spoilers_enabled boolean not null default false,
    last_episode_id uuid references public.episodes(id) on delete set null,
    last_activity_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    primary key (user_id, story_id)
);

-- -----------------------------------------------------------------------------
-- DATA-INTEGRITY VALIDATION
-- PostgreSQL foreign keys prove that an episode exists; these triggers also prove
-- that the episode belongs to the same story as the wiki record.
-- -----------------------------------------------------------------------------

create or replace function public.validate_wiki_entry_story()
returns trigger
language plpgsql
as $$
begin
    if new.reveal_episode_id is not null and not exists (
        select 1
        from public.episodes e
        where e.id = new.reveal_episode_id
          and e.story_id = new.story_id
    ) then
        raise exception 'reveal_episode_id must belong to the same story as the wiki entry';
    end if;

    return new;
end;
$$;

create or replace function public.validate_wiki_child_story()
returns trigger
language plpgsql
as $$
declare
    v_story_id uuid;
begin
    select we.story_id
      into v_story_id
      from public.wiki_entries we
     where we.id = new.wiki_entry_id;

    if v_story_id is null then
        raise exception 'The referenced wiki entry does not exist';
    end if;

    if new.reveal_episode_id is not null and not exists (
        select 1
          from public.episodes e
         where e.id = new.reveal_episode_id
           and e.story_id = v_story_id
    ) then
        raise exception 'reveal_episode_id must belong to the same story as the wiki entry';
    end if;

    return new;
end;
$$;

create or replace function public.validate_episode_wiki_story()
returns trigger
language plpgsql
as $$
declare
    v_episode_story uuid;
    v_entry_story uuid;
begin
    select story_id into v_episode_story
      from public.episodes
     where id = new.episode_id;

    select story_id into v_entry_story
      from public.wiki_entries
     where id = new.wiki_entry_id;

    if v_episode_story is distinct from v_entry_story then
        raise exception 'episode_id and wiki_entry_id must belong to the same story';
    end if;

    if new.reveal_episode_id is not null and not exists (
        select 1
          from public.episodes e
         where e.id = new.reveal_episode_id
           and e.story_id = v_entry_story
    ) then
        raise exception 'reveal_episode_id must belong to the same story';
    end if;

    return new;
end;
$$;

create or replace function public.validate_wiki_relationship_story()
returns trigger
language plpgsql
as $$
declare
    v_source_story uuid;
    v_target_story uuid;
begin
    select story_id into v_source_story
      from public.wiki_entries
     where id = new.source_entry_id;

    select story_id into v_target_story
      from public.wiki_entries
     where id = new.target_entry_id;

    if v_source_story is distinct from v_target_story then
        raise exception 'Related wiki entries must belong to the same story';
    end if;

    if new.reveal_episode_id is not null and not exists (
        select 1
          from public.episodes e
         where e.id = new.reveal_episode_id
           and e.story_id = v_source_story
    ) then
        raise exception 'reveal_episode_id must belong to the same story as the related entries';
    end if;

    return new;
end;
$$;

create or replace function public.validate_character_profile_type()
returns trigger
language plpgsql
as $$
begin
    if not exists (
        select 1
          from public.wiki_entries we
         where we.id = new.wiki_entry_id
           and we.entry_type = 'character'
    ) then
        raise exception 'wiki_character_profiles can only reference a character wiki entry';
    end if;

    return new;
end;
$$;

create or replace function public.validate_story_canon_rule()
returns trigger
language plpgsql
as $$
declare
    v_from_number integer;
    v_to_number integer;
begin
    if new.active_from_episode_id is not null then
        select episode_number into v_from_number
          from public.episodes
         where id = new.active_from_episode_id
           and story_id = new.story_id;

        if v_from_number is null then
            raise exception 'active_from_episode_id must belong to the same story';
        end if;
    end if;

    if new.active_to_episode_id is not null then
        select episode_number into v_to_number
          from public.episodes
         where id = new.active_to_episode_id
           and story_id = new.story_id;

        if v_to_number is null then
            raise exception 'active_to_episode_id must belong to the same story';
        end if;
    end if;

    if new.reveal_episode_id is not null and not exists (
        select 1
          from public.episodes e
         where e.id = new.reveal_episode_id
           and e.story_id = new.story_id
    ) then
        raise exception 'reveal_episode_id must belong to the same story';
    end if;

    if v_from_number is not null
       and v_to_number is not null
       and v_from_number > v_to_number then
        raise exception 'active_from_episode_id cannot occur after active_to_episode_id';
    end if;

    return new;
end;
$$;

create or replace function public.validate_character_knowledge_story()
returns trigger
language plpgsql
as $$
declare
    v_story_id uuid;
    v_character_type text;
    v_episode_id uuid;
begin
    select story_id, entry_type
      into v_story_id, v_character_type
      from public.wiki_entries
     where id = new.character_entry_id;

    if v_character_type is distinct from 'character' then
        raise exception 'character_entry_id must reference a character wiki entry';
    end if;

    if new.fact_entry_id is not null and not exists (
        select 1
          from public.wiki_entries we
         where we.id = new.fact_entry_id
           and we.story_id = v_story_id
    ) then
        raise exception 'fact_entry_id must belong to the same story as the character';
    end if;

    foreach v_episode_id in array array[
        new.learned_in_episode_id,
        new.superseded_in_episode_id,
        new.reveal_episode_id
    ]
    loop
        if v_episode_id is not null and not exists (
            select 1
              from public.episodes e
             where e.id = v_episode_id
               and e.story_id = v_story_id
        ) then
            raise exception 'All episode references must belong to the same story as the character';
        end if;
    end loop;

    return new;
end;
$$;

create or replace function public.validate_user_story_progress()
returns trigger
language plpgsql
as $$
begin
    if new.last_episode_id is not null and not exists (
        select 1
          from public.episodes e
         where e.id = new.last_episode_id
           and e.story_id = new.story_id
    ) then
        raise exception 'last_episode_id must belong to the same story';
    end if;

    return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- TRIGGERS
-- -----------------------------------------------------------------------------

drop trigger if exists set_story_wiki_settings_updated_at on public.story_wiki_settings;
create trigger set_story_wiki_settings_updated_at
before update on public.story_wiki_settings
for each row execute function public.set_updated_at();

drop trigger if exists set_wiki_entries_updated_at on public.wiki_entries;
create trigger set_wiki_entries_updated_at
before update on public.wiki_entries
for each row execute function public.set_updated_at();

drop trigger if exists validate_wiki_entries_story on public.wiki_entries;
create trigger validate_wiki_entries_story
before insert or update on public.wiki_entries
for each row execute function public.validate_wiki_entry_story();

drop trigger if exists set_wiki_entry_sections_updated_at on public.wiki_entry_sections;
create trigger set_wiki_entry_sections_updated_at
before update on public.wiki_entry_sections
for each row execute function public.set_updated_at();

drop trigger if exists validate_wiki_entry_sections_story on public.wiki_entry_sections;
create trigger validate_wiki_entry_sections_story
before insert or update on public.wiki_entry_sections
for each row execute function public.validate_wiki_child_story();

drop trigger if exists set_wiki_entry_internal_updated_at on public.wiki_entry_internal;
create trigger set_wiki_entry_internal_updated_at
before update on public.wiki_entry_internal
for each row execute function public.set_updated_at();

drop trigger if exists set_wiki_character_profiles_updated_at on public.wiki_character_profiles;
create trigger set_wiki_character_profiles_updated_at
before update on public.wiki_character_profiles
for each row execute function public.set_updated_at();

drop trigger if exists validate_wiki_character_profile_type on public.wiki_character_profiles;
create trigger validate_wiki_character_profile_type
before insert or update on public.wiki_character_profiles
for each row execute function public.validate_character_profile_type();

drop trigger if exists validate_episode_wiki_entries_story on public.episode_wiki_entries;
create trigger validate_episode_wiki_entries_story
before insert or update on public.episode_wiki_entries
for each row execute function public.validate_episode_wiki_story();

drop trigger if exists set_episode_wiki_entry_internal_updated_at on public.episode_wiki_entry_internal;
create trigger set_episode_wiki_entry_internal_updated_at
before update on public.episode_wiki_entry_internal
for each row execute function public.set_updated_at();

drop trigger if exists set_wiki_entry_relationships_updated_at on public.wiki_entry_relationships;
create trigger set_wiki_entry_relationships_updated_at
before update on public.wiki_entry_relationships
for each row execute function public.set_updated_at();

drop trigger if exists validate_wiki_entry_relationships_story on public.wiki_entry_relationships;
create trigger validate_wiki_entry_relationships_story
before insert or update on public.wiki_entry_relationships
for each row execute function public.validate_wiki_relationship_story();

drop trigger if exists set_wiki_relationship_internal_updated_at on public.wiki_relationship_internal;
create trigger set_wiki_relationship_internal_updated_at
before update on public.wiki_relationship_internal
for each row execute function public.set_updated_at();

drop trigger if exists set_wiki_entry_images_updated_at on public.wiki_entry_images;
create trigger set_wiki_entry_images_updated_at
before update on public.wiki_entry_images
for each row execute function public.set_updated_at();

drop trigger if exists validate_wiki_entry_images_story on public.wiki_entry_images;
create trigger validate_wiki_entry_images_story
before insert or update on public.wiki_entry_images
for each row execute function public.validate_wiki_child_story();

drop trigger if exists set_story_canon_rules_updated_at on public.story_canon_rules;
create trigger set_story_canon_rules_updated_at
before update on public.story_canon_rules
for each row execute function public.set_updated_at();

drop trigger if exists validate_story_canon_rules_story on public.story_canon_rules;
create trigger validate_story_canon_rules_story
before insert or update on public.story_canon_rules
for each row execute function public.validate_story_canon_rule();

drop trigger if exists set_story_canon_rule_internal_updated_at on public.story_canon_rule_internal;
create trigger set_story_canon_rule_internal_updated_at
before update on public.story_canon_rule_internal
for each row execute function public.set_updated_at();

drop trigger if exists set_character_knowledge_updated_at on public.character_knowledge;
create trigger set_character_knowledge_updated_at
before update on public.character_knowledge
for each row execute function public.set_updated_at();

drop trigger if exists validate_character_knowledge_story on public.character_knowledge;
create trigger validate_character_knowledge_story
before insert or update on public.character_knowledge
for each row execute function public.validate_character_knowledge_story();

drop trigger if exists set_user_story_progress_updated_at on public.user_story_progress;
create trigger set_user_story_progress_updated_at
before update on public.user_story_progress
for each row execute function public.set_updated_at();

drop trigger if exists validate_user_story_progress_story on public.user_story_progress;
create trigger validate_user_story_progress_story
before insert or update on public.user_story_progress
for each row execute function public.validate_user_story_progress();

-- -----------------------------------------------------------------------------
-- OPTIONAL PLAYBACK-PROGRESS INTEGRATION
-- If public.playback_progress exists and has user_id, episode_id and completed,
-- completing an episode automatically advances user_story_progress.
-- -----------------------------------------------------------------------------

create or replace function public.sync_story_progress_from_playback()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_story_id uuid;
    v_episode_number integer;
begin
    if coalesce(new.completed, false) = false then
        return new;
    end if;

    select e.story_id, e.episode_number
      into v_story_id, v_episode_number
      from public.episodes e
     where e.id = new.episode_id;

    if v_story_id is null then
        return new;
    end if;

    insert into public.user_story_progress (
        user_id,
        story_id,
        highest_episode_completed,
        last_episode_id,
        last_activity_at
    )
    values (
        new.user_id,
        v_story_id,
        v_episode_number,
        new.episode_id,
        now()
    )
    on conflict (user_id, story_id)
    do update set
        highest_episode_completed = greatest(
            public.user_story_progress.highest_episode_completed,
            excluded.highest_episode_completed
        ),
        last_episode_id = excluded.last_episode_id,
        last_activity_at = now(),
        updated_at = now();

    return new;
end;
$$;

do $$
begin
    if to_regclass('public.playback_progress') is not null
       and 3 = (
           select count(*)
             from information_schema.columns
            where table_schema = 'public'
              and table_name = 'playback_progress'
              and column_name in ('user_id', 'episode_id', 'completed')
       ) then
        execute 'drop trigger if exists sync_story_progress_after_playback on public.playback_progress';
        execute '
            create trigger sync_story_progress_after_playback
            after insert or update of completed on public.playback_progress
            for each row
            when (new.completed = true)
            execute function public.sync_story_progress_from_playback()
        ';
    end if;
end;
$$;

-- Authenticated clients can also call this directly when an episode is completed.
create or replace function public.mark_episode_completed(p_episode_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid;
    v_story_id uuid;
    v_episode_number integer;
begin
    v_user_id := auth.uid();

    if v_user_id is null then
        raise exception 'Authentication is required';
    end if;

    select e.story_id, e.episode_number
      into v_story_id, v_episode_number
      from public.episodes e
     where e.id = p_episode_id
       and e.episode_status = 'published';

    if v_story_id is null then
        raise exception 'Published episode not found';
    end if;

    insert into public.user_story_progress (
        user_id,
        story_id,
        highest_episode_completed,
        last_episode_id,
        last_activity_at
    )
    values (
        v_user_id,
        v_story_id,
        v_episode_number,
        p_episode_id,
        now()
    )
    on conflict (user_id, story_id)
    do update set
        highest_episode_completed = greatest(
            public.user_story_progress.highest_episode_completed,
            excluded.highest_episode_completed
        ),
        last_episode_id = excluded.last_episode_id,
        last_activity_at = now(),
        updated_at = now();
end;
$$;

revoke all on function public.mark_episode_completed(uuid) from public;
grant execute on function public.mark_episode_completed(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- SPOILER-AWARE VISIBILITY FUNCTION
-- Anonymous users see only published public content with no reveal episode.
-- Authenticated users also see content unlocked by completed episode progress.
-- When spoilers_enabled = true, all published public content for that story is visible.
-- Internal rows remain hidden because is_public must still be true.
-- -----------------------------------------------------------------------------

create or replace function public.can_view_wiki_item(
    p_story_id uuid,
    p_reveal_episode_id uuid,
    p_is_public boolean,
    p_content_status text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select
        coalesce(p_is_public, false)
        and p_content_status = 'published'
        and exists (
            select 1
              from public.stories s
             where s.id = p_story_id
               and s.content_status = 'published'
        )
        and (
            p_reveal_episode_id is null
            or exists (
                select 1
                  from public.episodes e
                  left join public.user_story_progress usp
                    on usp.story_id = p_story_id
                   and usp.user_id = auth.uid()
                 where e.id = p_reveal_episode_id
                   and e.story_id = p_story_id
                   and e.episode_status = 'published'
                   and (
                       coalesce(usp.spoilers_enabled, false)
                       or coalesce(usp.highest_episode_completed, 0) >= e.episode_number
                   )
            )
        );
$$;

revoke all on function public.can_view_wiki_item(uuid, uuid, boolean, text) from public;
grant execute on function public.can_view_wiki_item(uuid, uuid, boolean, text) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- INDEXES
-- -----------------------------------------------------------------------------

create index idx_wiki_entries_story_type_status
    on public.wiki_entries (story_id, entry_type, content_status, sort_order, title);

create index idx_wiki_entries_story_reveal
    on public.wiki_entries (story_id, reveal_episode_id);

create index idx_wiki_entries_search
    on public.wiki_entries
    using gin (
        to_tsvector(
            'english',
            coalesce(title, '') || ' ' ||
            coalesce(short_description, '') || ' ' ||
            coalesce(introduction, '')
        )
    );

create index idx_wiki_entry_sections_entry_status_order
    on public.wiki_entry_sections (wiki_entry_id, content_status, sort_order);

create index idx_episode_wiki_entries_episode
    on public.episode_wiki_entries (episode_id, sort_order);

create index idx_episode_wiki_entries_entry
    on public.episode_wiki_entries (wiki_entry_id, episode_id);

create index idx_wiki_relationships_source
    on public.wiki_entry_relationships (source_entry_id, content_status, sort_order);

create index idx_wiki_relationships_target
    on public.wiki_entry_relationships (target_entry_id, content_status, sort_order);

create index idx_wiki_entry_images_entry_status_order
    on public.wiki_entry_images (wiki_entry_id, content_status, sort_order);

create index idx_story_canon_rules_story_category
    on public.story_canon_rules (story_id, rule_category, importance, content_status);

create index idx_character_knowledge_character
    on public.character_knowledge (character_entry_id, content_status, learned_in_episode_id);

create index idx_user_story_progress_user_activity
    on public.user_story_progress (user_id, last_activity_at desc);

-- -----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- The public site can read only published, public and spoiler-safe rows.
-- Internal tables have no public SELECT policy.
-- -----------------------------------------------------------------------------

alter table public.wiki_entry_types enable row level security;
alter table public.wiki_relationship_types enable row level security;
alter table public.story_wiki_settings enable row level security;
alter table public.wiki_entries enable row level security;
alter table public.wiki_entry_sections enable row level security;
alter table public.wiki_entry_internal enable row level security;
alter table public.wiki_character_profiles enable row level security;
alter table public.episode_wiki_entries enable row level security;
alter table public.episode_wiki_entry_internal enable row level security;
alter table public.wiki_entry_relationships enable row level security;
alter table public.wiki_relationship_internal enable row level security;
alter table public.wiki_entry_images enable row level security;
alter table public.story_canon_rules enable row level security;
alter table public.story_canon_rule_internal enable row level security;
alter table public.character_knowledge enable row level security;
alter table public.user_story_progress enable row level security;

-- Lookup tables

drop policy if exists wiki_entry_types_public_read on public.wiki_entry_types;
create policy wiki_entry_types_public_read
on public.wiki_entry_types
for select
to anon, authenticated
using (true);

drop policy if exists wiki_relationship_types_public_read on public.wiki_relationship_types;
create policy wiki_relationship_types_public_read
on public.wiki_relationship_types
for select
to anon, authenticated
using (true);

-- Wiki settings

drop policy if exists story_wiki_settings_public_read on public.story_wiki_settings;
create policy story_wiki_settings_public_read
on public.story_wiki_settings
for select
to anon, authenticated
using (
    wiki_enabled = true
    and exists (
        select 1
          from public.stories s
         where s.id = story_wiki_settings.story_id
           and s.content_status = 'published'
    )
);

-- Entries

drop policy if exists wiki_entries_spoiler_aware_read on public.wiki_entries;
create policy wiki_entries_spoiler_aware_read
on public.wiki_entries
for select
to anon, authenticated
using (
    public.can_view_wiki_item(
        story_id,
        reveal_episode_id,
        is_public,
        content_status
    )
);

-- Sections

drop policy if exists wiki_entry_sections_spoiler_aware_read on public.wiki_entry_sections;
create policy wiki_entry_sections_spoiler_aware_read
on public.wiki_entry_sections
for select
to anon, authenticated
using (
    exists (
        select 1
          from public.wiki_entries we
         where we.id = wiki_entry_sections.wiki_entry_id
           and public.can_view_wiki_item(
               we.story_id,
               we.reveal_episode_id,
               we.is_public,
               we.content_status
           )
           and public.can_view_wiki_item(
               we.story_id,
               wiki_entry_sections.reveal_episode_id,
               wiki_entry_sections.is_public,
               wiki_entry_sections.content_status
           )
    )
);

-- Episode links

drop policy if exists episode_wiki_entries_spoiler_aware_read on public.episode_wiki_entries;
create policy episode_wiki_entries_spoiler_aware_read
on public.episode_wiki_entries
for select
to anon, authenticated
using (
    exists (
        select 1
          from public.wiki_entries we
          join public.episodes e
            on e.id = episode_wiki_entries.episode_id
           and e.story_id = we.story_id
         where we.id = episode_wiki_entries.wiki_entry_id
           and e.episode_status = 'published'
           and public.can_view_wiki_item(
               we.story_id,
               we.reveal_episode_id,
               we.is_public,
               we.content_status
           )
           and public.can_view_wiki_item(
               we.story_id,
               episode_wiki_entries.reveal_episode_id,
               episode_wiki_entries.is_public,
               'published'
           )
    )
);

-- Relationships

drop policy if exists wiki_entry_relationships_spoiler_aware_read on public.wiki_entry_relationships;
create policy wiki_entry_relationships_spoiler_aware_read
on public.wiki_entry_relationships
for select
to anon, authenticated
using (
    exists (
        select 1
          from public.wiki_entries source_entry
          join public.wiki_entries target_entry
            on target_entry.id = wiki_entry_relationships.target_entry_id
           and target_entry.story_id = source_entry.story_id
         where source_entry.id = wiki_entry_relationships.source_entry_id
           and public.can_view_wiki_item(
               source_entry.story_id,
               source_entry.reveal_episode_id,
               source_entry.is_public,
               source_entry.content_status
           )
           and public.can_view_wiki_item(
               target_entry.story_id,
               target_entry.reveal_episode_id,
               target_entry.is_public,
               target_entry.content_status
           )
           and public.can_view_wiki_item(
               source_entry.story_id,
               wiki_entry_relationships.reveal_episode_id,
               wiki_entry_relationships.is_public,
               wiki_entry_relationships.content_status
           )
    )
);

-- Images

drop policy if exists wiki_entry_images_spoiler_aware_read on public.wiki_entry_images;
create policy wiki_entry_images_spoiler_aware_read
on public.wiki_entry_images
for select
to anon, authenticated
using (
    exists (
        select 1
          from public.wiki_entries we
         where we.id = wiki_entry_images.wiki_entry_id
           and public.can_view_wiki_item(
               we.story_id,
               we.reveal_episode_id,
               we.is_public,
               we.content_status
           )
           and public.can_view_wiki_item(
               we.story_id,
               wiki_entry_images.reveal_episode_id,
               wiki_entry_images.is_public,
               wiki_entry_images.content_status
           )
    )
);

-- Public canon rows only. Internal canon remains inaccessible to public clients.

drop policy if exists story_canon_rules_spoiler_aware_read on public.story_canon_rules;
create policy story_canon_rules_spoiler_aware_read
on public.story_canon_rules
for select
to anon, authenticated
using (
    public.can_view_wiki_item(
        story_id,
        reveal_episode_id,
        is_public,
        content_status
    )
);

-- Public character knowledge rows only. Most records should remain is_public = false.

drop policy if exists character_knowledge_spoiler_aware_read on public.character_knowledge;
create policy character_knowledge_spoiler_aware_read
on public.character_knowledge
for select
to anon, authenticated
using (
    exists (
        select 1
          from public.wiki_entries character_entry
         where character_entry.id = character_knowledge.character_entry_id
           and public.can_view_wiki_item(
               character_entry.story_id,
               character_entry.reveal_episode_id,
               character_entry.is_public,
               character_entry.content_status
           )
           and public.can_view_wiki_item(
               character_entry.story_id,
               character_knowledge.reveal_episode_id,
               character_knowledge.is_public,
               character_knowledge.content_status
           )
    )
);

-- User progress: each authenticated user manages only their own row.

drop policy if exists user_story_progress_select_own on public.user_story_progress;
create policy user_story_progress_select_own
on public.user_story_progress
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists user_story_progress_insert_own on public.user_story_progress;
create policy user_story_progress_insert_own
on public.user_story_progress
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists user_story_progress_update_own on public.user_story_progress;
create policy user_story_progress_update_own
on public.user_story_progress
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists user_story_progress_delete_own on public.user_story_progress;
create policy user_story_progress_delete_own
on public.user_story_progress
for delete
to authenticated
using (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- OPTIONAL ADMIN POLICIES
-- If public.profiles exists and includes user_id + is_admin, authenticated admins
-- receive full access. If profiles has not been created yet, this block safely skips.
-- -----------------------------------------------------------------------------

do $$
declare
    v_table text;
    v_policy text;
    v_tables text[] := array[
        'wiki_entry_types',
        'wiki_relationship_types',
        'story_wiki_settings',
        'wiki_entries',
        'wiki_entry_sections',
        'wiki_entry_internal',
        'wiki_character_profiles',
        'episode_wiki_entries',
        'episode_wiki_entry_internal',
        'wiki_entry_relationships',
        'wiki_relationship_internal',
        'wiki_entry_images',
        'story_canon_rules',
        'story_canon_rule_internal',
        'character_knowledge'
    ];
begin
    if to_regclass('public.profiles') is not null
       and exists (
           select 1
             from information_schema.columns
            where table_schema = 'public'
              and table_name = 'profiles'
              and column_name = 'is_admin'
       )
       and exists (
           select 1
             from information_schema.columns
            where table_schema = 'public'
              and table_name = 'profiles'
              and column_name = 'user_id'
       ) then
        foreach v_table in array v_tables
        loop
            v_policy := v_table || '_admin_all';

            execute format(
                'drop policy if exists %I on public.%I',
                v_policy,
                v_table
            );

            execute format(
                'create policy %I on public.%I for all to authenticated '
                || 'using (exists (select 1 from public.profiles p '
                || 'where p.user_id = auth.uid() and p.is_admin = true)) '
                || 'with check (exists (select 1 from public.profiles p '
                || 'where p.user_id = auth.uid() and p.is_admin = true))',
                v_policy,
                v_table
            );
        end loop;
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- PRIVILEGES
-- RLS still controls which rows are accessible.
-- -----------------------------------------------------------------------------

grant select on public.wiki_entry_types to anon, authenticated;
grant select on public.wiki_relationship_types to anon, authenticated;
grant select on public.story_wiki_settings to anon, authenticated;
grant select on public.wiki_entries to anon, authenticated;
grant select on public.wiki_entry_sections to anon, authenticated;
grant select on public.episode_wiki_entries to anon, authenticated;
grant select on public.wiki_entry_relationships to anon, authenticated;
grant select on public.wiki_entry_images to anon, authenticated;
grant select on public.story_canon_rules to anon, authenticated;
grant select on public.character_knowledge to anon, authenticated;

grant select, insert, update, delete on public.user_story_progress to authenticated;

-- Authenticated users need table privileges for admin policies to take effect.
-- Non-admin users remain blocked by RLS.
grant all on public.wiki_entry_types to authenticated;
grant all on public.wiki_relationship_types to authenticated;
grant all on public.story_wiki_settings to authenticated;
grant all on public.wiki_entries to authenticated;
grant all on public.wiki_entry_sections to authenticated;
grant all on public.wiki_entry_internal to authenticated;
grant all on public.wiki_character_profiles to authenticated;
grant all on public.episode_wiki_entries to authenticated;
grant all on public.episode_wiki_entry_internal to authenticated;
grant all on public.wiki_entry_relationships to authenticated;
grant all on public.wiki_relationship_internal to authenticated;
grant all on public.wiki_entry_images to authenticated;
grant all on public.story_canon_rules to authenticated;
grant all on public.story_canon_rule_internal to authenticated;
grant all on public.character_knowledge to authenticated;

commit;

-- END OF MIGRATION
