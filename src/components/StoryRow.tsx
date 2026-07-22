"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { getStorageImageUrl } from "@/lib/supabase-storage";

export type RowStory = {
  id: string;
  slug: string;
  title: string;
  short_description: string | null;
  cover_image_path: string | null;
  content_status: string;
  last_listened_episode?: string | null;
  percentage_complete?: number | null;
};

export default function StoryRow({
  title,
  stories,
  onSelect,
}: {
  title: string;
  stories: RowStory[];
  onSelect?: (slug: string) => void;
}) {
  const [hoveredId, setHoveredId] = useState<string | null>(null);

  return (
    <section className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold text-white">{title}</h2>
      </div>

      {stories.length === 0 ? (
        <div className="rounded-3xl border border-zinc-800 bg-zinc-900 p-8 text-center text-sm text-zinc-400">
          No stories found in this category yet.
        </div>
      ) : (
        <div className="no-scrollbar flex gap-4 overflow-x-auto pb-3">
          {stories.map((story) => (
            <Link
              key={story.id}
              href={`/stories/${story.slug}`}
              onClick={() => onSelect?.(story.slug)}
              onMouseEnter={() => setHoveredId(story.id)}
              onMouseLeave={() => setHoveredId(null)}
              className="group relative min-w-[18rem] max-w-[21.25rem] flex-shrink-0 h-full overflow-hidden rounded-3xl border border-zinc-800 bg-zinc-900 transition hover:border-emerald-400"
            >
              <div className="relative aspect-[3/2] overflow-hidden bg-zinc-950">
                <Image
                  src={getStorageImageUrl(story.cover_image_path)}
                  alt={story.title}
                  fill
                  sizes="(max-width: 640px) 82vw, 340px"
                  className="object-cover transition duration-500 group-hover:scale-105"
                />
              </div>

              <div className="flex h-full flex-col justify-between space-y-4 p-5">
                <div className="space-y-2">
                  <p className="text-sm uppercase tracking-[0.24em] text-emerald-400">
                    {story.content_status}
                  </p>
                  <h3 className="text-2xl font-semibold leading-tight text-white line-clamp-2">
                    {story.title}
                  </h3>
                  <p className="text-sm leading-6 text-zinc-400 line-clamp-3">
                    {story.short_description ?? "No description yet."}
                  </p>
                </div>

                {story.last_listened_episode && story.percentage_complete != null ? (
                  <div className="rounded-3xl border border-zinc-800 bg-zinc-950 p-4">
                    <p className="text-xs uppercase tracking-[0.24em] text-emerald-400">
                      Continue Listening
                    </p>
                    <p className="mt-2 text-sm font-semibold text-white">
                      {story.last_listened_episode}
                    </p>
                    <div className="mt-3 h-2 overflow-hidden rounded-full bg-zinc-800">
                      <div
                        className="h-full rounded-full bg-emerald-400"
                        style={{ width: `${story.percentage_complete}%` }}
                      />
                    </div>
                    <p className="mt-2 text-xs text-zinc-500">
                      {story.percentage_complete}%
                    </p>
                  </div>
                ) : null}

                {hoveredId === story.id ? (
                  <div className="space-y-2 rounded-3xl border border-emerald-400/20 bg-zinc-950/95 p-4 text-sm text-zinc-300">
                    <p className="font-semibold text-white">
                      {story.last_listened_episode ? "Continue Listening" : "Story preview"}
                    </p>
                    <p>{story.short_description ?? "Discover this story."}</p>
                    {story.last_listened_episode ? (
                      <p className="text-xs text-zinc-500">
                        Resume at {story.last_listened_episode} • {story.percentage_complete}% complete
                      </p>
                    ) : null}
                  </div>
                ) : (
                  <div className="flex items-center justify-between pt-4">
                    <span className="text-sm font-semibold text-emerald-300">
                      View Story →
                    </span>
                  </div>
                )}
              </div>
            </Link>
          ))}
        </div>
      )}
    </section>
  );
}
