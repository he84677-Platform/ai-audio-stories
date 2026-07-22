import Link from "next/link";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { getStorageImageUrl } from "@/lib/supabase-storage";

type SearchParams = {
  spoilers?: string | string[];
  season?: string | string[];
  episode?: string | string[];
};

type WikiEntry = {
  id: string;
  slug: string;
  title: string;
  short_description: string | null;
  introduction: string | null;
  entry_type: string;
};

type WikiEpisode = {
  id: string;
  season_number: number;
  episode_number: number;
  title: string;
};

type WikiSettings = {
  wiki_title: string | null;
  wiki_introduction: string | null;
  allow_spoiler_toggle: boolean;
  show_locked_placeholders: boolean;
};

type WikiResponse = {
  story: {
    slug: string;
    title: string;
    short_description: string | null;
    banner_image_path: string | null;
  };
  settings: WikiSettings;
  episodes: WikiEpisode[];
  entries: WikiEntry[];
  locked_entries: Array<{ unlock_season: number | null; unlock_episode: number | null }>;
};

function getParam(value: string | string[] | undefined): string | undefined {
  if (Array.isArray(value)) {
    return value[0];
  }
  return value;
}

function parseNumber(value: string | undefined): number | null {
  if (!value) return null;
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function buildQuery(spoilersOn: boolean, season: string | null, episode: string | null) {
  const params = new URLSearchParams();

  if (spoilersOn) {
    params.set("spoilers", "on");
  } else {
    params.set("spoilers", "off");
    if (season) params.set("season", season);
    if (episode) params.set("episode", episode);
  }

  const query = params.toString();
  return query ? `?${query}` : "";
}

function humanizeType(entryType: string) {
  return entryType.replace(/_/g, " ").replace(/\b\w/g, (value) => value.toUpperCase());
}

export default async function StoryWikiIndex({
  params,
  searchParams,
}: {
  params: { slug: string };
  searchParams: SearchParams;
}) {
  const { slug } = params;
  const spoilersParam = getParam(searchParams.spoilers);
  const spoilersOn = spoilersParam === "on";
  const seasonParam = getParam(searchParams.season);
  const episodeParam = getParam(searchParams.episode);
  const completedSeason = spoilersOn ? null : parseNumber(seasonParam);
  const completedEpisode = spoilersOn ? null : parseNumber(episodeParam);

  const { data, error } = await supabase.rpc("get_public_story_wiki", {
    p_story_slug: slug,
    p_entry_slug: null,
    p_completed_season: completedSeason,
    p_completed_episode: completedEpisode,
    p_include_spoilers: spoilersOn,
  });

  if (error) {
    throw new Error(error.message);
  }

  const wiki = data as WikiResponse | null;
  if (!wiki?.story) {
    notFound();
  }

  const queryString = buildQuery(spoilersOn, seasonParam ?? null, episodeParam ?? null);

  const episodesBySeason = wiki.episodes.reduce((acc, episode) => {
    acc[episode.season_number] ||= [];
    acc[episode.season_number].push(episode);
    return acc;
  }, {} as Record<number, WikiEpisode[]>);

  const entryGroups = wiki.entries.reduce((acc, entry) => {
    acc[entry.entry_type] ||= [];
    acc[entry.entry_type].push(entry);
    return acc;
  }, {} as Record<string, WikiEntry[]>);

  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-white">
      <div className="mx-auto max-w-6xl space-y-10">
        <div className="space-y-6 rounded-[2rem] border border-zinc-800 bg-zinc-900 p-8 sm:p-12">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
                {wiki.settings.wiki_title ?? "Story Wiki"}
              </p>
              <h1 className="mt-3 text-4xl font-bold text-white sm:text-5xl">
                {wiki.story.title}
              </h1>
            </div>
            <Link
              href={`/stories/${wiki.story.slug}`}
              className="inline-flex items-center justify-center rounded-full border border-zinc-700 bg-zinc-950/80 px-6 py-3 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
            >
              Back to story
            </Link>
          </div>

          <div className="grid gap-6 lg:grid-cols-[1.6fr_0.9fr]">
            <div className="space-y-4">
              <p className="text-lg leading-8 text-zinc-300">
                {wiki.settings.wiki_introduction ?? wiki.story.short_description}
              </p>
              <div className="rounded-3xl bg-zinc-950/70 p-5 text-sm text-zinc-400">
                <p>
                  {wiki.entries.length} available wiki entries · {wiki.locked_entries.length} locked entries
                </p>
              </div>
            </div>

            <form className="space-y-4 rounded-3xl border border-zinc-800 bg-zinc-900 p-6" method="get">
              <div className="space-y-2">
                <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
                  Spoiler controls
                </p>
                <p className="text-sm text-zinc-400">
                  Choose whether the wiki should reveal information based on your completed episode.
                </p>
              </div>

              <div className="space-y-3">
                <label className="flex items-center gap-3 rounded-3xl border border-zinc-800 bg-zinc-950 p-4">
                  <input
                    type="radio"
                    name="spoilers"
                    value="off"
                    defaultChecked={!spoilersOn}
                    className="h-4 w-4 rounded-full border-zinc-700 bg-zinc-800 text-emerald-400"
                  />
                  <span className="text-sm text-zinc-200">Spoilers off</span>
                </label>

                <label className="flex items-center gap-3 rounded-3xl border border-zinc-800 bg-zinc-950 p-4">
                  <input
                    type="radio"
                    name="spoilers"
                    value="on"
                    defaultChecked={spoilersOn}
                    disabled={!wiki.settings.allow_spoiler_toggle}
                    className="h-4 w-4 rounded-full border-zinc-700 bg-zinc-800 text-emerald-400"
                  />
                  <span className="text-sm text-zinc-200">
                    Spoilers on
                    {!wiki.settings.allow_spoiler_toggle ? " (disabled by story)" : ""}
                  </span>
                </label>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="space-y-2 text-sm text-zinc-300">
                  <span>Completed season</span>
                  <select
                    name="season"
                    defaultValue={seasonParam ?? ""}
                    className="w-full rounded-3xl border border-zinc-800 bg-zinc-950 px-4 py-3 text-white outline-none transition focus:border-emerald-400"
                  >
                    <option value="">Not completed</option>
                    {Object.keys(episodesBySeason)
                      .sort((a, b) => Number(a) - Number(b))
                      .map((seasonNumber) => (
                        <option key={seasonNumber} value={seasonNumber}>
                          Season {seasonNumber}
                        </option>
                      ))}
                  </select>
                </label>

                <label className="space-y-2 text-sm text-zinc-300">
                  <span>Completed episode</span>
                  <select
                    name="episode"
                    defaultValue={episodeParam ?? ""}
                    className="w-full rounded-3xl border border-zinc-800 bg-zinc-950 px-4 py-3 text-white outline-none transition focus:border-emerald-400"
                  >
                    <option value="">Not completed</option>
                    {wiki.episodes.map((episode) => (
                      <option key={episode.id} value={episode.episode_number}>
                        S{episode.season_number} · E{episode.episode_number} — {episode.title}
                      </option>
                    ))}
                  </select>
                </label>
              </div>

              <button
                type="submit"
                className="inline-flex items-center justify-center rounded-full bg-emerald-400 px-6 py-3 text-sm font-semibold text-zinc-950 transition hover:bg-emerald-300"
              >
                Update view
              </button>
            </form>
          </div>
        </div>

        <div className="space-y-8">
          {Object.entries(entryGroups).map(([entryType, entries]) => (
            <section key={entryType} className="space-y-4">
              <div className="flex items-center justify-between gap-4">
                <h2 className="text-2xl font-semibold text-white">
                  {humanizeType(entryType)}
                </h2>
                <span className="rounded-full border border-zinc-800 bg-zinc-950 px-3 py-1 text-xs uppercase tracking-[0.24em] text-emerald-400">
                  {entries.length}
                </span>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                {entries.map((entry) => (
                  <Link
                    key={entry.id}
                    href={`/stories/${wiki.story.slug}/wiki/${entry.slug}${queryString}`}
                    className="group overflow-hidden rounded-3xl border border-zinc-800 bg-zinc-900 p-6 transition hover:border-emerald-400"
                  >
                    <h3 className="text-xl font-semibold text-white transition group-hover:text-emerald-300">
                      {entry.title}
                    </h3>
                    <p className="mt-3 text-sm leading-6 text-zinc-400">
                      {entry.short_description ?? entry.introduction ?? "No summary available."}
                    </p>
                    <div className="mt-6 flex items-center justify-between text-sm text-emerald-300">
                      <span>View entry</span>
                      <span>→</span>
                    </div>
                  </Link>
                ))}
              </div>
            </section>
          ))}

          {wiki.locked_entries.length > 0 && wiki.settings.show_locked_placeholders ? (
            <section className="rounded-3xl border border-zinc-800 bg-zinc-900 p-6">
              <h2 className="text-2xl font-semibold text-white">Locked entries</h2>
              <p className="mt-2 text-sm leading-6 text-zinc-400">
                Some entries are locked until you complete the matching episode.
              </p>
              <div className="mt-5 space-y-3">
                {wiki.locked_entries.map((locked, index) => (
                  <div
                    key={`${locked.unlock_season}-${locked.unlock_episode}-${index}`}
                    className="rounded-3xl border border-zinc-800 bg-zinc-950 p-4"
                  >
                    <p className="text-sm text-zinc-300">
                      Unlocks at Season {locked.unlock_season ?? "?"}, Episode {locked.unlock_episode ?? "?"}
                    </p>
                  </div>
                ))}
              </div>
            </section>
          ) : null}
        </div>
      </div>
    </main>
  );
}
