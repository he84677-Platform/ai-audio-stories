import Link from "next/link";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { getStorageImageUrl } from "@/lib/supabase-storage";

type SearchParams = {
  spoilers?: string | string[];
  season?: string | string[];
  episode?: string | string[];
};

type WikiSection = {
  id: string;
  heading: string | null;
  content: string | null;
};

type WikiRelationship = {
  relationship_type: string;
  public_description: string | null;
};

type WikiEntryDetail = {
  id: string;
  title: string | null;
  entry_type: string | null;
  short_description: string | null;
  introduction: string | null;
  is_unlocked: boolean;
};

type WikiEpisode = {
  id: string;
  season_number: number;
  episode_number: number;
  title: string;
};

type WikiResponse = {
  story: {
    slug: string;
    title: string;
    short_description: string | null;
    banner_image_path: string | null;
  };
  settings: {
    wiki_title: string | null;
    wiki_introduction: string | null;
    allow_spoiler_toggle: boolean;
    show_locked_placeholders: boolean;
  };
  episodes: WikiEpisode[];
  requested_entry: WikiEntryDetail | null;
  sections: WikiSection[];
  relationships: WikiRelationship[];
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

function humanizeType(entryType: string | null) {
  return entryType
    ? entryType.replace(/_/g, " ").replace(/\b\w/g, (value) => value.toUpperCase())
    : "Wiki entry";
}

export default async function WikiEntryPage({
  params,
  searchParams,
}: {
  params: { slug: string; entrySlug: string };
  searchParams: SearchParams;
}) {
  const { slug, entrySlug } = params;
  const spoilersParam = getParam(searchParams.spoilers);
  const spoilersOn = spoilersParam === "on";
  const seasonParam = getParam(searchParams.season);
  const episodeParam = getParam(searchParams.episode);
  const completedSeason = spoilersOn ? null : parseNumber(seasonParam);
  const completedEpisode = spoilersOn ? null : parseNumber(episodeParam);

  const { data, error } = await supabase.rpc("get_public_story_wiki", {
    p_story_slug: slug,
    p_entry_slug: entrySlug,
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

  if (!wiki.requested_entry) {
    notFound();
  }

  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-white">
      <div className="mx-auto max-w-5xl space-y-10">
        <div className="rounded-[2rem] border border-zinc-800 bg-zinc-900 p-8 sm:p-12">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
                {wiki.settings.wiki_title ?? "Story Wiki"}
              </p>
              <h1 className="mt-3 text-4xl font-bold text-white sm:text-5xl">
                {wiki.requested_entry.title ?? "Wiki Entry"}
              </h1>
            </div>
            <Link
              href={`/stories/${wiki.story.slug}/wiki${queryString}`}
              className="inline-flex items-center justify-center rounded-full border border-zinc-700 bg-zinc-950/80 px-6 py-3 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
            >
              Back to wiki
            </Link>
          </div>

          <div className="mt-6 grid gap-6 lg:grid-cols-[1.4fr_0.8fr]">
            <div className="space-y-4">
              <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
                {humanizeType(wiki.requested_entry.entry_type)}
              </p>
              <p className="text-lg leading-8 text-zinc-300">
                {wiki.requested_entry.short_description ?? wiki.requested_entry.introduction ?? "No public description available."}
              </p>
              <div className="grid gap-4">
                {wiki.sections.map((section) => (
                  <div key={section.id} className="rounded-3xl border border-zinc-800 bg-zinc-950 p-6">
                    <h2 className="text-xl font-semibold text-white">{section.heading ?? "Details"}</h2>
                    <p className="mt-3 text-sm leading-7 text-zinc-300 whitespace-pre-line">
                      {section.content ?? "No section content available."}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            <aside className="space-y-4">
              <div className="rounded-3xl border border-zinc-800 bg-zinc-950 p-6">
                <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">Story</p>
                <h2 className="mt-3 text-xl font-semibold text-white">{wiki.story.title}</h2>
              </div>

              {wiki.episodes.length > 0 ? (
                <div className="rounded-3xl border border-zinc-800 bg-zinc-950 p-6">
                  <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">Related episodes</p>
                  <ul className="mt-4 space-y-3 text-sm text-zinc-300">
                    {wiki.episodes.map((episode) => (
                      <li key={episode.id}>
                        S{episode.season_number} · E{episode.episode_number} — {episode.title}
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}

              {wiki.relationships.length > 0 ? (
                <div className="rounded-3xl border border-zinc-800 bg-zinc-950 p-6">
                  <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">Related entries</p>
                  <ul className="mt-4 space-y-3 text-sm text-zinc-300">
                    {wiki.relationships.map((relationship, index) => (
                      <li key={index}>
                        <span className="font-semibold text-white">{relationship.relationship_type}:</span> {relationship.public_description}
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}

              <div className="rounded-3xl border border-zinc-800 bg-zinc-950 p-6">
                <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">Spoiler state</p>
                <p className="mt-3 text-sm text-zinc-300">
                  {wiki.requested_entry.is_unlocked ? "This entry is unlocked for your current progress." : "This entry is locked by your current progress."}
                </p>
              </div>
            </aside>
          </div>
        </div>
      </div>
    </main>
  );
}
