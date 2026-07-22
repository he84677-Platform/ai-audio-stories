"use client";

import Image from "next/image";
import Link from "next/link";
import { useMemo, useRef, useState } from "react";
import { getStorageImageUrl } from "@/lib/supabase-storage";

export type Story = {
  id: string;
  slug: string;
  title: string;
  short_description: string | null;
  cover_image_path: string | null;
  content_status: string;
};

const storageKey = "ai-audio-stories:lastSelectedStory";

function reorderStories(stories: Story[], selectedSlug: string | null) {
  if (!selectedSlug) return stories;

  const index = stories.findIndex((story) => story.slug === selectedSlug);
  if (index <= 0) return stories;

  const selected = stories[index];
  return [selected, ...stories.slice(0, index), ...stories.slice(index + 1)];
}

export default function StoriesCarousel({ initialStories }: { initialStories: Story[] }) {
  const [selectedSlug, setSelectedSlug] = useState<string | null>(() => {
    if (typeof window === "undefined") return null;
    try {
      return window.localStorage.getItem(storageKey);
    } catch {
      return null;
    }
  });
  const carouselRef = useRef<HTMLDivElement | null>(null);

  const stories = useMemo(
    () => reorderStories(initialStories, selectedSlug),
    [initialStories, selectedSlug]
  );

  const handleSelect = (slug: string) => {
    try {
      window.localStorage.setItem(storageKey, slug);
    } catch {
      // ignore client-side storage errors
    }
    setSelectedSlug(slug);
  };

  const scrollByCard = (direction: "prev" | "next") => {
    if (!carouselRef.current) return;
    const offset = carouselRef.current.clientWidth * 0.8;
    carouselRef.current.scrollBy({
      left: direction === "next" ? offset : -offset,
      behavior: "smooth",
    });
  };

  return (
    <div>
      <div className="mb-4 rounded-2xl border border-zinc-800 bg-zinc-900 p-5 text-sm text-zinc-400">
        <p className="mb-1 text-emerald-400">Swipe or scroll horizontally</p>
        <p>Last selected story is pinned first in the carousel.</p>
      </div>

      <div className="relative">
        <div className="absolute left-4 top-1/2 hidden -translate-y-1/2 gap-2 sm:flex">
          <button
            type="button"
            onClick={() => scrollByCard("prev")}
            className="rounded-full border border-zinc-800 bg-zinc-900 px-3 py-2 text-sm text-zinc-300 transition hover:border-emerald-400 hover:text-white"
          >
            ←
          </button>
          <button
            type="button"
            onClick={() => scrollByCard("next")}
            className="rounded-full border border-zinc-800 bg-zinc-900 px-3 py-2 text-sm text-zinc-300 transition hover:border-emerald-400 hover:text-white"
          >
            →
          </button>
        </div>

        <div ref={carouselRef} className="no-scrollbar overflow-x-auto pb-3 scroll-smooth">
          <div className="flex gap-5 snap-x snap-mandatory px-3 sm:px-0">
            {stories.map((story) => (
              <Link
                key={story.id}
                href={`/stories/${story.slug}`}
                onClick={() => handleSelect(story.slug)}
                className="group w-[82vw] max-w-[21.25rem] sm:w-[21.25rem] h-[34rem] flex-shrink-0 snap-start overflow-hidden rounded-3xl border border-zinc-800 bg-zinc-900 text-left transition hover:border-emerald-400 hover:shadow-[0_20px_60px_rgba(8,11,16,0.45)]"
              >
                <div className="relative overflow-hidden bg-zinc-950">
                  <div className="aspect-[3/2] overflow-hidden transition duration-500 group-hover:scale-105">
                    <Image
                      src={getStorageImageUrl(story.cover_image_path)}
                      alt={story.title}
                      fill
                      sizes="(max-width: 640px) 82vw, 340px"
                      className="object-cover"
                    />
                  </div>
                </div>

                <div className="flex h-[calc(100%-14rem)] flex-col justify-between p-6">
                  <div>
                    <span className="inline-flex rounded-full bg-emerald-400/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-300">
                      {story.content_status === "published" ? "Published" : story.content_status}
                    </span>

                    <h2
                      className="mt-4 mb-3 text-2xl font-semibold leading-tight text-white"
                      style={{
                        display: "-webkit-box",
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: "vertical",
                        overflow: "hidden",
                      }}
                    >
                      {story.title}
                    </h2>

                    <p
                      className="text-sm leading-6 text-zinc-400"
                      style={{
                        display: "-webkit-box",
                        WebkitLineClamp: 3,
                        WebkitBoxOrient: "vertical",
                        overflow: "hidden",
                      }}
                    >
                      {story.short_description ?? "No description yet."}
                    </p>
                  </div>

                  <div className="pt-4">
                    <span className="text-sm font-semibold text-white transition group-hover:text-emerald-300">
                      View Story →
                    </span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
