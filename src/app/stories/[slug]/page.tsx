import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { getStorageImageUrl } from "@/lib/supabase-storage";

type Props = {
  params: Promise<{ slug: string }>;
};

export default async function StoryPage({ params }: Props) {
  const { slug } = await params;

  const { data: story } = await supabase
    .from("stories")
    .select("id, slug, title, description, short_description, banner_image_path")
    .eq("slug", slug)
    .eq("content_status", "published")
    .single();

  if (!story) notFound();

  const { data: episodes, error } = await supabase
    .from("episodes")
    .select(
      "id, season_number, episode_number, title, summary, word_count, duration_seconds, episode_status, audio_url, artwork_path"
    )
    .eq("story_id", story.id)
    .eq("episode_status", "published")
    .order("season_number")
    .order("episode_number");

  if (error) {
    throw new Error(error.message);
  }

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
          {Object.entries(seasons).map(([seasonNumber, seasonEpisodes]) => (
            <section key={seasonNumber}>
              <h2 className="mb-4 text-2xl font-semibold text-white">
                Season {seasonNumber}
              </h2>

              <div className="space-y-4">
                {seasonEpisodes.map((episode) => (
                  <article
                    key={episode.id}
                    className="grid gap-4 rounded-3xl border border-zinc-800 bg-zinc-900 p-5 sm:grid-cols-[120px_minmax(0,1fr)] sm:p-6"
                  >
                    <div className="relative overflow-hidden rounded-3xl bg-zinc-950">
                      <div className="aspect-square">
                        <Image
                          src={getStorageImageUrl(episode.artwork_path ?? null)}
                          alt={episode.title}
                          fill
                          sizes="120px"
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
