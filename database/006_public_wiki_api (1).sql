-- 006_public_wiki_api.sql
-- Public, spoiler-aware read API for the website wiki.
--
-- Requires 004_wiki_story_bible_schema.sql.
-- This SECURITY DEFINER function deliberately selects only public wiki fields.
-- It does not expose wiki_entry_internal, wiki_character_profiles, canon-rule
-- internals, character knowledge or any other private story-bible content.

begin;

create or replace function public.get_public_story_wiki(
    p_story_slug text,
    p_entry_slug text default null,
    p_completed_season integer default null,
    p_completed_episode integer default null,
    p_include_spoilers boolean default false
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
with selected_story as (
    select
        s.id,
        s.slug,
        s.title,
        s.short_description,
        s.banner_image_path,
        sws.wiki_title,
        sws.wiki_introduction,
        sws.allow_spoiler_toggle,
        sws.show_locked_placeholders
    from public.stories s
    join public.story_wiki_settings sws
      on sws.story_id = s.id
     and sws.wiki_enabled = true
    where s.slug = p_story_slug
      and s.content_status = 'published'
),
episode_sequence as (
    select
        e.id,
        e.story_id,
        coalesce(e.season_number, 1) as season_number,
        e.episode_number,
        e.title,
        (
            row_number() over (
                order by coalesce(e.season_number, 1), e.episode_number
            )
        )::integer as story_sequence
    from public.episodes e
    join selected_story s
      on s.id = e.story_id
    where e.episode_status = 'published'
),
viewer_state as (
    select
        s.*,
        coalesce(
            (
                select es.story_sequence
                from episode_sequence es
                where es.season_number = p_completed_season
                  and es.episode_number = p_completed_episode
                limit 1
            ),
            0
        ) as completed_sequence,
        (s.allow_spoiler_toggle and p_include_spoilers) as show_all_spoilers
    from selected_story s
),
entry_rows as (
    select
        we.id,
        we.story_id,
        we.entry_type,
        we.slug,
        we.title,
        we.short_description,
        we.introduction,
        we.reveal_episode_id,
        we.spoiler_level,
        we.sort_order,
        reveal_episode.season_number as unlock_season,
        reveal_episode.episode_number as unlock_episode,
        (
            v.show_all_spoilers
            or we.reveal_episode_id is null
            or coalesce(
                reveal_episode.story_sequence <= v.completed_sequence,
                false
            )
        ) as is_unlocked
    from public.wiki_entries we
    join viewer_state v
      on v.id = we.story_id
    left join episode_sequence reveal_episode
      on reveal_episode.id = we.reveal_episode_id
    where we.is_public = true
      and we.content_status = 'published'
),
requested_entry as (
    select er.*
    from entry_rows er
    where p_entry_slug is not null
      and er.slug = p_entry_slug
    limit 1
),
section_rows as (
    select
        wes.id,
        wes.wiki_entry_id,
        wes.section_key,
        wes.heading,
        wes.content,
        wes.reveal_episode_id,
        wes.spoiler_level,
        wes.sort_order,
        (
            v.show_all_spoilers
            or wes.reveal_episode_id is null
            or coalesce(
                reveal_episode.story_sequence <= v.completed_sequence,
                false
            )
        ) as is_unlocked
    from public.wiki_entry_sections wes
    join requested_entry re
      on re.id = wes.wiki_entry_id
    join viewer_state v
      on true
    left join episode_sequence reveal_episode
      on reveal_episode.id = wes.reveal_episode_id
    where wes.is_public = true
      and wes.content_status = 'published'
      and re.is_unlocked = true
),
relationship_rows as (
    select
        r.source_entry_id,
        r.target_entry_id,
        r.relationship_type,
        r.public_description,
        r.reveal_episode_id,
        r.spoiler_level,
        r.sort_order,
        (
            v.show_all_spoilers
            or r.reveal_episode_id is null
            or coalesce(
                reveal_episode.story_sequence <= v.completed_sequence,
                false
            )
        ) as is_unlocked
    from public.wiki_entry_relationships r
    join requested_entry re
      on re.id = r.source_entry_id
      or re.id = r.target_entry_id
    join entry_rows source_entry
      on source_entry.id = r.source_entry_id
    join entry_rows target_entry
      on target_entry.id = r.target_entry_id
    join viewer_state v
      on true
    left join episode_sequence reveal_episode
      on reveal_episode.id = r.reveal_episode_id
    where r.is_public = true
      and r.content_status = 'published'
      and re.is_unlocked = true
      and source_entry.is_unlocked = true
      and target_entry.is_unlocked = true
)
select case
    when not exists (select 1 from viewer_state) then null
    else jsonb_build_object(
        'story', (
            select jsonb_build_object(
                'id', v.id,
                'slug', v.slug,
                'title', v.title,
                'short_description', v.short_description,
                'banner_image_path', v.banner_image_path
            )
            from viewer_state v
        ),
        'settings', (
            select jsonb_build_object(
                'story_id', v.id,
                'wiki_enabled', true,
                'wiki_title', v.wiki_title,
                'wiki_introduction', v.wiki_introduction,
                'allow_spoiler_toggle', v.allow_spoiler_toggle,
                'show_locked_placeholders', v.show_locked_placeholders
            )
            from viewer_state v
        ),
        'episodes', coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'id', es.id,
                        'season_number', es.season_number,
                        'episode_number', es.episode_number,
                        'title', es.title
                    )
                    order by es.story_sequence
                )
                from episode_sequence es
            ),
            '[]'::jsonb
        ),
        'entry_count', (select count(*) from entry_rows),
        'entries', coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'id', er.id,
                        'story_id', er.story_id,
                        'entry_type', er.entry_type,
                        'slug', er.slug,
                        'title', er.title,
                        'short_description', er.short_description,
                        'introduction', er.introduction,
                        'reveal_episode_id', er.reveal_episode_id,
                        'spoiler_level', er.spoiler_level,
                        'sort_order', er.sort_order
                    )
                    order by er.sort_order, er.title
                )
                from entry_rows er
                where er.is_unlocked = true
            ),
            '[]'::jsonb
        ),
        'locked_entries', coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'id', er.id,
                        'reveal_episode_id', er.reveal_episode_id,
                        'unlock_season', er.unlock_season,
                        'unlock_episode', er.unlock_episode,
                        'sort_order', er.sort_order
                    )
                    order by er.sort_order
                )
                from entry_rows er
                where er.is_unlocked = false
            ),
            '[]'::jsonb
        ),
        'requested_entry', (
            select jsonb_build_object(
                'id', re.id,
                'story_id', re.story_id,
                'entry_type', case when re.is_unlocked then re.entry_type end,
                'slug', re.slug,
                'title', case when re.is_unlocked then re.title end,
                'short_description', case when re.is_unlocked then re.short_description end,
                'introduction', case when re.is_unlocked then re.introduction end,
                'reveal_episode_id', re.reveal_episode_id,
                'spoiler_level', re.spoiler_level,
                'sort_order', re.sort_order,
                'is_unlocked', re.is_unlocked
            )
            from requested_entry re
        ),
        'sections', coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'id', sr.id,
                        'wiki_entry_id', sr.wiki_entry_id,
                        'section_key', sr.section_key,
                        'heading', sr.heading,
                        'content', sr.content,
                        'reveal_episode_id', sr.reveal_episode_id,
                        'spoiler_level', sr.spoiler_level,
                        'sort_order', sr.sort_order
                    )
                    order by sr.sort_order
                )
                from section_rows sr
                where sr.is_unlocked = true
            ),
            '[]'::jsonb
        ),
        'locked_section_count', (
            select count(*)
            from section_rows sr
            where sr.is_unlocked = false
        ),
        'relationships', coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'source_entry_id', rr.source_entry_id,
                        'target_entry_id', rr.target_entry_id,
                        'relationship_type', rr.relationship_type,
                        'public_description', rr.public_description,
                        'reveal_episode_id', rr.reveal_episode_id,
                        'spoiler_level', rr.spoiler_level,
                        'sort_order', rr.sort_order
                    )
                    order by rr.sort_order
                )
                from relationship_rows rr
                where rr.is_unlocked = true
            ),
            '[]'::jsonb
        )
    )
end;
$function$;

create or replace function public.has_public_story_wiki(p_story_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
    select exists (
        select 1
        from public.stories s
        join public.story_wiki_settings sws
          on sws.story_id = s.id
         and sws.wiki_enabled = true
        where s.id = p_story_id
          and s.content_status = 'published'
    );
$function$;

revoke all on function public.get_public_story_wiki(
    text,
    text,
    integer,
    integer,
    boolean
) from public;

grant execute on function public.get_public_story_wiki(
    text,
    text,
    integer,
    integer,
    boolean
) to anon, authenticated;

revoke all on function public.has_public_story_wiki(uuid) from public;
grant execute on function public.has_public_story_wiki(uuid)
to anon, authenticated;

comment on function public.get_public_story_wiki(
    text,
    text,
    integer,
    integer,
    boolean
) is 'Returns only published public wiki content, filtered by listener progress or an explicit spoiler opt-in.';

comment on function public.has_public_story_wiki(uuid)
is 'Returns whether a published story has an enabled public wiki.';

commit;

-- Smoke test after applying 004, 005 and this migration:
-- select public.get_public_story_wiki(
--     'life-inside-the-dyson', null, 1, 10, false
-- );
