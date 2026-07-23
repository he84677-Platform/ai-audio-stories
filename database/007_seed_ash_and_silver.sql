-- 007_seed_ash_and_silver.sql
-- Creates or updates the story "Ash and Silver" and its ten Season 1 episodes.
-- Safe to rerun.
--
-- Notes:
--   * The story and episodes are published so they appear on the current website.
--   * audio_url is inserted as an empty string so this script also works where
--     audio_url is NOT NULL. The website should not show an audio player for an
--     empty value.
--   * Existing audio, artwork, scripts, word counts and durations are preserved
--     when the script is rerun.

BEGIN;

DO $$
DECLARE
    v_story_id uuid;
BEGIN
    INSERT INTO public.stories
    (
        slug,
        title,
        short_description,
        description,
        cover_image_url,
        content_status,
        published_at
    )
    VALUES
    (
        'ash-and-silver',
        'Ash and Silver',
        'A gifted clockmaker''s daughter steals secrets for the challenge, then discovers an ancient mystery that no ordinary lock can contain.',
        'Elara is a clockmaker''s daughter with an instinct for small mechanisms and more curiosity than caution. Clockmaking came easily, lock-picking followed naturally, and stealing information became the most interesting puzzle the city could offer. She is already an accomplished thief before magic ever enters her life.

When a sealed letter disappears before she can steal it, Elara follows the story left behind by locks, gears, hidden rooms and altered stone. Her search draws her beneath the capital, through noble intrigues and towards fragments of an ancient civilisation misunderstood by the modern world.

A quietly decent noble named Cedric notices the elusive thief and chases her across the city, but this is Elara''s story. Their rivalry becomes respect only after he learns that she has been following a far more important mystery. As the stakes grow, Elara begins to experience powers she neither expected nor understands.',
        NULL,
        'published',
        now()
    )
    ON CONFLICT (slug)
    DO UPDATE SET
        title = EXCLUDED.title,
        short_description = EXCLUDED.short_description,
        description = EXCLUDED.description,
        content_status = EXCLUDED.content_status,
        published_at = COALESCE(public.stories.published_at, EXCLUDED.published_at),
        updated_at = now()
    RETURNING id INTO v_story_id;

    INSERT INTO public.episodes
    (
        story_id,
        season_number,
        episode_number,
        title,
        summary,
        audio_url,
        artwork_url,
        duration_seconds,
        is_free,
        episode_status,
        published_at,
        script_text,
        word_count
    )
    VALUES
        (
            v_story_id, 1, 1, 'The Clockmaker''s Daughter',
            'Elara spends her days repairing clocks beside her hardworking father and her nights accepting small thefts that challenge her curiosity more than her conscience. In the market she briefly notices a young noble treating ordinary people with unexpected respect, but he is only a passing detail in her day. That evening she enters a merchant''s home to steal a sealed letter and discovers that someone reached it first.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 2, 'Every Lock Tells a Story',
            'Unwilling to accept that another thief beat her, Elara studies the merchant''s locks, windows and hidden compartments as evidence. A memory of her father teaching her that every mechanism tells a story helps her recognise that the missing letter was never the only prize. During a second job, the noble she noticed in the market nearly catches her and unknowingly begins the hunt for the city''s most elusive thief.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 3, 'The Fox''s Game',
            'Cedric''s search becomes a challenge Elara cannot resist. She leads him through rooftops, workshops and crowded streets while continuing her own investigation, always escaping through preparation and knowledge of the city rather than luck. Beneath one of the capital''s oldest buildings she finds an unfamiliar symbol carved into stone that predates everything around it.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 4, 'One Step Ahead',
            'Cedric finally corners Elara after learning to anticipate several of her favourite routes. She escapes through wit, but not before showing him the evidence of a much greater theft committed while he was chasing her. Cedric realises she has been following a genuine conspiracy, and the contest between hunter and thief ends with neither of them winning.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 5, 'The Broken Mechanism',
            'Back in the workshop, Elara compares the ancient symbol with old mechanical drawings, damaged clockwork and designs collected through years of repairs. Her father sees only another puzzle occupying his daughter, unaware of how dangerous it may become. Elara discovers that the symbol behaves less like writing and more like one piece of a much larger mechanism.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 6, 'Beneath the City',
            'Elara follows the pattern into forgotten tunnels below the capital and finds machinery unlike anything made by modern craftsmen. Her ordinary skills allow her to wake one small part of it, proving that the ancient builders expected their work to be understood. When the darkness suddenly appears as clear as daylight from somewhere above her, Elara experiences the first hint of an ability she cannot explain.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 7, 'Whispers',
            'Missing documents and secret meetings unsettle the noble houses, drawing guards and political agents into Elara''s path. She cares more about the ancient machinery than court rivalries, but the same people appear behind both mysteries. Cedric investigates from within the nobility while Elara moves through the places its members believe are invisible.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 8, 'The Old Tongue',
            'An abandoned shrine outside the city contains the same designs found beneath the capital. Among them Elara discovers the repeated word VAELOR, a name modern scholars cannot translate with confidence. Touching the carving produces a disturbing sense of recognition and strengthens her fear that the impossible moment beneath the city was not imagination.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 9, 'The Missing Piece',
            'Elara learns that the original letter was one fragment of a larger puzzle connecting old ruins, political alliances and a history deliberately misunderstood. Cedric reaches part of the same conclusion through court records and private conversations. Their investigations collide, forcing them to exchange information while both remain careful not to call the arrangement trust.',
            '', NULL, 0, true, 'published', now(), '', 0
        ),
        (
            v_story_id, 1, 10, 'Ash and Silver',
            'Elara and Cedric prevent the stolen documents from being used to ignite conflict between rival houses, but the political conspiracy proves to be only the surface of the mystery. Deep beneath the city, Elara opens an ancient mechanism by listening to the story told by its damaged parts. Beyond it waits another door, the name VAELOR and the first undeniable sign that something within Elara has begun to awaken.',
            '', NULL, 0, true, 'published', now(), '', 0
        )
    ON CONFLICT (story_id, episode_number)
    DO UPDATE SET
        season_number = EXCLUDED.season_number,
        title = EXCLUDED.title,
        summary = EXCLUDED.summary,
        is_free = EXCLUDED.is_free,
        episode_status = EXCLUDED.episode_status,
        published_at = COALESCE(public.episodes.published_at, EXCLUDED.published_at),
        updated_at = now(),
        -- Preserve production assets and completed scripts on rerun.
        audio_url = CASE
            WHEN COALESCE(public.episodes.audio_url, '') <> ''
                THEN public.episodes.audio_url
            ELSE EXCLUDED.audio_url
        END,
        artwork_url = COALESCE(public.episodes.artwork_url, EXCLUDED.artwork_url),
        script_text = CASE
            WHEN COALESCE(public.episodes.script_text, '') <> ''
                THEN public.episodes.script_text
            ELSE EXCLUDED.script_text
        END,
        word_count = CASE
            WHEN COALESCE(public.episodes.word_count, 0) > 0
                THEN public.episodes.word_count
            ELSE EXCLUDED.word_count
        END,
        duration_seconds = CASE
            WHEN COALESCE(public.episodes.duration_seconds, 0) > 0
                THEN public.episodes.duration_seconds
            ELSE EXCLUDED.duration_seconds
        END;
END
$$;

COMMIT;

-- Verification
SELECT
    s.slug,
    s.title,
    s.content_status,
    COUNT(e.id) AS episode_count,
    MIN(e.episode_number) AS first_episode,
    MAX(e.episode_number) AS last_episode
FROM public.stories AS s
LEFT JOIN public.episodes AS e
    ON e.story_id = s.id
WHERE s.slug = 'ash-and-silver'
GROUP BY
    s.slug,
    s.title,
    s.content_status;

SELECT
    e.season_number,
    e.episode_number,
    e.title,
    e.episode_status,
    e.duration_seconds,
    e.word_count
FROM public.episodes AS e
INNER JOIN public.stories AS s
    ON s.id = e.story_id
WHERE s.slug = 'ash-and-silver'
ORDER BY
    e.season_number,
    e.episode_number;
