"use client";

import Image from "next/image";
import Link from "next/link";
import { getStorageImageUrl } from "@/lib/supabase-storage";

export type FeaturedStory = {
  id: number;
  slug: string;
  title: string;
  short_description: string | null;
  cover_image_path: string | null;
  banner_image_path: string | null;
  content_status: string;
  episodeCount: number;
  seasonNumber: number;
  created_at: string;
};

export default function FeaturedStoryCard({
  story,
  onSelect,
}: {
  story: FeaturedStory;
  onSelect?: (slug: string) => void;
}) {
  const isNewThisWeek =
    new Date(story.created_at) >=
    new Date(Date.now() - 1000 * 60 * 60 * 24 * 7);

  return (
    <section className="relative overflow-hidden rounded-[2rem] border border-zinc-800 bg-zinc-900 text-white shadow-[0_25px_80px_rgba(0,0,0,0.35)]">
      <div className="relative h-[24rem] sm:h-[32rem]">
        <Image
          src={getStorageImageUrl(story.banner_image_path ?? story.cover_image_path)}
          alt={story.title}
          fill
          sizes="100vw"
          className="object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-transparent to-transparent opacity-95" />
      </div>

      <div className="absolute inset-x-0 bottom-0 p-6 sm:p-10">
        <div className="mb-4 flex flex-wrap items-center gap-3 text-sm uppercase tracking-[0.24em] text-emerald-400">
          <span>Featured</span>
          {isNewThisWeek && (
            <span className="rounded-full bg-emerald-400/10 px-3 py-1 text-emerald-300">
              New Episode This Week
            </span>
          )}
        </div>

        <h1 className="max-w-3xl text-5xl font-bold leading-tight text-white sm:text-6xl">
          {story.title}
        </h1>

        <p className="mt-4 max-w-3xl text-sm leading-6 text-zinc-200 sm:text-base">
          {story.short_description ?? "Explore the latest cinematic audio story."}
        </p>

        <div className="mt-8 flex flex-wrap items-center gap-4">
          <Link
            href={`/stories/${story.slug}`}
            onClick={() => onSelect?.(story.slug)}
            className="inline-flex items-center justify-center rounded-full bg-emerald-400 px-8 py-3 text-sm font-semibold text-zinc-950 transition hover:bg-emerald-300"
          >
            ▶ Listen Now
          </Link>
          <Link
            href={`/stories/${story.slug}`}
            onClick={() => onSelect?.(story.slug)}
            className="inline-flex items-center justify-center rounded-full border border-zinc-700 bg-zinc-950/80 px-8 py-3 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
          >
            ℹ View Story
          </Link>
        </div>

        <p className="mt-6 text-sm text-zinc-400">
          Season {story.seasonNumber} • {story.episodeCount} Episodes
        </p>
      </div>
    </section>
  );
}
