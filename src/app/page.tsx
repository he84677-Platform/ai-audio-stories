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
        ) : stories && stories.length > 0 ? (
          <StoryLibrary stories={stories} />
        ) : (
          <p className="rounded-lg border border-zinc-800 bg-zinc-900 p-6 text-zinc-400">
            No stories have been added yet.
          </p>
        )}
      </div>
    </main>
  );
}
