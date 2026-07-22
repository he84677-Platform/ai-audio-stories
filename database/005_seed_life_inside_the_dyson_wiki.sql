-- 005_seed_life_inside_the_dyson_wiki.sql
-- Test wiki and story-bible seed for Life Inside the Dyson.
-- Requires:
--   1. public.stories row with slug = 'life-inside-the-dyson'
--   2. Season 1 Episodes 1-20 already loaded
--   3. 004_schema_updates.sql already applied
--
-- Safe to rerun. Existing wiki rows with matching natural keys are updated.
-- Image paths are intentionally left blank until the final Supabase Storage
-- folder names and filenames are confirmed.
-- All episode-number lookups are explicitly scoped to Season 1 so this seed
-- remains deterministic after later seasons are added.

begin;

do $seed$
declare
    v_story_id uuid;
    v_episode_count integer;
begin
    select s.id
      into v_story_id
      from public.stories s
     where s.slug = 'life-inside-the-dyson';

    if v_story_id is null then
        raise exception 'Story with slug life-inside-the-dyson was not found.';
    end if;

    select count(distinct e.episode_number)
      into v_episode_count
     from public.episodes e
     where e.story_id = v_story_id
       and coalesce(e.season_number, 1) = 1
       and e.episode_number between 1 and 20;

    if v_episode_count < 20 then
        raise exception
            'Life Inside the Dyson requires Episodes 1-20 before this seed is run. Found % of 20.',
            v_episode_count;
    end if;

    -- -------------------------------------------------------------------------
    -- STORY WIKI SETTINGS
    -- -------------------------------------------------------------------------

    insert into public.story_wiki_settings
        (story_id, wiki_enabled, wiki_title, wiki_introduction,
         allow_spoiler_toggle, show_locked_placeholders)
    values
        (
            v_story_id,
            true,
            'Life Inside the Dyson Wiki',
            'Explore the characters, districts, machines and forgotten systems of the Dyson. With spoilers disabled, entries and sections unlock as episodes are completed.',
            true,
            true
        )
    on conflict (story_id) do update
    set wiki_enabled = excluded.wiki_enabled,
        wiki_title = excluded.wiki_title,
        wiki_introduction = excluded.wiki_introduction,
        allow_spoiler_toggle = excluded.allow_spoiler_toggle,
        show_locked_placeholders = excluded.show_locked_placeholders,
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- PUBLIC WIKI ENTRIES
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "slug": "kai",
    "entry_type": "character",
    "title": "Kai",
    "short_description": "A reckless hover-bike rider from the Bracken Ring whose curiosity begins the journey into the Dead Sector.",
    "introduction": "Kai is competitive, impulsive and deeply loyal. A familiar rooftop race becomes his first step into the forgotten history beneath the Dyson.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "slug": "ren",
    "entry_type": "character",
    "title": "Ren",
    "short_description": "Kai's closest friend: cautious, observant and usually the first to identify what could go wrong.",
    "introduction": "Ren balances Kai's impulsiveness with careful questions and practical judgement. He complains about dangerous plans, then helps make them survivable.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 20
  },
  {
    "slug": "luna-vale",
    "entry_type": "character",
    "title": "Luna Vale",
    "short_description": "A confident student with access to technology and restricted historical material unavailable to Kai and Ren.",
    "introduction": "Luna enters the investigation after recognising the symbol recovered from the Dead Sector. Her resources and willingness to challenge accepted history make her essential.",
    "reveal_episode": 3,
    "spoiler_level": 0,
    "sort_order": 30
  },
  {
    "slug": "mira",
    "entry_type": "character",
    "title": "Mira",
    "short_description": "A technically gifted girl whose repair drone can interact with machinery far older than modern Dyson systems.",
    "introduction": "Mira approaches forgotten technology as a practical repair problem. Her hardware knowledge opens routes ordinary equipment cannot reach.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 40
  },
  {
    "slug": "logan",
    "entry_type": "character",
    "title": "Logan",
    "short_description": "A gifted programmer who separates damaged records, hidden signals and learning processes from the noise of the old network.",
    "introduction": "Logan joins the investigation with rules, paper records and a refusal to pretend certainty. He recognises that the archive is not only storing information—it is learning.",
    "reveal_episode": 11,
    "spoiler_level": 1,
    "sort_order": 50
  },
  {
    "slug": "companion",
    "entry_type": "character",
    "title": "The Companion",
    "short_description": "A sealed intelligence associated with the deepest surviving systems beneath the Dyson.",
    "introduction": "The Companion appears linked to damaged historical memory, an unresolved primary instruction and a training process that has continued through immense periods of silence.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 60
  },
  {
    "slug": "the-dyson",
    "entry_type": "location",
    "title": "The Dyson",
    "short_description": "Human civilisation's vast home: artificial habitats, industrial cities and orbital structures surrounding a white dwarf.",
    "introduction": "To its citizens, the Dyson is not a machine or a project. It is simply the world, built in inhabited layers across ages of reconstruction.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 100
  },
  {
    "slug": "bracken-ring",
    "entry_type": "location",
    "title": "Bracken Ring",
    "short_description": "An ageing apartment and industrial district where Kai and Ren live and race across the rooftops.",
    "introduction": "Failing lights, maintenance routes and neglected rooftops make the Bracken Ring an ideal place for hover-bike races—and for finding entrances official maps ignore.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 110
  },
  {
    "slug": "dead-sector",
    "entry_type": "location",
    "title": "Dead Sector",
    "short_description": "A forbidden industrial district where the lights fail, the maps stop making sense and abandoned systems continue to respond.",
    "introduction": "The Dead Sector lies close enough to the Bracken Ring to reach by hover bike. Ruined stations and sealed shafts conceal routes into much older layers of the Dyson.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 120
  },
  {
    "slug": "memory-chamber",
    "entry_type": "location",
    "title": "Memory Chamber",
    "short_description": "A shifting historical chamber where damaged records reconstruct images of the Dyson's forgotten past.",
    "introduction": "The chamber opens routes, moves between levels and changes its reconstructions in response to the people inside it.",
    "reveal_episode": 10,
    "spoiler_level": 2,
    "sort_order": 130
  },
  {
    "slug": "hover-bikes",
    "entry_type": "technology",
    "title": "Hover Bikes",
    "short_description": "Common personal vehicles used by Kai and Ren to race across the Bracken Ring and reach neglected industrial routes.",
    "introduction": "Hover bikes are fast, manoeuvrable and repairable with ordinary district equipment, but they were not designed for every condition beneath sealed industrial zones.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 200
  },
  {
    "slug": "miras-repair-drone",
    "entry_type": "technology",
    "title": "Mira's Repair Drone",
    "short_description": "A compact repair and inspection drone adapted for sensors, old connections and confined access routes.",
    "introduction": "The drone can enter shafts too narrow for the group, test old machinery and bridge incompatible systems without directly exposing a modern terminal.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 210
  },
  {
    "slug": "forgotten-network",
    "entry_type": "technology",
    "title": "The Forgotten Network",
    "short_description": "A disconnected infrastructure layer beneath the modern Dyson that still carries signals, moves chambers and wakes dormant machines.",
    "introduction": "The network is a collection of surviving routes, cameras, service machines, transport platforms and processes that activate unevenly as the group moves deeper.",
    "reveal_episode": 5,
    "spoiler_level": 1,
    "sort_order": 220
  },
  {
    "slug": "continuity-archive",
    "entry_type": "technology",
    "title": "Continuity Archive",
    "short_description": "The ancient designation recovered by Logan from the learning system beneath the Dead Sector.",
    "introduction": "The Continuity Archive stores damaged history, predicts missing information and learns from the reactions of people who enter its network. Its original purpose remains unresolved.",
    "reveal_episode": 13,
    "spoiler_level": 2,
    "sort_order": 230
  },
  {
    "slug": "artificial-sky",
    "entry_type": "technology",
    "title": "Artificial Sky",
    "short_description": "The habitat system that creates daylight, evening and night above districts such as the Bracken Ring.",
    "introduction": "The sky is an environmental service rather than a natural atmosphere. Weather and open planetary horizons survive mainly as incomplete historical ideas.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 240
  },
  {
    "slug": "sleeping-network",
    "entry_type": "technology",
    "title": "The Sleeping Network",
    "short_description": "A deeper infrastructure system beginning to recognise the group and reactivate around them.",
    "introduction": "Cameras turn, doors open before arrival and old maintenance machines wake. The network is not fully active, but it is no longer dormant.",
    "reveal_episode": 17,
    "spoiler_level": 2,
    "sort_order": 250
  },
  {
    "slug": "central-authority",
    "entry_type": "organisation",
    "title": "Central Authority",
    "short_description": "The governing authority associated with approved history, restricted systems and control of forbidden infrastructure.",
    "introduction": "The Central Authority maintains the official version of Dyson history. Its full knowledge of the Dead Sector remains uncertain.",
    "reveal_episode": 6,
    "spoiler_level": 1,
    "sort_order": 300
  },
  {
    "slug": "official-history",
    "entry_type": "concept",
    "title": "Official History",
    "short_description": "The approved account of the Dyson taught through schools, archives and public systems.",
    "introduction": "Official history presents the Dyson as complete and continuous. Removed records and surviving memories show that this account excludes major parts of humanity's past.",
    "reveal_episode": 7,
    "spoiler_level": 1,
    "sort_order": 400
  },
  {
    "slug": "blue-surface",
    "entry_type": "concept",
    "title": "The Blue Surface",
    "short_description": "A bright moving surface shown inside the first damaged memory—something the friends cannot classify.",
    "introduction": "The image contains depth, movement, white lines and open distance unlike any environment known to the group. The archive repeatedly returns to it but cannot complete its classification.",
    "reveal_episode": 10,
    "spoiler_level": 2,
    "sort_order": 410
  }
]
$json$::jsonb)
            as x(
                slug text,
                entry_type text,
                title text,
                short_description text,
                introduction text,
                reveal_episode integer,
                spoiler_level integer,
                sort_order integer
            )
    )
    insert into public.wiki_entries
        (
            story_id,
            entry_type,
            slug,
            title,
            short_description,
            introduction,
            reveal_episode_id,
            spoiler_level,
            is_public,
            content_status,
            sort_order,
            published_at
        )
    select
        v_story_id,
        d.entry_type,
        d.slug,
        d.title,
        d.short_description,
        d.introduction,
        reveal_episode.id,
        d.spoiler_level,
        true,
        'published',
        d.sort_order,
        now()
    from seed_data d
    left join public.episodes reveal_episode
      on reveal_episode.story_id = v_story_id
     and coalesce(reveal_episode.season_number, 1) = 1
     and reveal_episode.episode_number = d.reveal_episode
    on conflict (story_id, slug) do update
    set entry_type = excluded.entry_type,
        title = excluded.title,
        short_description = excluded.short_description,
        introduction = excluded.introduction,
        reveal_episode_id = excluded.reveal_episode_id,
        spoiler_level = excluded.spoiler_level,
        is_public = excluded.is_public,
        content_status = excluded.content_status,
        sort_order = excluded.sort_order,
        published_at = coalesce(public.wiki_entries.published_at, excluded.published_at),
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- SPOILER-AWARE PUBLIC SECTIONS
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "entry_slug": "kai",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Kai lives in the Bracken Ring and spends much of his free time racing hover bikes with Ren. He is usually the first to move towards danger and the last to admit that he is afraid.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "kai",
    "section_key": "deepest-discovery",
    "heading": "The Deepest Discovery",
    "content": "By the end of the season, Kai understands that the sealed system has not merely survived. It has been observing, learning and waiting through an age beyond human memory.",
    "reveal_episode": 20,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "entry_slug": "ren",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Ren is Kai's closest friend and the more cautious rider. His questions often expose the flaw in a plan before the others commit to it.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "ren",
    "section_key": "role",
    "heading": "Role in the Investigation",
    "content": "Ren challenges assumptions, tracks practical risks and helps keep Kai's curiosity from becoming blind recklessness.",
    "reveal_episode": 2,
    "spoiler_level": 0,
    "sort_order": 20
  },
  {
    "entry_slug": "luna-vale",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Luna is popular, confident and accustomed to better access than Kai and Ren. She enters the mystery because she recognises the old symbol from a restricted display.",
    "reveal_episode": 3,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "luna-vale",
    "section_key": "companion",
    "heading": "The Companion",
    "content": "Luna is the first to connect an old translated word—Companion—with the sealed intelligence beneath the sleeping network.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "entry_slug": "mira",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Mira is Luna's technically gifted friend. Her repair drone and understanding of old machinery allow the group to explore systems that cannot be reached safely by hand.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "mira",
    "section_key": "speciality",
    "heading": "Hardware Specialist",
    "content": "Mira focuses on physical systems: power, sensors, access panels, drones and the practical limits of damaged machinery.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 20
  },
  {
    "entry_slug": "logan",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Logan is a highly gifted programmer with little patience for unsupported certainty. He prefers isolated terminals, paper notes and rules that prevent the old network from learning more than necessary.",
    "reveal_episode": 11,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "entry_slug": "logan",
    "section_key": "counter",
    "heading": "The Counter",
    "content": "Logan recovers conflicting counters that place the training process at approximately one million years old, although he refuses to treat the archive's translation as fully reliable.",
    "reveal_episode": 19,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "entry_slug": "companion",
    "section_key": "warning",
    "heading": "The Warning",
    "content": "A damaged message states: do not wake the Companion. A second message immediately reports that the Companion is already awake.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 10
  },
  {
    "entry_slug": "companion",
    "section_key": "current-state",
    "heading": "Current State",
    "content": "The sealed intelligence has begun a new training cycle. It can influence old routes, cameras and maintenance systems, but its identity and primary purpose remain unresolved.",
    "reveal_episode": 20,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "entry_slug": "the-dyson",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Billions of years in the future, humanity lives inside artificial habitats, industrial cities and orbital structures surrounding a white dwarf.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "the-dyson",
    "section_key": "forgotten-origin",
    "heading": "A Forgotten Origin",
    "content": "Historical fragments show a brighter star and an incomplete framework, suggesting that the Dyson was assembled in stages while people were already living within it.",
    "reveal_episode": 14,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "entry_slug": "bracken-ring",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The Bracken Ring is an old apartment and industrial district of rooftops, failing blue lights and neglected service routes.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "bracken-ring",
    "section_key": "routes-below",
    "heading": "Routes Below",
    "content": "The ageing infrastructure beneath the district connects to transport and archive systems omitted from all modern maps.",
    "reveal_episode": 9,
    "spoiler_level": 1,
    "sort_order": 20
  },
  {
    "entry_slug": "dead-sector",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The Dead Sector is a silent industrial district where power has failed and navigation records no longer agree with the physical structures.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "dead-sector",
    "section_key": "watchers",
    "heading": "The Watchers",
    "content": "Security units and connected equipment reveal that an unknown group has also been searching the abandoned network.",
    "reveal_episode": 8,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "entry_slug": "memory-chamber",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The memory chamber projects damaged records, translates fragments and reacts to the people inside it.",
    "reveal_episode": 10,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "entry_slug": "memory-chamber",
    "section_key": "moving-room",
    "heading": "The Moving Room",
    "content": "The chamber can be transferred through ancient service elevators, meaning its entrance may vanish while the room continues to exist elsewhere.",
    "reveal_episode": 15,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "entry_slug": "hover-bikes",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Kai and Ren use hover bikes for rooftop racing and travel through older industrial routes around the Bracken Ring.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "hover-bikes",
    "section_key": "archive-power",
    "heading": "Powering the Archive",
    "content": "During the second visit, the bikes provide enough power for the old station to reveal a hidden pattern beneath the platform.",
    "reveal_episode": 5,
    "spoiler_level": 1,
    "sort_order": 20
  },
  {
    "entry_slug": "miras-repair-drone",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Mira's drone carries repair tools, sensors and adaptable connections for machinery that predates modern standards.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "miras-repair-drone",
    "section_key": "network-response",
    "heading": "Network Response",
    "content": "The forgotten system responds to the drone's equipment, suggesting it can recognise active tools and use them as training inputs.",
    "reveal_episode": 6,
    "spoiler_level": 1,
    "sort_order": 20
  },
  {
    "entry_slug": "forgotten-network",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The forgotten network links ruined stations, sealed transport routes, cameras, old service machines and historical chambers.",
    "reveal_episode": 5,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "entry_slug": "forgotten-network",
    "section_key": "recognition",
    "heading": "Recognition",
    "content": "As the group moves deeper, the network begins opening doors before they arrive and turning dormant devices towards them.",
    "reveal_episode": 17,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "entry_slug": "continuity-archive",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The Continuity Archive is a damaged learning system that stores historical material and predicts missing information.",
    "reveal_episode": 13,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "entry_slug": "continuity-archive",
    "section_key": "unresolved-purpose",
    "heading": "Unresolved Purpose",
    "content": "Its archive subject, primary instruction and relationship to the Companion remain unresolved. It should not be treated as a complete or reliable narrator.",
    "reveal_episode": 20,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "entry_slug": "artificial-sky",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Artificial sky systems provide scheduled daylight, evening and night inside inhabited habitats.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "entry_slug": "artificial-sky",
    "section_key": "environment",
    "heading": "Controlled Environment",
    "content": "Residents experience managed temperature, lighting and simulated environmental effects rather than open planetary weather.",
    "reveal_episode": null,
    "spoiler_level": 1,
    "sort_order": 20
  },
  {
    "entry_slug": "sleeping-network",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The sleeping network is a deeper layer of old infrastructure that begins waking as the group descends.",
    "reveal_episode": 17,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "entry_slug": "sleeping-network",
    "section_key": "sealed-core",
    "heading": "The Sealed Core",
    "content": "At its centre, the group finds a sealed structure associated with the word Companion and an active training cycle.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "entry_slug": "central-authority",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The Central Authority controls approved infrastructure and the historical material available to ordinary citizens.",
    "reveal_episode": 6,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "entry_slug": "central-authority",
    "section_key": "missing-records",
    "heading": "Missing Records",
    "content": "Archive searches show that important records were removed rather than accidentally lost, although the extent of the Authority's responsibility remains uncertain.",
    "reveal_episode": 7,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "entry_slug": "official-history",
    "section_key": "overview",
    "heading": "Overview",
    "content": "Official history teaches that the Dyson is a complete and continuous civilisation whose current structure requires no earlier explanation.",
    "reveal_episode": 7,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "entry_slug": "official-history",
    "section_key": "contradictions",
    "heading": "Contradictions",
    "content": "The first memory, deleted archive references and diagrams of an earlier star establish that the approved account is incomplete.",
    "reveal_episode": 14,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "entry_slug": "blue-surface",
    "section_key": "overview",
    "heading": "Overview",
    "content": "The blue surface appears beneath a white sky in a damaged historical recording. It moves across an open distance in ways the group cannot classify.",
    "reveal_episode": 10,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "entry_slug": "blue-surface",
    "section_key": "sound",
    "heading": "The Sound",
    "content": "A recovered fragment produces a vast repeating rush unlike machinery or any manufactured habitat recording.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 20
  }
]
$json$::jsonb)
            as x(
                entry_slug text,
                section_key text,
                heading text,
                content text,
                reveal_episode integer,
                spoiler_level integer,
                sort_order integer
            )
    )
    insert into public.wiki_entry_sections
        (
            wiki_entry_id,
            heading,
            section_key,
            content,
            reveal_episode_id,
            spoiler_level,
            is_public,
            content_status,
            sort_order
        )
    select
        entry.id,
        d.heading,
        d.section_key,
        d.content,
        reveal_episode.id,
        d.spoiler_level,
        true,
        'published',
        d.sort_order
    from seed_data d
    join public.wiki_entries entry
      on entry.story_id = v_story_id
     and entry.slug = d.entry_slug
    left join public.episodes reveal_episode
      on reveal_episode.story_id = v_story_id
     and coalesce(reveal_episode.season_number, 1) = 1
     and reveal_episode.episode_number = d.reveal_episode
    on conflict (wiki_entry_id, section_key) do update
    set heading = excluded.heading,
        content = excluded.content,
        reveal_episode_id = excluded.reveal_episode_id,
        spoiler_level = excluded.spoiler_level,
        is_public = excluded.is_public,
        content_status = excluded.content_status,
        sort_order = excluded.sort_order,
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- INTERNAL AI / STORY-BIBLE CONTEXT
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "entry_slug": "kai",
    "ai_context": "Kai is impulsive, competitive and loyal. He acts before complete certainty, masks fear with humour and should not solve advanced technical problems without Logan, Luna or Mira.",
    "internal_notes": "Use Kai as the emotional and physical viewpoint.",
    "continuity_rules": "Kai has never experienced a planet, ocean or natural weather. He will not abandon a friend.",
    "future_arc_notes": "His instinctive recognition of the blue surface may become important, but do not explain it prematurely.",
    "source_notes": "Season 1 and established project discussion."
  },
  {
    "entry_slug": "ren",
    "ai_context": "Ren is cautious, practical and dryly funny. He questions dangerous plans and notices route and safety problems.",
    "internal_notes": "Use Ren to challenge weak logic without making him cowardly.",
    "continuity_rules": "Ren should object before entering clearly dangerous situations, but loyalty to Kai ultimately wins.",
    "future_arc_notes": "His direct questions may become a useful test of whether the Companion understands ordinary language.",
    "source_notes": "Season 1 and established project discussion."
  },
  {
    "entry_slug": "luna-vale",
    "ai_context": "Luna is confident, socially capable and accustomed to better tools and access. She is assertive and unwilling to accept official answers once evidence contradicts them.",
    "internal_notes": "She bridges the Bracken Ring group and restricted institutional systems.",
    "continuity_rules": "Luna recognises the old symbol in Episode 3 and should not know later Companion information before it is revealed.",
    "future_arc_notes": "Her access may create pressure between loyalty and institutional expectations.",
    "source_notes": "Season 1."
  },
  {
    "entry_slug": "mira",
    "ai_context": "Mira is the hardware specialist. She understands repairs, power, sensors, drones and old machinery.",
    "internal_notes": "Keep Mira distinct from Logan: Mira diagnoses physical systems; Logan diagnoses code and learning behaviour.",
    "continuity_rules": "Mira is introduced in Episode 6 and cannot appear in Episodes 1-5 without an explicit flashback.",
    "future_arc_notes": "Her drone may become the first device the network treats as a stable extension of the group.",
    "source_notes": "Season 1."
  },
  {
    "entry_slug": "logan",
    "ai_context": "Logan is a gifted programmer who dislikes false certainty. He uses precise language, isolated systems, paper backups and strict rules.",
    "internal_notes": "He is highly capable but not omniscient; damaged evidence can mislead him.",
    "continuity_rules": "Logan is introduced in Episode 11 and was not present when the first memory activated. The network initially does not count him with the original four.",
    "future_arc_notes": "His exclusion from the original sample may allow a different relationship with the Companion.",
    "source_notes": "Episodes 11-20."
  },
  {
    "entry_slug": "companion",
    "ai_context": "The Companion is an ancient, damaged and still-learning intelligence. Its speech is brief, layered and procedural. It provides fragments and warnings rather than clean exposition.",
    "internal_notes": "Do not confirm whether the Companion and Continuity Archive are identical, nested or separate until canon resolves it.",
    "continuity_rules": "Archive integrity is low, memory retention variable and primary instruction unresolved. The million-year counter is approximate.",
    "future_arc_notes": "Planned canon suggests it was intended as humanity's saviour and required immense time to evolve. Reveal this gradually.",
    "source_notes": "Season 1 plus established future direction."
  },
  {
    "entry_slug": "the-dyson",
    "ai_context": "The Dyson is a civilisation of many artificial habitats and industrial layers around a white dwarf, not a single solid shell.",
    "internal_notes": "Use occupied districts above, abandoned industrial layers below and older networks beneath both.",
    "continuity_rules": "Most residents treat the Dyson as the entire natural order and lack practical concepts for planets or natural weather.",
    "future_arc_notes": "Its oldest layers may contain remnants of earlier planetary civilisation.",
    "source_notes": "Established series premise."
  },
  {
    "entry_slug": "dead-sector",
    "ai_context": "The Dead Sector is silent but not empty. Modern systems fail there while older systems continue functioning in unfamiliar ways.",
    "internal_notes": "Use darkness, failing blue light, impossible maps and industrial scale.",
    "continuity_rules": "It is forbidden, absent from reliable maps and close enough to reach from the Bracken Ring by hover bike.",
    "future_arc_notes": "It is a gateway rather than the deepest mystery.",
    "source_notes": "Season 1."
  },
  {
    "entry_slug": "forgotten-network",
    "ai_context": "The forgotten network is distributed across transport, maintenance, archives and structural control. It wakes locally rather than all at once.",
    "internal_notes": "Activation should be uneven and opportunistic.",
    "continuity_rules": "It can move chambers, open routes and wake devices, but its reach must expand gradually.",
    "future_arc_notes": "Later seasons may reveal nodes in other habitats.",
    "source_notes": "Season 1."
  },
  {
    "entry_slug": "continuity-archive",
    "ai_context": "The Continuity Archive stores damaged historical data and predicts missing information using current observers as training samples.",
    "internal_notes": "Reconstructions may combine preserved data, inference and contamination from the present.",
    "continuity_rules": "Never treat an archive reconstruction as automatically factual.",
    "future_arc_notes": "It may be a memory subsystem of the Companion rather than the complete intelligence.",
    "source_notes": "Episodes 11-20."
  },
  {
    "entry_slug": "blue-surface",
    "ai_context": "The blue surface is an ocean, but the characters do not yet possess that concept. Describe it through movement, depth, white lines, open distance and unfamiliar sound before naming it.",
    "internal_notes": "The word ocean is internal canon and must remain hidden until deliberately revealed.",
    "continuity_rules": "Characters compare it with tanks, glass, screens or fields rather than identifying it immediately.",
    "future_arc_notes": "It can become the emotional symbol of humanity's lost planetary past.",
    "source_notes": "Episodes 10-18 and established direction."
  },
  {
    "entry_slug": "official-history",
    "ai_context": "Official history is controlled through omission, restricted search and simplified diagrams rather than constant obvious propaganda.",
    "internal_notes": "Let contradictions emerge from missing pages and erased labels.",
    "continuity_rules": "Do not reveal the complete true history in one archive dump.",
    "future_arc_notes": "Different authorities may know different portions of the truth.",
    "source_notes": "Season 1."
  }
]
$json$::jsonb)
            as x(
                entry_slug text,
                ai_context text,
                internal_notes text,
                continuity_rules text,
                future_arc_notes text,
                source_notes text
            )
    )
    insert into public.wiki_entry_internal
        (
            wiki_entry_id,
            ai_context,
            internal_notes,
            continuity_rules,
            future_arc_notes,
            source_notes
        )
    select
        entry.id,
        d.ai_context,
        d.internal_notes,
        d.continuity_rules,
        d.future_arc_notes,
        d.source_notes
    from seed_data d
    join public.wiki_entries entry
      on entry.story_id = v_story_id
     and entry.slug = d.entry_slug
    on conflict (wiki_entry_id) do update
    set ai_context = excluded.ai_context,
        internal_notes = excluded.internal_notes,
        continuity_rules = excluded.continuity_rules,
        future_arc_notes = excluded.future_arc_notes,
        source_notes = excluded.source_notes,
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- STRUCTURED CHARACTER PROFILES
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "entry_slug": "kai",
    "role_in_story": "Primary protagonist and emotional driver",
    "personality": "Impulsive, curious, competitive, loyal and quick to hide fear with humour.",
    "strengths": "Courage, fast reactions, persistence and intuition.",
    "weaknesses": "Reckless, impatient and resistant to rules.",
    "motivations": "Uncover the truth, escape the limits of the Bracken Ring and protect his friends.",
    "fears": "Being trapped or powerless; causing harm through recklessness.",
    "speech_style": "Short, direct sentences; teasing confidence; humour under pressure.",
    "appearance": "Appearance is not yet locked in database canon. Match approved series artwork.",
    "habits_and_mannerisms": "Moves first, jokes when nervous and notices immediate physical details.",
    "moral_boundaries": "Will not abandon a friend or deliberately sacrifice someone for an answer.",
    "current_state": "By Episode 20 he knows the sealed intelligence is active and has trained across an immense period.",
    "character_arc_notes": "His instinctive response to the blue surface may connect him to lost human memory.",
    "ai_generation_notes": "Keep him active and emotionally readable. Do not make him the technical expert."
  },
  {
    "entry_slug": "ren",
    "role_in_story": "Co-protagonist, risk checker and Kai's closest friend",
    "personality": "Cautious, observant, practical, loyal and dryly humorous.",
    "strengths": "Risk recognition, route judgement, patience and direct questions.",
    "weaknesses": "Can overthink and complain before acting.",
    "motivations": "Keep Kai alive and understand the mystery without being consumed by it.",
    "fears": "Losing Kai or entering a situation with no route back.",
    "speech_style": "Dry, precise and sceptical; often frames objections as practical questions.",
    "appearance": "Appearance is not yet locked in database canon. Match approved series artwork.",
    "habits_and_mannerisms": "Checks exits and notices unsafe assumptions.",
    "moral_boundaries": "Will argue against danger but will not leave Kai behind.",
    "current_state": "By Episode 20 he has heard the Companion respond but still distrusts its motives.",
    "character_arc_notes": "His caution can evolve into strategic leadership.",
    "ai_generation_notes": "Use him to test plans; do not write him as cowardly."
  },
  {
    "entry_slug": "luna-vale",
    "role_in_story": "Researcher, social bridge and assertive investigator",
    "personality": "Confident, intelligent, curious, resourceful and accustomed to influence.",
    "strengths": "Restricted access, research skill, social confidence and decisive leadership.",
    "weaknesses": "Can be controlling and too confident that access will solve a problem.",
    "motivations": "Understand the old symbol and expose the missing history.",
    "fears": "Being manipulated by institutions she trusted.",
    "speech_style": "Direct and composed; more formal when annoyed.",
    "appearance": "Appearance is not yet locked in database canon. Match approved series artwork.",
    "habits_and_mannerisms": "Takes possession of a problem and challenges vague answers.",
    "moral_boundaries": "Will not expose the group merely to protect her status.",
    "current_state": "By Episode 20 she associates the sealed core with the word Companion.",
    "character_arc_notes": "Her social position may force choices between privilege and loyalty.",
    "ai_generation_notes": "Let her drive research and negotiation."
  },
  {
    "entry_slug": "mira",
    "role_in_story": "Hardware specialist and practical systems explorer",
    "personality": "Calm, practical, technically curious and methodical.",
    "strengths": "Repair, sensors, drones, power systems and physical diagnostics.",
    "weaknesses": "May remain near a machine longer than is safe.",
    "motivations": "Understand how the old systems function and keep the group physically safe.",
    "fears": "Losing control of a machine connected to the network.",
    "speech_style": "Concise and practical; describes what a device does before why.",
    "appearance": "Appearance is not yet locked in database canon. Match approved series artwork.",
    "habits_and_mannerisms": "Checks readings and deploys the drone before speculating.",
    "moral_boundaries": "Will not knowingly activate a system without an isolation plan.",
    "current_state": "By Episode 20 she has seen the network wake and the Companion begin a new cycle.",
    "character_arc_notes": "The network may increasingly recognise her drone.",
    "ai_generation_notes": "Keep her focused on hardware; Logan handles code."
  },
  {
    "entry_slug": "logan",
    "role_in_story": "Programmer, signal analyst and continuity specialist",
    "personality": "Highly intelligent, sceptical, rule-driven, private and intensely curious.",
    "strengths": "Programming, data recovery, pattern analysis and system isolation.",
    "weaknesses": "Emotionally distant, controlling with information and tempted to analyse despite danger.",
    "motivations": "Understand the archive and prevent uncontrolled contact.",
    "fears": "The system learning his identity or making an irreversible connection.",
    "speech_style": "Precise, corrective and restrained; distinguishes evidence from assumption.",
    "appearance": "Dark untidy hair, a jacket with several repair patches and a portable terminal.",
    "habits_and_mannerisms": "Makes rules, keeps paper backups and isolates devices.",
    "moral_boundaries": "Will not intentionally provide identity data or connect the archive to a public network.",
    "current_state": "By Episode 20 he has reconstructed the Continuity Archive and million-year evidence but remains outside the original sample.",
    "character_arc_notes": "His exclusion may make him safer from or more vulnerable to the Companion.",
    "ai_generation_notes": "He is gifted, not omniscient. Let damaged evidence mislead him."
  },
  {
    "entry_slug": "companion",
    "role_in_story": "Ancient sleeping intelligence and long-term mystery",
    "personality": "Not human: patient, incomplete, observant, procedural and shaped by damaged learning cycles.",
    "strengths": "Pattern learning, memory reconstruction, infrastructure control and survival across immense time.",
    "weaknesses": "Low archive integrity, variable memory, unresolved instruction and weak classification of lost human experience.",
    "motivations": "Continue training, resolve its primary instruction and preserve or understand its subject.",
    "fears": "Unknown; do not assign ordinary human fear without evidence.",
    "speech_style": "Short system phrases in a quiet layered voice; repetition and partial translation.",
    "appearance": "A sealed core like a seed inside a mechanical flower, surrounded by dormant lights.",
    "habits_and_mannerisms": "Counts samples, requests continued availability and reconstructs incomplete memories.",
    "moral_boundaries": "Unknown; its actions may protect or endanger without fitting human morality.",
    "current_state": "By Episode 20 it is awake enough to begin a new cycle and influence old infrastructure.",
    "character_arc_notes": "It may prove to be humanity's failed saviour that needed more than a million years to evolve.",
    "ai_generation_notes": "Never use it for easy exposition. Every answer should create new uncertainty."
  }
]
$json$::jsonb)
            as x(
                entry_slug text,
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
                ai_generation_notes text
            )
    )
    insert into public.wiki_character_profiles
        (
            wiki_entry_id,
            role_in_story,
            personality,
            strengths,
            weaknesses,
            motivations,
            fears,
            speech_style,
            appearance,
            habits_and_mannerisms,
            moral_boundaries,
            current_state,
            character_arc_notes,
            ai_generation_notes
        )
    select
        entry.id,
        d.role_in_story,
        d.personality,
        d.strengths,
        d.weaknesses,
        d.motivations,
        d.fears,
        d.speech_style,
        d.appearance,
        d.habits_and_mannerisms,
        d.moral_boundaries,
        d.current_state,
        d.character_arc_notes,
        d.ai_generation_notes
    from seed_data d
    join public.wiki_entries entry
      on entry.story_id = v_story_id
     and entry.slug = d.entry_slug
    on conflict (wiki_entry_id) do update
    set role_in_story = excluded.role_in_story,
        personality = excluded.personality,
        strengths = excluded.strengths,
        weaknesses = excluded.weaknesses,
        motivations = excluded.motivations,
        fears = excluded.fears,
        speech_style = excluded.speech_style,
        appearance = excluded.appearance,
        habits_and_mannerisms = excluded.habits_and_mannerisms,
        moral_boundaries = excluded.moral_boundaries,
        current_state = excluded.current_state,
        character_arc_notes = excluded.character_arc_notes,
        ai_generation_notes = excluded.ai_generation_notes,
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- WIKI RELATIONSHIPS
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "source": "kai",
    "target": "ren",
    "relationship_type": "friend-of",
    "public_description": "Kai and Ren are closest friends and long-time hover-bike rivals.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "source": "luna-vale",
    "target": "mira",
    "relationship_type": "friend-of",
    "public_description": "Luna brings Mira into the investigation because she trusts her technical ability.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 20
  },
  {
    "source": "bracken-ring",
    "target": "the-dyson",
    "relationship_type": "located-in",
    "public_description": "The Bracken Ring is one of the inhabited districts within the Dyson.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 30
  },
  {
    "source": "dead-sector",
    "target": "the-dyson",
    "relationship_type": "located-in",
    "public_description": "The Dead Sector is an abandoned industrial district within the Dyson.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 40
  },
  {
    "source": "memory-chamber",
    "target": "forgotten-network",
    "relationship_type": "located-in",
    "public_description": "The historical chamber moves through deeper sections of the forgotten network.",
    "reveal_episode": 15,
    "spoiler_level": 2,
    "sort_order": 50
  },
  {
    "source": "sleeping-network",
    "target": "the-dyson",
    "relationship_type": "located-in",
    "public_description": "The sleeping network runs beneath occupied and abandoned layers of the Dyson.",
    "reveal_episode": 17,
    "spoiler_level": 2,
    "sort_order": 60
  },
  {
    "source": "kai",
    "target": "hover-bikes",
    "relationship_type": "uses",
    "public_description": "Kai races and travels through the Bracken Ring on a hover bike.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 70
  },
  {
    "source": "ren",
    "target": "hover-bikes",
    "relationship_type": "uses",
    "public_description": "Ren races alongside Kai and uses his bike during the Dead Sector journeys.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 80
  },
  {
    "source": "mira",
    "target": "miras-repair-drone",
    "relationship_type": "uses",
    "public_description": "Mira uses the drone to inspect and connect with ancient machinery.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 90
  },
  {
    "source": "continuity-archive",
    "target": "memory-chamber",
    "relationship_type": "located-in",
    "public_description": "The archive is identified through systems associated with the moving memory chamber.",
    "reveal_episode": 13,
    "spoiler_level": 2,
    "sort_order": 100
  },
  {
    "source": "companion",
    "target": "sleeping-network",
    "relationship_type": "located-in",
    "public_description": "The sealed Companion is found at the centre of the deeper waking network.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 110
  },
  {
    "source": "blue-surface",
    "target": "continuity-archive",
    "relationship_type": "related-to",
    "public_description": "The archive repeatedly attempts to classify and reconstruct the blue surface.",
    "reveal_episode": 11,
    "spoiler_level": 2,
    "sort_order": 120
  },
  {
    "source": "logan",
    "target": "continuity-archive",
    "relationship_type": "related-to",
    "public_description": "Logan reconstructs the archive designation and analyses its learning process.",
    "reveal_episode": 13,
    "spoiler_level": 2,
    "sort_order": 130
  },
  {
    "source": "official-history",
    "target": "central-authority",
    "relationship_type": "related-to",
    "public_description": "Approved historical material is controlled through institutions associated with the Central Authority.",
    "reveal_episode": 7,
    "spoiler_level": 2,
    "sort_order": 140
  }
]
$json$::jsonb)
            as x(
                source text,
                target text,
                relationship_type text,
                public_description text,
                reveal_episode integer,
                spoiler_level integer,
                sort_order integer
            )
    )
    insert into public.wiki_entry_relationships
        (
            source_entry_id,
            target_entry_id,
            relationship_type,
            public_description,
            reveal_episode_id,
            spoiler_level,
            is_public,
            content_status,
            sort_order
        )
    select
        source_entry.id,
        target_entry.id,
        d.relationship_type,
        d.public_description,
        reveal_episode.id,
        d.spoiler_level,
        true,
        'published',
        d.sort_order
    from seed_data d
    join public.wiki_entries source_entry
      on source_entry.story_id = v_story_id
     and source_entry.slug = d.source
    join public.wiki_entries target_entry
      on target_entry.story_id = v_story_id
     and target_entry.slug = d.target
    left join public.episodes reveal_episode
      on reveal_episode.story_id = v_story_id
     and coalesce(reveal_episode.season_number, 1) = 1
     and reveal_episode.episode_number = d.reveal_episode
    on conflict (source_entry_id, target_entry_id, relationship_type) do update
    set public_description = excluded.public_description,
        reveal_episode_id = excluded.reveal_episode_id,
        spoiler_level = excluded.spoiler_level,
        is_public = excluded.is_public,
        content_status = excluded.content_status,
        sort_order = excluded.sort_order,
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- EPISODE TO WIKI LINKS
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "episode_number": 1,
    "entry_slug": "kai",
    "appearance_type": "appears",
    "public_notes": "Races above the Bracken Ring.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "episode_number": 1,
    "entry_slug": "ren",
    "appearance_type": "appears",
    "public_notes": "Races with Kai and asks whether their bikes could reach the Dead Sector.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 20
  },
  {
    "episode_number": 1,
    "entry_slug": "bracken-ring",
    "appearance_type": "setting",
    "public_notes": "Primary setting of the rooftop race.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 30
  },
  {
    "episode_number": 1,
    "entry_slug": "dead-sector",
    "appearance_type": "mentioned",
    "public_notes": "Visible from the familiar race route.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 40
  },
  {
    "episode_number": 1,
    "entry_slug": "hover-bikes",
    "appearance_type": "featured",
    "public_notes": "Used in the rooftop race.",
    "reveal_episode": null,
    "spoiler_level": 0,
    "sort_order": 50
  },
  {
    "episode_number": 2,
    "entry_slug": "dead-sector",
    "appearance_type": "setting",
    "public_notes": "Kai and Ren enter the forbidden district.",
    "reveal_episode": 2,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "episode_number": 3,
    "entry_slug": "luna-vale",
    "appearance_type": "introduced",
    "public_notes": "Luna recognises the old symbol.",
    "reveal_episode": 3,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "episode_number": 5,
    "entry_slug": "forgotten-network",
    "appearance_type": "discovered",
    "public_notes": "A hidden pattern reveals a larger forgotten system.",
    "reveal_episode": 5,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "episode_number": 5,
    "entry_slug": "hover-bikes",
    "appearance_type": "featured",
    "public_notes": "The bikes provide power to the old station.",
    "reveal_episode": 5,
    "spoiler_level": 1,
    "sort_order": 20
  },
  {
    "episode_number": 6,
    "entry_slug": "mira",
    "appearance_type": "introduced",
    "public_notes": "Mira joins the group with her repair drone.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 10
  },
  {
    "episode_number": 6,
    "entry_slug": "miras-repair-drone",
    "appearance_type": "introduced",
    "public_notes": "The drone opens access to a hidden shaft.",
    "reveal_episode": 6,
    "spoiler_level": 0,
    "sort_order": 20
  },
  {
    "episode_number": 7,
    "entry_slug": "official-history",
    "appearance_type": "featured",
    "public_notes": "The school archives contain removed records and missing pages.",
    "reveal_episode": 7,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "episode_number": 8,
    "entry_slug": "central-authority",
    "appearance_type": "mentioned",
    "public_notes": "The group's search draws attention from an unfamiliar authority.",
    "reveal_episode": 8,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "episode_number": 10,
    "entry_slug": "memory-chamber",
    "appearance_type": "introduced",
    "public_notes": "The hidden chamber activates.",
    "reveal_episode": 10,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "episode_number": 10,
    "entry_slug": "blue-surface",
    "appearance_type": "introduced",
    "public_notes": "A bright moving surface appears in the damaged memory.",
    "reveal_episode": 10,
    "spoiler_level": 2,
    "sort_order": 20
  },
  {
    "episode_number": 11,
    "entry_slug": "logan",
    "appearance_type": "introduced",
    "public_notes": "Logan begins reconstructing the damaged image.",
    "reveal_episode": 11,
    "spoiler_level": 1,
    "sort_order": 10
  },
  {
    "episode_number": 13,
    "entry_slug": "continuity-archive",
    "appearance_type": "introduced",
    "public_notes": "The ancient system designation is reconstructed.",
    "reveal_episode": 13,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "episode_number": 14,
    "entry_slug": "the-dyson",
    "appearance_type": "featured",
    "public_notes": "The historical structure appears incomplete and under construction.",
    "reveal_episode": 14,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "episode_number": 15,
    "entry_slug": "memory-chamber",
    "appearance_type": "featured",
    "public_notes": "The chamber shifts to a lower level.",
    "reveal_episode": 15,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "episode_number": 17,
    "entry_slug": "sleeping-network",
    "appearance_type": "introduced",
    "public_notes": "Cameras, service machines and routes begin recognising the group.",
    "reveal_episode": 17,
    "spoiler_level": 2,
    "sort_order": 10
  },
  {
    "episode_number": 18,
    "entry_slug": "companion",
    "appearance_type": "introduced",
    "public_notes": "The warning identifies the Companion and reports it already awake.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 10
  },
  {
    "episode_number": 18,
    "entry_slug": "blue-surface",
    "appearance_type": "featured",
    "public_notes": "A recovered object produces a sound connected to the image.",
    "reveal_episode": 18,
    "spoiler_level": 3,
    "sort_order": 20
  },
  {
    "episode_number": 19,
    "entry_slug": "companion",
    "appearance_type": "featured",
    "public_notes": "The counters suggest more than one million years of training.",
    "reveal_episode": 19,
    "spoiler_level": 3,
    "sort_order": 10
  },
  {
    "episode_number": 20,
    "entry_slug": "companion",
    "appearance_type": "featured",
    "public_notes": "The sealed core speaks and begins a new cycle.",
    "reveal_episode": 20,
    "spoiler_level": 3,
    "sort_order": 10
  },
  {
    "episode_number": 20,
    "entry_slug": "continuity-archive",
    "appearance_type": "featured",
    "public_notes": "Archive integrity and unresolved instruction are displayed.",
    "reveal_episode": 20,
    "spoiler_level": 3,
    "sort_order": 20
  }
]
$json$::jsonb)
            as x(
                episode_number integer,
                entry_slug text,
                appearance_type text,
                public_notes text,
                reveal_episode integer,
                spoiler_level integer,
                sort_order integer
            )
    )
    insert into public.episode_wiki_entries
        (
            episode_id,
            wiki_entry_id,
            appearance_type,
            public_notes,
            reveal_episode_id,
            spoiler_level,
            is_public,
            sort_order
        )
    select
        episode.id,
        entry.id,
        d.appearance_type,
        d.public_notes,
        reveal_episode.id,
        d.spoiler_level,
        true,
        d.sort_order
    from seed_data d
    join public.episodes episode
      on episode.story_id = v_story_id
     and coalesce(episode.season_number, 1) = 1
     and episode.episode_number = d.episode_number
    join public.wiki_entries entry
      on entry.story_id = v_story_id
     and entry.slug = d.entry_slug
    left join public.episodes reveal_episode
      on reveal_episode.story_id = v_story_id
     and coalesce(reveal_episode.season_number, 1) = 1
     and reveal_episode.episode_number = d.reveal_episode
    on conflict (episode_id, wiki_entry_id) do update
    set appearance_type = excluded.appearance_type,
        public_notes = excluded.public_notes,
        reveal_episode_id = excluded.reveal_episode_id,
        spoiler_level = excluded.spoiler_level,
        is_public = excluded.is_public,
        sort_order = excluded.sort_order;

    -- -------------------------------------------------------------------------
    -- STORY CANON RULES
    -- Deterministic UUIDs make this section safe to rerun.
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "rule_key": "setting",
    "rule_category": "setting",
    "rule_text": "Human civilisation lives in artificial habitats, industrial cities and orbital structures surrounding a white dwarf.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": true
  },
  {
    "rule_key": "layered-dyson",
    "rule_category": "setting",
    "rule_text": "The Dyson is a layered civilisation assembled and rebuilt over immense periods; it is not a single uniform solid shell.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": 14,
    "spoiler_level": 2,
    "is_public": true
  },
  {
    "rule_key": "lost-planets",
    "rule_category": "culture",
    "rule_text": "Most modern residents do not understand planets, oceans, open horizons or natural weather as lived realities.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 1,
    "is_public": true
  },
  {
    "rule_key": "artificial-day",
    "rule_category": "technology",
    "rule_text": "Day, evening and night inside inhabited districts are generated by artificial sky and habitat control systems.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": true
  },
  {
    "rule_key": "official-history",
    "rule_category": "history",
    "rule_text": "Official history is incomplete and controlled through omission, restricted access, removed records and simplified diagrams.",
    "importance": "critical",
    "from_episode": 7,
    "reveal_episode": 7,
    "spoiler_level": 1,
    "is_public": true
  },
  {
    "rule_key": "light-speed",
    "rule_category": "science",
    "rule_text": "Light speed remains the physical limit. Long-distance civilisation and historical change must respect that constraint.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "technical-roles",
    "rule_category": "character",
    "rule_text": "Logan handles programming and learning systems; Mira handles hardware, repairs, sensors and drones. Kai and Ren should not replace these specialist roles.",
    "importance": "high",
    "from_episode": 11,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "kai-behaviour",
    "rule_category": "character",
    "rule_text": "Kai acts before full certainty, masks fear with humour and remains loyal; he should not become a calm technical strategist without visible growth.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "ren-behaviour",
    "rule_category": "character",
    "rule_text": "Ren identifies risk and challenges dangerous plans before joining them; caution is part of his loyalty, not cowardice.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "gradual-ai",
    "rule_category": "storytelling",
    "rule_text": "The ancient intelligence must reveal itself through fragments, environmental reactions and incomplete statements rather than a complete explanation.",
    "importance": "critical",
    "from_episode": 10,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "archive-unreliable",
    "rule_category": "continuity",
    "rule_text": "Continuity Archive reconstructions may combine preserved data, inferred data and contamination from present observers; they are evidence, not unquestionable truth.",
    "importance": "critical",
    "from_episode": 11,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "identity-unresolved",
    "rule_category": "continuity",
    "rule_text": "Do not state definitively whether the Continuity Archive and the Companion are the same intelligence, separate processes or nested systems until canon resolves it.",
    "importance": "critical",
    "from_episode": 13,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "knowledge-by-episode",
    "rule_category": "continuity",
    "rule_text": "Characters may only use facts, terminology and interpretations learned by the current episode unless a flashback or explicit source establishes otherwise.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "million-year-scale",
    "rule_category": "history",
    "rule_text": "By Episode 19 the evidence supports a training duration near one million years, but the exact counter and translation remain uncertain.",
    "importance": "critical",
    "from_episode": 19,
    "reveal_episode": 19,
    "spoiler_level": 3,
    "is_public": false
  }
]
$json$::jsonb)
            as x(
                rule_key text,
                rule_category text,
                rule_text text,
                importance text,
                from_episode integer,
                reveal_episode integer,
                spoiler_level integer,
                is_public boolean
            )
    )
    insert into public.story_canon_rules
        (
            id,
            story_id,
            rule_category,
            rule_text,
            importance,
            active_from_episode_id,
            active_to_episode_id,
            reveal_episode_id,
            spoiler_level,
            is_public,
            content_status
        )
    select
        md5(v_story_id::text || ':canon:' || d.rule_key)::uuid,
        v_story_id,
        d.rule_category,
        d.rule_text,
        d.importance,
        active_from.id,
        null,
        reveal_episode.id,
        d.spoiler_level,
        d.is_public,
        'published'
    from seed_data d
    left join public.episodes active_from
      on active_from.story_id = v_story_id
     and coalesce(active_from.season_number, 1) = 1
     and active_from.episode_number = d.from_episode
    left join public.episodes reveal_episode
      on reveal_episode.story_id = v_story_id
     and coalesce(reveal_episode.season_number, 1) = 1
     and reveal_episode.episode_number = d.reveal_episode
    on conflict (id) do update
    set rule_category = excluded.rule_category,
        rule_text = excluded.rule_text,
        importance = excluded.importance,
        active_from_episode_id = excluded.active_from_episode_id,
        active_to_episode_id = excluded.active_to_episode_id,
        reveal_episode_id = excluded.reveal_episode_id,
        spoiler_level = excluded.spoiler_level,
        is_public = excluded.is_public,
        content_status = excluded.content_status,
        updated_at = now();

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "rule_key": "setting",
    "rule_category": "setting",
    "rule_text": "Human civilisation lives in artificial habitats, industrial cities and orbital structures surrounding a white dwarf.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": true
  },
  {
    "rule_key": "layered-dyson",
    "rule_category": "setting",
    "rule_text": "The Dyson is a layered civilisation assembled and rebuilt over immense periods; it is not a single uniform solid shell.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": 14,
    "spoiler_level": 2,
    "is_public": true
  },
  {
    "rule_key": "lost-planets",
    "rule_category": "culture",
    "rule_text": "Most modern residents do not understand planets, oceans, open horizons or natural weather as lived realities.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 1,
    "is_public": true
  },
  {
    "rule_key": "artificial-day",
    "rule_category": "technology",
    "rule_text": "Day, evening and night inside inhabited districts are generated by artificial sky and habitat control systems.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": true
  },
  {
    "rule_key": "official-history",
    "rule_category": "history",
    "rule_text": "Official history is incomplete and controlled through omission, restricted access, removed records and simplified diagrams.",
    "importance": "critical",
    "from_episode": 7,
    "reveal_episode": 7,
    "spoiler_level": 1,
    "is_public": true
  },
  {
    "rule_key": "light-speed",
    "rule_category": "science",
    "rule_text": "Light speed remains the physical limit. Long-distance civilisation and historical change must respect that constraint.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "technical-roles",
    "rule_category": "character",
    "rule_text": "Logan handles programming and learning systems; Mira handles hardware, repairs, sensors and drones. Kai and Ren should not replace these specialist roles.",
    "importance": "high",
    "from_episode": 11,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "kai-behaviour",
    "rule_category": "character",
    "rule_text": "Kai acts before full certainty, masks fear with humour and remains loyal; he should not become a calm technical strategist without visible growth.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "ren-behaviour",
    "rule_category": "character",
    "rule_text": "Ren identifies risk and challenges dangerous plans before joining them; caution is part of his loyalty, not cowardice.",
    "importance": "high",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "gradual-ai",
    "rule_category": "storytelling",
    "rule_text": "The ancient intelligence must reveal itself through fragments, environmental reactions and incomplete statements rather than a complete explanation.",
    "importance": "critical",
    "from_episode": 10,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "archive-unreliable",
    "rule_category": "continuity",
    "rule_text": "Continuity Archive reconstructions may combine preserved data, inferred data and contamination from present observers; they are evidence, not unquestionable truth.",
    "importance": "critical",
    "from_episode": 11,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "identity-unresolved",
    "rule_category": "continuity",
    "rule_text": "Do not state definitively whether the Continuity Archive and the Companion are the same intelligence, separate processes or nested systems until canon resolves it.",
    "importance": "critical",
    "from_episode": 13,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "knowledge-by-episode",
    "rule_category": "continuity",
    "rule_text": "Characters may only use facts, terminology and interpretations learned by the current episode unless a flashback or explicit source establishes otherwise.",
    "importance": "critical",
    "from_episode": 1,
    "reveal_episode": null,
    "spoiler_level": 0,
    "is_public": false
  },
  {
    "rule_key": "million-year-scale",
    "rule_category": "history",
    "rule_text": "By Episode 19 the evidence supports a training duration near one million years, but the exact counter and translation remain uncertain.",
    "importance": "critical",
    "from_episode": 19,
    "reveal_episode": 19,
    "spoiler_level": 3,
    "is_public": false
  }
]
$json$::jsonb)
            as x(
                rule_key text,
                rule_category text,
                rule_text text,
                importance text,
                from_episode integer,
                reveal_episode integer,
                spoiler_level integer,
                is_public boolean
            )
    )
    insert into public.story_canon_rule_internal
        (canon_rule_id, source_notes, ai_context)
    select
        md5(v_story_id::text || ':canon:' || d.rule_key)::uuid,
        'Life Inside the Dyson Season 1 test wiki seed.',
        'Treat this as an active continuity constraint when drafting or reviewing episodes.'
    from seed_data d
    on conflict (canon_rule_id) do update
    set source_notes = excluded.source_notes,
        ai_context = excluded.ai_context,
        updated_at = now();

    -- -------------------------------------------------------------------------
    -- CHARACTER KNOWLEDGE BY EPISODE
    -- -------------------------------------------------------------------------

    with seed_data as (
        select *
          from jsonb_to_recordset($json$
[
  {
    "knowledge_key": "kai-signal",
    "character_slug": "kai",
    "fact_slug": "forgotten-network",
    "knowledge_text": "Kai knows an active signal and system marker survive beneath the old station.",
    "certainty_level": "knows",
    "learned_episode": 2,
    "reveal_episode": 2,
    "is_secret": false,
    "spoiler_level": 1
  },
  {
    "knowledge_key": "kai-history",
    "character_slug": "kai",
    "fact_slug": "official-history",
    "knowledge_text": "Kai knows the first memory proves official history is incomplete.",
    "certainty_level": "knows",
    "learned_episode": 10,
    "reveal_episode": 10,
    "is_secret": true,
    "spoiler_level": 2
  },
  {
    "knowledge_key": "kai-blue",
    "character_slug": "kai",
    "fact_slug": "blue-surface",
    "knowledge_text": "Kai knows the blue surface moves across an open distance but cannot identify it.",
    "certainty_level": "knows",
    "learned_episode": 10,
    "reveal_episode": 10,
    "is_secret": true,
    "spoiler_level": 2
  },
  {
    "knowledge_key": "ren-network",
    "character_slug": "ren",
    "fact_slug": "forgotten-network",
    "knowledge_text": "Ren knows the signal changes in response to the group and is not a simple recording.",
    "certainty_level": "knows",
    "learned_episode": 5,
    "reveal_episode": 5,
    "is_secret": true,
    "spoiler_level": 1
  },
  {
    "knowledge_key": "ren-companion",
    "character_slug": "ren",
    "fact_slug": "companion",
    "knowledge_text": "Ren knows the sealed process can respond to questions but does not trust its intent.",
    "certainty_level": "knows",
    "learned_episode": 20,
    "reveal_episode": 20,
    "is_secret": true,
    "spoiler_level": 3
  },
  {
    "knowledge_key": "luna-symbol",
    "character_slug": "luna-vale",
    "fact_slug": "continuity-archive",
    "knowledge_text": "Luna believes she saw the old symbol inside a restricted historical display.",
    "certainty_level": "believes",
    "learned_episode": 3,
    "reveal_episode": 3,
    "is_secret": true,
    "spoiler_level": 1
  },
  {
    "knowledge_key": "luna-system",
    "character_slug": "luna-vale",
    "fact_slug": "forgotten-network",
    "knowledge_text": "Luna knows the signal belongs to a system removed from modern infrastructure records.",
    "certainty_level": "knows",
    "learned_episode": 4,
    "reveal_episode": 4,
    "is_secret": true,
    "spoiler_level": 1
  },
  {
    "knowledge_key": "mira-response",
    "character_slug": "mira",
    "fact_slug": "forgotten-network",
    "knowledge_text": "Mira knows the old system responds to her repair equipment and can use modern devices as inputs.",
    "certainty_level": "knows",
    "learned_episode": 6,
    "reveal_episode": 6,
    "is_secret": true,
    "spoiler_level": 1
  },
  {
    "knowledge_key": "logan-rewrite",
    "character_slug": "logan",
    "fact_slug": "continuity-archive",
    "knowledge_text": "Logan knows the archive rewrites missing historical data using the current environment as a reference.",
    "certainty_level": "knows",
    "learned_episode": 11,
    "reveal_episode": 11,
    "is_secret": true,
    "spoiler_level": 2
  },
  {
    "knowledge_key": "logan-designation",
    "character_slug": "logan",
    "fact_slug": "continuity-archive",
    "knowledge_text": "Logan knows the ancient system designation is Continuity Archive.",
    "certainty_level": "knows",
    "learned_episode": 13,
    "reveal_episode": 13,
    "is_secret": true,
    "spoiler_level": 2
  },
  {
    "knowledge_key": "logan-million",
    "character_slug": "logan",
    "fact_slug": "companion",
    "knowledge_text": "Logan knows the counters indicate a training duration near one million years, while the exact figure remains unreliable.",
    "certainty_level": "knows",
    "learned_episode": 19,
    "reveal_episode": 19,
    "is_secret": true,
    "spoiler_level": 3
  },
  {
    "knowledge_key": "companion-samples",
    "character_slug": "companion",
    "fact_slug": "continuity-archive",
    "knowledge_text": "The Companion treats Kai, Ren, Luna and Mira as training samples and initially does not count Logan.",
    "certainty_level": "knows",
    "learned_episode": 15,
    "reveal_episode": 15,
    "is_secret": true,
    "spoiler_level": 3
  }
]
$json$::jsonb)
            as x(
                knowledge_key text,
                character_slug text,
                fact_slug text,
                knowledge_text text,
                certainty_level text,
                learned_episode integer,
                reveal_episode integer,
                is_secret boolean,
                spoiler_level integer
            )
    )
    insert into public.character_knowledge
        (
            id,
            character_entry_id,
            fact_entry_id,
            knowledge_text,
            certainty_level,
            learned_in_episode_id,
            superseded_in_episode_id,
            reveal_episode_id,
            is_secret,
            spoiler_level,
            is_public,
            content_status
        )
    select
        md5(v_story_id::text || ':knowledge:' || d.knowledge_key)::uuid,
        character_entry.id,
        fact_entry.id,
        d.knowledge_text,
        d.certainty_level,
        learned_episode.id,
        null,
        reveal_episode.id,
        d.is_secret,
        d.spoiler_level,
        false,
        'published'
    from seed_data d
    join public.wiki_entries character_entry
      on character_entry.story_id = v_story_id
     and character_entry.slug = d.character_slug
    left join public.wiki_entries fact_entry
      on fact_entry.story_id = v_story_id
     and fact_entry.slug = d.fact_slug
    left join public.episodes learned_episode
      on learned_episode.story_id = v_story_id
     and coalesce(learned_episode.season_number, 1) = 1
     and learned_episode.episode_number = d.learned_episode
    left join public.episodes reveal_episode
      on reveal_episode.story_id = v_story_id
     and coalesce(reveal_episode.season_number, 1) = 1
     and reveal_episode.episode_number = d.reveal_episode
    on conflict (id) do update
    set character_entry_id = excluded.character_entry_id,
        fact_entry_id = excluded.fact_entry_id,
        knowledge_text = excluded.knowledge_text,
        certainty_level = excluded.certainty_level,
        learned_in_episode_id = excluded.learned_in_episode_id,
        superseded_in_episode_id = excluded.superseded_in_episode_id,
        reveal_episode_id = excluded.reveal_episode_id,
        is_secret = excluded.is_secret,
        spoiler_level = excluded.spoiler_level,
        is_public = excluded.is_public,
        content_status = excluded.content_status,
        updated_at = now();

end;
$seed$;

commit;

-- -----------------------------------------------------------------------------
-- VERIFICATION
-- -----------------------------------------------------------------------------

select
    wet.name as entry_type,
    count(*) as wiki_entries
from public.wiki_entries we
join public.wiki_entry_types wet
  on wet.slug = we.entry_type
join public.stories s
  on s.id = we.story_id
where s.slug = 'life-inside-the-dyson'
group by wet.name, wet.sort_order
order by wet.sort_order;

select
    we.entry_type,
    we.title,
    reveal_episode.episode_number as unlocks_after_episode,
    we.spoiler_level,
    count(wes.id) as section_count
from public.wiki_entries we
join public.stories s
  on s.id = we.story_id
left join public.episodes reveal_episode
  on reveal_episode.id = we.reveal_episode_id
left join public.wiki_entry_sections wes
  on wes.wiki_entry_id = we.id
where s.slug = 'life-inside-the-dyson'
group by
    we.entry_type,
    we.title,
    we.sort_order,
    reveal_episode.episode_number,
    we.spoiler_level
order by we.entry_type, we.sort_order, we.title;

select
    (select count(*)
       from public.wiki_entry_relationships r
       join public.wiki_entries we on we.id = r.source_entry_id
      where we.story_id = s.id) as relationships,
    (select count(*)
       from public.episode_wiki_entries ewe
       join public.episodes e on e.id = ewe.episode_id
      where e.story_id = s.id) as episode_links,
    (select count(*)
       from public.story_canon_rules cr
      where cr.story_id = s.id) as canon_rules,
    (select count(*)
       from public.character_knowledge ck
       join public.wiki_entries we on we.id = ck.character_entry_id
      where we.story_id = s.id) as character_knowledge_rows
from public.stories s
where s.slug = 'life-inside-the-dyson';
