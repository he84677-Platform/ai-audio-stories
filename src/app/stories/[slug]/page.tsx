import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { getStorageImageUrl } from "@/lib/supabase-storage";

type Props = {
  params: Promise<{ slug: string }>;
  searchParams: { page?: string };
};

export default async function StoryPage({ params, searchParams }: Props) {
  const { slug } = await params;
  const page = Math.max(1, Number(searchParams.page ?? 1));
  const pageSize = 10;
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  const { data: story } = await supabase
    .from("stories")
    .select("id, slug, title, description, short_description, banner_image_path")
    .eq("slug", slug)
    .eq("content_status", "published")
    .single();

  if (!story) notFound();

  const { data: episodes, error, count } = await supabase
    .from("episodes")
    .select(
      "id, season_number, episode_number, title, summary, word_count, duration_seconds, episode_status, audio_url, artwork_path",
      { count: "exact" }
    )
    .eq("story_id", story.id)
    .eq("episode_status", "published")
    .order("season_number")
    .order("episode_number")
    .range(from, to);

  if (error) {
    throw new Error(error.message);
  }

  const { data: hasWiki, error: wikiError } = await supabase.rpc("has_public_story_wiki", {
    p_story_id: story.id,
  });

  if (wikiError) {
    throw new Error(wikiError.message);
  }

  const wikiEnabled = Boolean(hasWiki);
  const totalPages = Math.max(1, Math.ceil((count ?? episodes.length) / pageSize));

  const seasons = episodes.reduce(
    (groups, episode) => {
      const season = episode.season_number ?? 1;
      groups[season] ??= [];
      groups[season].push(episode);
      return groups;
    },
    {} as Record<number, typeof episodes>
  );

  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-white">
      <div className="mx-auto max-w-4xl">
        <Link
          href="/"
          className="text-sm text-emerald-400 hover:text-emerald-300"
        >
          ← Back to library
        </Link>

        <div className="mt-10 overflow-hidden rounded-[2rem] border border-zinc-800 bg-zinc-900">
          <div className="relative h-72 sm:h-96">
            <Image
              src={getStorageImageUrl(story.banner_image_path ?? null)}
              alt={story.title}
              fill
              sizes="100vw"
              className="object-cover"
            />
          </div>

          <div className="space-y-6 p-6 sm:p-10">
            <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
              AI Audio Stories
            </p>

            <h1 className="text-4xl font-bold text-white">{story.title}</h1>

            <p className="max-w-3xl text-lg leading-8 text-zinc-300">
              {story.description ?? story.short_description}
            </p>
          </div>
        </div>

        <div className="mt-12 space-y-10">
          {wikiEnabled ? (
            <div className="rounded-3xl border border-emerald-500/20 bg-emerald-500/5 p-6 text-sm text-emerald-200">
              <p className="font-semibold">Story wiki available</p>
              <p className="mt-2 text-zinc-300">
                Explore the public story wiki, spoiler-aware and tied to your completed episode progress.
              </p>
              <Link
                href={`/stories/${story.slug}/wiki`}
                className="mt-4 inline-flex items-center justify-center rounded-full bg-emerald-400 px-5 py-3 text-sm font-semibold text-zinc-950 transition hover:bg-emerald-300"
              >
                View story wiki
              </Link>
            </div>
          ) : null}

          {Object.entries(seasons).map(([seasonNumber, seasonEpisodes]) => (
            <section key={seasonNumber}>
              <h2 className="mb-4 text-2xl font-semibold text-white">
                Season {seasonNumber}
              </h2>

              <div className="space-y-4">
                {seasonEpisodes.map((episode) => (
                  <article
                    key={episode.id}
                    className="rounded-3xl border border-zinc-800 bg-zinc-900 p-5 sm:p-6"
                  >
                    <div className="grid gap-4 sm:grid-cols-[320px_minmax(0,1fr)]">
                      <div className="relative overflow-hidden rounded-3xl bg-zinc-950">
                        <div className="aspect-[4/3] sm:aspect-[5/4]">
                          <Image
                            src={getStorageImageUrl(episode.artwork_path ?? null)}
                            alt={episode.title}
                            fill
                            sizes="(max-width: 640px) 100vw, 320px"
                            className="object-cover"
                          />
                        </div>
                      </div>

                      <div className="flex flex-col justify-between">
                        <div>
                          <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
                            Episode {episode.episode_number}
                          </p>
                          <h3 className="mt-2 text-xl font-semibold text-white">
                            {episode.title}
                          </h3>
                          {episode.summary && (
                            <p className="mt-3 text-zinc-400">{episode.summary}</p>
                          )}
                        </div>

                        <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                          <p className="text-sm text-zinc-500">
                            {episode.word_count ?? 0} words · {Math.round((episode.duration_seconds ?? 0) / 60)} minutes
                          </p>
                          {episode.audio_url ? (
                            <a
                              href={episode.audio_url}
                              className="inline-flex items-center justify-center rounded-full bg-emerald-400 px-4 py-2 text-sm font-semibold text-zinc-950 transition hover:bg-emerald-300"
                            >
                              Play
                            </a>
                          ) : (
                            <span className="inline-flex items-center justify-center rounded-full bg-zinc-800 px-4 py-2 text-sm font-semibold text-zinc-500">
                              No audio
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </article>
                ))}
              </div>
            </section>
          ))}
        </div>
      </div>
    </main>
  );
}
