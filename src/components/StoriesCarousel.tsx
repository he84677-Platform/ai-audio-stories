"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

export type Story = {
  id: number;
  slug: string;
  title: string;
  short_description: string | null;
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
  const [selectedSlug, setSelectedSlug] = useState<string | null>(null);

  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(storageKey);
      if (saved) setSelectedSlug(saved);
    } catch {
      // ignore client-side storage errors
    }
  }, []);

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

  return (
    <div>
      <div className="mb-4 rounded-2xl border border-zinc-800 bg-zinc-900 p-5 text-sm text-zinc-400">
        <p className="mb-1 text-emerald-400">Swipe or scroll horizontally</p>
        <p>Last selected story is pinned first in the carousel.</p>
      </div>

      <div className="no-scrollbar overflow-x-auto pb-3">
        <div className="flex gap-5 snap-x snap-mandatory">
          {stories.map((story) => (
            <Link
              key={story.id}
              href={`/stories/${story.slug}`}
              onClick={() => handleSelect(story.slug)}
              className="min-w-[20rem] flex-shrink-0 snap-start rounded-xl border border-zinc-800 bg-zinc-900 p-6 transition hover:border-emerald-400"
            >
              <p className="mb-2 text-sm text-emerald-400">{story.content_status}</p>
              <h2 className="mb-2 text-2xl font-semibold">{story.title}</h2>
              <p className="text-zinc-400">{story.short_description ?? "No description yet."}</p>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
