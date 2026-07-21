import { supabase } from "@/lib/supabase";
import StoryLibrary from "@/components/StoryLibrary";

export const dynamic = "force-dynamic";

export default async function Home() {
  const { data: stories, error } = await supabase
    .from("stories")
    .select(
      "id, slug, title, short_description, description, content_status, cover_image_path, banner_image_path, created_at"
    )
    .order("created_at", { ascending: false });

  const storyIds = stories?.map((story) => story.id) ?? [];
  let episodeRows: Array<{ story_id: string; season_number: number | null }> = [];

  if (storyIds.length > 0) {
    const { data, error: episodeError } = await supabase
      .from("episodes")
      .select("story_id, season_number")
      .in("story_id", storyIds)
      .eq("episode_status", "published");

    if (episodeError) {
      throw new Error(episodeError.message);
    }

    episodeRows = data ?? [];
  }

  const episodeCountByStory = episodeRows.reduce(
    (counts, episode) => {
      counts[episode.story_id] = (counts[episode.story_id] ?? 0) + 1;
      return counts;
    },
    {} as Record<string, number>
  );

  const seasonNumberByStory = episodeRows.reduce(
    (seasons, episode) => {
      const season = episode.season_number ?? 1;
      seasons[episode.story_id] = seasons[episode.story_id]
        ? Math.min(seasons[episode.story_id], season)
        : season;
      return seasons;
    },
    {} as Record<string, number>
  );

  const storiesWithEpisodeCount = stories?.map((story) => ({
    ...story,
    episodeCount: episodeCountByStory[story.id] ?? 0,
    seasonNumber: seasonNumberByStory[story.id] ?? 1,
  })) ?? [];

  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-white">
      <div className="mx-auto max-w-6xl">
        <div className="mb-10 space-y-3">
          <p className="text-sm uppercase tracking-widest text-emerald-400">
            AI Audio Stories
          </p>
          <h1 className="text-4xl font-bold">Your story library</h1>
          <p className="max-w-3xl text-zinc-400">
            Discover cinematic audio stories, resume your listening, and explore featured titles.
          </p>
        </div>

        {error ? (
          <p className="rounded-lg bg-red-950 p-4 text-red-300">
            Supabase error: {error.message}
          </p>
        ) : storiesWithEpisodeCount && storiesWithEpisodeCount.length > 0 ? (
          <StoryLibrary stories={storiesWithEpisodeCount} />
        ) : (
          <p className="rounded-lg border border-zinc-800 bg-zinc-900 p-6 text-zinc-400">
            No stories have been added yet.
          </p>
        )}
      </div>
    </main>
  );
}
