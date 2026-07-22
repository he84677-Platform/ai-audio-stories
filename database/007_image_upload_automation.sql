-- Image upload automation: database preparation and one-time backfill.
-- Expected layout in bucket story-images:
--   <story-slug>/cover.png
--   <story-slug>/banner.png
--   <story-slug>/episodes/episode-01.png

alter table public.stories
  add column if not exists cover_image_path text,
  add column if not exists banner_image_path text;

alter table public.episodes
  add column if not exists artwork_url text;
  add column if not exists artwork_path text;

create unique index if not exists uq_media_assets_storage_path
  on public.media_assets (storage_path) where storage_path is not null;

create table if not exists public.storage_image_sync_errors (
  id bigint generated always as identity primary key,
  bucket_id text not null,
  object_name text not null,
  error_message text not null,
  created_at timestamptz not null default now()
);

create or replace function public.sync_existing_story_images(
  p_bucket_id text default 'story-images',
  p_supabase_url text default null
)
returns table(processed integer, updated_stories integer, updated_episodes integer, errors integer)
language plpgsql security definer set search_path = public, storage
as $$
declare
  o record;
  story_slug text;
  v_story_id uuid;
  v_episode_number integer;
  asset_type text;
  asset_episode_id uuid;
  v_processed integer := 0;
  v_stories integer := 0;
  v_episodes integer := 0;
  v_errors integer := 0;
begin
  for o in select name, bucket_id, metadata from storage.objects
           where bucket_id = p_bucket_id
             and lower(coalesce(metadata->>'mimetype', '')) like 'image/%'
  loop
    begin
      v_processed := v_processed + 1;
      story_slug := split_part(o.name, '/', 1);
      select s.id into v_story_id from public.stories as s where s.slug = story_slug;
      if v_story_id is null then raise exception 'No story found for slug: %', story_slug; end if;

      if lower(o.name) ~ '/cover\.[a-z0-9]+$' then
        update public.stories set cover_image_path = o.name,
          cover_image_url = case when p_supabase_url is null then cover_image_url else
            format('%s/storage/v1/object/public/%s/%s', rtrim(p_supabase_url, '/'), p_bucket_id, o.name) end,
          updated_at = now() where id = v_story_id;
        asset_type := 'cover_image'; asset_episode_id := null; v_stories := v_stories + 1;
      elsif lower(o.name) ~ '/banner\.[a-z0-9]+$' then
        update public.stories set banner_image_path = o.name, updated_at = now()
          where id = v_story_id;
        asset_type := 'cover_image'; asset_episode_id := null; v_stories := v_stories + 1;
      elsif lower(o.name) ~ '/episodes/episode-[0-9]+\.[a-z0-9]+$' then
        v_episode_number := substring(lower(o.name) from '/episodes/episode-([0-9]+)\.')::integer;
        select e.id into asset_episode_id from public.episodes as e
          where e.story_id = v_story_id and e.episode_number = v_episode_number;
        if asset_episode_id is null then
          raise exception 'No episode % found for story %', v_episode_number, story_slug;
        end if;
        update public.episodes set artwork_path = o.name,
          artwork_url = case
            when p_supabase_url is null then null
            else format('%s/storage/v1/object/public/%s/%s', rtrim(p_supabase_url, '/'), p_bucket_id, o.name)
          end,
          updated_at = now() where id = asset_episode_id;
        asset_type := 'episode_image'; v_episodes := v_episodes + 1;
      else
        raise exception 'Unsupported image path: %', o.name;
      end if;

      insert into public.media_assets
        (story_id, episode_id, asset_type, storage_provider, storage_path,
         public_url, mime_type, file_size_bytes)
      values (
        case when asset_type = 'cover_image' then v_story_id else null end,
        asset_episode_id, asset_type, 'supabase', o.name,
        case when p_supabase_url is null then null else format(
          '%s/storage/v1/object/public/%s/%s', rtrim(p_supabase_url, '/'), p_bucket_id, o.name) end,
        o.metadata->>'mimetype', (o.metadata->>'size')::bigint
      ) on conflict (storage_path) do update set public_url = excluded.public_url;
    exception when others then
      v_errors := v_errors + 1;
      insert into public.storage_image_sync_errors(bucket_id, object_name, error_message)
        values (p_bucket_id, o.name, sqlerrm);
    end;
  end loop;
  return query select v_processed, v_stories, v_episodes, v_errors;
end;
$$;

-- One-time run after existing images are uploaded:
-- select * from public.sync_existing_story_images(
--   'story-images', 'https://YOUR_PROJECT_REF.supabase.co'
-- );
