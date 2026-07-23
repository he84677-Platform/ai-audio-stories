-- The Cartographer's Dream + Microsoft Azure Sonia narrator
-- Safe migration for the existing story:
--   current slug: the-cartographers-dream
--   current story id: 2acd5b3f-9ec5-4699-93cb-8d7ab16edce2
--
-- Run this in Supabase SQL Editor after taking a database backup.

begin;

do $migration$
declare
  v_story_id uuid;
begin
  select id
    into v_story_id
  from public.stories
  where id = '2acd5b3f-9ec5-4699-93cb-8d7ab16edce2'::uuid
     or slug = 'the-cartographers-dream'
  limit 1;

  if v_story_id is null then
    raise exception 'The Cartographer''s Dream story was not found';
  end if;

    -- Update the public title and URL slug. Episodes remain linked by story_id.
  update public.stories
    set title = 'The Cartographer''s Dream',
      slug = 'the-cartographers-dream',
      updated_at = now()
  where id = v_story_id;

  -- Keep a database-owned voice configuration for the Quick Play service.
  -- This table is independent of Azure credentials; never store the Azure key here.
  create table if not exists public.story_audio_voice_settings (
    story_id uuid primary key references public.stories(id) on delete cascade,
    narrator_display_name text not null,
    speech_provider text not null,
    provider_voice_id text not null,
    locale text not null,
    voice_description text null,
    enabled boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  );

  insert into public.story_audio_voice_settings (
    story_id,
    narrator_display_name,
    speech_provider,
    provider_voice_id,
    locale,
    voice_description,
    enabled,
    updated_at
  )
  values (
    v_story_id,
    'Sonia',
    'azure',
    'en-GB-SoniaNeural',
    'en-GB',
    'Gentle and soft British female narrator for The Cartographer''s Dream.',
    true,
    now()
  )
  on conflict (story_id) do update
  set narrator_display_name = excluded.narrator_display_name,
      speech_provider = excluded.speech_provider,
      provider_voice_id = excluded.provider_voice_id,
      locale = excluded.locale,
      voice_description = excluded.voice_description,
      enabled = excluded.enabled,
      updated_at = now();

  raise notice 'Updated story % to The Cartographer''s Dream with Azure voice %',
    v_story_id, 'en-GB-SoniaNeural';
end;
$migration$;

commit;

-- Verification
select id, slug, title
from public.stories
where slug = 'the-cartographers-dream';

select s.slug, s.title, v.narrator_display_name, v.speech_provider,
       v.provider_voice_id, v.locale, v.enabled
from public.story_audio_voice_settings v
join public.stories s on s.id = v.story_id
where s.slug = 'the-cartographers-dream';

select count(*) as linked_episode_count
from public.episodes e
join public.stories s on s.id = e.story_id
where s.slug = 'the-cartographers-dream';
