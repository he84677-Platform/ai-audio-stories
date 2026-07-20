import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default async function Home() {
  const { data: stories, error } = await supabase
    .from("stories")
    .select("id, slug, title, short_description, content_status")
    .order("created_at", { ascending: false });

  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-white">
      <div className="mx-auto max-w-4xl">
        <p className="mb-3 text-sm uppercase tracking-widest text-emerald-400">
          AI Audio Stories
        </p>

        <h1 className="mb-4 text-4xl font-bold">
          Your story library
        </h1>

        <p className="mb-10 text-zinc-400">
          Stories are being read from Supabase.
        </p>

        {error ? (
          <p className="rounded-lg bg-red-950 p-4 text-red-300">
            Supabase error: {error.message}
          </p>
        ) : stories && stories.length > 0 ? (
          <div className="grid gap-5 sm:grid-cols-2">
            {stories.map((story) => (
              <article
                key={story.id}
                className="rounded-xl border border-zinc-800 bg-zinc-900 p-6"
              >
                <p className="mb-2 text-sm text-emerald-400">
                  {story.content_status}
                </p>

                <h2 className="mb-2 text-2xl font-semibold">
                  {story.title}
                </h2>

                <p className="text-zinc-400">
                  {story.short_description ?? "No description yet."}
                </p>
              </article>
            ))}
          </div>
        ) : (
          <p className="rounded-lg border border-zinc-800 bg-zinc-900 p-6 text-zinc-400">
            No stories have been added yet.
          </p>
        )}
      </div>
    </main>
  );
}