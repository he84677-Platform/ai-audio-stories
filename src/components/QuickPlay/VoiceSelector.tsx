"use client";
import React from "react";
import type { StoryQuickVoice } from "./types";

type Props = {
  profiles: StoryQuickVoice[];
  selectedId: string | null;
  onSelect: (id: string) => void;
};

export default function VoiceSelector({ profiles, selectedId, onSelect }: Props) {
  return (
    <div className="flex items-center gap-3">
      <label className="text-sm font-semibold">Narrator:</label>
      <select
        aria-label="Select narrator"
        value={selectedId ?? ""}
        onChange={(e) => onSelect(e.target.value)}
        className="rounded-md bg-zinc-800 px-2 py-1 text-sm text-white"
      >
        {profiles.map((p) => (
          <option key={p.id} value={p.id}>
            {p.display_name}
          </option>
        ))}
      </select>
    </div>
  );
}
