import Link from "next/link";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";

type Props = {
  params: Promise<{ slug: string; episodeNumber: string }>;
};

export default async function EpisodeReadPage({ params }: Props) {
  const { slug, episodeNumber } = await params;
  const episodeIndex = Number(episodeNumber);
  if (!Number.isInteger(episodeIndex) || episodeIndex <= 0) {
    notFound();
  }

  const { data: story } = await supabase
    .from("stories")
    .select("id, slug, title")
    .eq("slug", slug)
    .eq("content_status", "published")
    .single();

  if (!story) {
    notFound();
  }

  const { data: episode, error } = await supabase
    .from("episodes")
    .select("id, episode_number, title, summary, script_text, audio_url")
    .eq("story_id", story.id)
    .eq("episode_number", episodeIndex)
    .eq("episode_status", "published")
    .single();

  if (!episode || error) {
    notFound();
  }

  const { data: nextEpisode } = await supabase
    .from("episodes")
    .select("episode_number")
    .eq("story_id", story.id)
    .gt("episode_number", episodeIndex)
    .eq("episode_status", "published")
    .order("episode_number", { ascending: true })
    .limit(1)
    .single();

  const nextEpisodeNumber = nextEpisode?.episode_number ?? null;
  const content = episode.script_text?.trim() || episode.summary || "No readable content is available for this episode.";

  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-white">
      <div className="mx-auto flex max-w-4xl flex-col gap-8 overflow-hidden">
        <div className="flex flex-col gap-4 rounded-[2rem] border border-zinc-800 bg-zinc-900 p-6 sm:p-8">
          <div className="flex flex-col gap-2">
            <p className="text-xs uppercase tracking-[0.24em] text-emerald-400">Read episode</p>
            <h1 className="text-2xl font-bold leading-tight text-white sm:text-3xl">
              {story.title}
            </h1>
            <p className="text-sm text-zinc-500">
              Episode {episode.episode_number}: {episode.title}
            </p>
          </div>

          <div className="flex flex-wrap gap-3">
            <Link
              href={`/stories/${story.slug}`}
              className="inline-flex items-center justify-center rounded-full border border-zinc-700 bg-zinc-950/90 px-4 py-2 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
            >
              Back to story
            </Link>
            {episode.audio_url ? (
              <a
                href={episode.audio_url}
                className="inline-flex items-center justify-center rounded-full bg-emerald-400 px-4 py-2 text-sm font-semibold text-zinc-950 transition hover:bg-emerald-300"
              >
                Play audio
              </a>
            ) : null}
            {nextEpisodeNumber ? (
              <Link
                href={`/stories/${story.slug}/episodes/${nextEpisodeNumber}`}
                className="inline-flex items-center justify-center rounded-full border border-emerald-400 bg-emerald-500/10 px-4 py-2 text-sm font-semibold text-emerald-300 transition hover:bg-emerald-400/10"
              >
                Next episode
              </Link>
            ) : null}
          </div>
        </div>

        <div className="flex flex-col overflow-hidden rounded-[2rem] border border-zinc-800 bg-zinc-900">
          <article className="max-h-[calc(100vh-15rem)] overflow-y-auto p-6 sm:p-8">
            <div className="prose prose-invert max-w-none space-y-6 text-zinc-200">
              <div className="whitespace-pre-wrap text-base leading-7">
                {content}
              </div>
            </div>
          </article>
        </div>
      </div>
    </main>
  );
}
