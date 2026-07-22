"use client";

import { useEffect, useMemo, useState } from "react";
import FeaturedStoryCard from "@/components/FeaturedStory";
import StoryRow from "@/components/StoryRow";

const LAST_SELECTED_KEY = "ai-audio-stories:lastSelectedStory";
const PROGRESS_KEY = "ai-audio-stories:storyProgress";

export type LibraryStory = {
  id: string;
  slug: string;
  title: string;
  short_description: string | null;
  description: string | null;
  cover_image_path: string | null;
  banner_image_path: string | null;
  content_status: string;
  episodeCount: number;
  seasonNumber: number;
  created_at: string;
};

function getStoredProgress(): Record<string, { episode: string; percentage: number }> {
  try {
    const saved = window.localStorage.getItem(PROGRESS_KEY);
    if (!saved) return {};
    return JSON.parse(saved) as Record<string, { episode: string; percentage: number }>;
  } catch {
    return {};
  }
}

function saveProgressMap(progressMap: Record<string, { episode: string; percentage: number }>) {
  try {
    window.localStorage.setItem(PROGRESS_KEY, JSON.stringify(progressMap));
  } catch {
    // ignore
  }
}

export default function StoryLibrary({ stories }: { stories: LibraryStory[] }) {
  const [lastSelectedSlug, setLastSelectedSlug] = useState<string | null>(null);
  const [progressMap, setProgressMap] = useState<Record<string, { episode: string; percentage: number }>>({});
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    let savedSlug: string | null = null;
    let savedProgress: Record<string, { episode: string; percentage: number }> = {};

    try {
      savedSlug = window.localStorage.getItem(LAST_SELECTED_KEY);
      savedProgress = getStoredProgress();
    } catch {
      // ignore client-side storage errors
    }

    /* eslint-disable react-hooks/set-state-in-effect */
    setLastSelectedSlug(savedSlug);
    setProgressMap(savedProgress);
    setHydrated(true);
    /* eslint-enable react-hooks/set-state-in-effect */
  }, []);

  const publishedStories = useMemo(
    () => stories.filter((story) => story.content_status === "published"),
    [stories]
  );

  const allPublished = useMemo(
    () => [...publishedStories].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
    [publishedStories]
  );

  const featuredStory = useMemo(() => {
    const lastSelected = lastSelectedSlug
      ? allPublished.find((story) => story.slug === lastSelectedSlug)
      : undefined;
    return lastSelected ?? allPublished[0] ?? null;
  }, [allPublished, lastSelectedSlug]);

  const continueStory = useMemo(() => {
    if (!lastSelectedSlug) return null;
    return allPublished.find((story) => story.slug === lastSelectedSlug) ?? null;
  }, [allPublished, lastSelectedSlug]);

  const continueStories = useMemo(() => {
    if (!continueStory) return [];

    const progress = progressMap[continueStory.slug] ?? {
      episode: "Episode 1",
      percentage: 10,
    };
    return [
      {
        ...continueStory,
        last_listened_episode: progress.episode,
        percentage_complete: progress.percentage,
      },
    ];
  }, [continueStory, progressMap]);

  const newestStories = useMemo(
    () => allPublished.filter((story) => story.slug !== featuredStory?.slug).slice(0, 8),
    [allPublished, featuredStory]
  );

  const comingSoonStories = useMemo(
    () => stories.filter((story) => story.content_status !== "published").slice(0, 8),
    [stories]
  );

  const handleSelect = (slug: string) => {
    try {
      window.localStorage.setItem(LAST_SELECTED_KEY, slug);
      setLastSelectedSlug(slug);
      setProgressMap((current) => {
        if (current[slug]) return current;
        const next = {
          ...current,
          [slug]: {
            episode: "Episode 4",
            percentage: 61,
          },
        };
        saveProgressMap(next);
        return next;
      });
    } catch {
      // ignore
    }
  };

  return (
    <div className="space-y-12">
      {featuredStory ? (
        <FeaturedStoryCard story={featuredStory} onSelect={handleSelect} />
      ) : null}

      {continueStories.length > 0 ? (
        <StoryRow title="Continue Listening" stories={continueStories} onSelect={handleSelect} />
      ) : null}

      <StoryRow title="Newest Stories" stories={newestStories} onSelect={handleSelect} />

      <StoryRow title="Coming Soon" stories={comingSoonStories} onSelect={handleSelect} />
    </div>
  );
}
