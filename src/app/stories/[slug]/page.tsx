import Link from "next/link";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";

type Props = {
  params: Promise<{ slug: string }>;
};

export default async function StoryPage({ params }: Props) {
  const { slug } = await params;

  const { data: story } = await supabase
    .from("stories")
    .select("id, slug, title, description, short_description")
    .eq("slug", slug)
    .eq("content_status", "published")
    .single();

  if (!story) notFound();

  const { data: episodes, error } = await supabase
    .from("episodes")
    .select(
      "id, season_number, episode_number, title, summary, word_count, duration_seconds, episode_status"
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

        <p className="mt-10 text-sm uppercase tracking-widest text-emerald-400">
          AI Audio Stories
        </p>

        <h1 className="mt-3 text-4xl font-bold">{story.title}</h1>

        <p className="mt-4 text-lg text-zinc-400">
          {story.description ?? story.short_description}
        </p>

        <div className="mt-12 space-y-10">
          {Object.entries(seasons).map(([seasonNumber, seasonEpisodes]) => (
            <section key={seasonNumber}>
              <h2 className="mb-4 text-2xl font-semibold">
                Season {seasonNumber}
              </h2>

              <div className="space-y-3">
                {seasonEpisodes.map((episode) => (
                  <article
                    key={episode.id}
                    className="rounded-xl border border-zinc-800 bg-zinc-900 p-5"
                  >
                    <p className="text-sm text-emerald-400">
                      Episode {episode.episode_number}
                    </p>

                    <h3 className="mt-1 text-xl font-semibold">
                      {episode.title}
                    </h3>

                    {episode.summary && (
                      <p className="mt-2 text-zinc-400">{episode.summary}</p>
                    )}

                    <p className="mt-3 text-sm text-zinc-500">
                      {episode.word_count ?? 0} words ·{" "}
                      {Math.round((episode.duration_seconds ?? 0) / 60)} minutes
                    </p>
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