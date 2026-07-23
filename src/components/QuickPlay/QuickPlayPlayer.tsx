"use client";
import React, { useEffect, useRef, useState } from "react";
import VoiceSelector from "./VoiceSelector";
import { matchBrowserVoice } from "./voiceMatcher";
import type { StoryQuickVoice, VoiceProfile, VoiceProfileRule } from "./types";

type Props = {
  storySlug: string;
  text: string;
  profiles: StoryQuickVoice[];
  voiceProfiles: VoiceProfile[];
  rules: VoiceProfileRule[];
};

const LS_KEY = (slug: string) => `discover-stories:quick-play:${slug}`;

function stripHtml(s: string) {
  return s.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

export default function QuickPlayPlayer({ storySlug, text, profiles, voiceProfiles, rules }: Props) {
  const supported = typeof window !== "undefined" && "speechSynthesis" in window;
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [selectedProfileId, setSelectedProfileId] = useState<string | null>(null);
  const [speed, setSpeed] = useState<number>(1);
  const chunkIndexRef = useRef(0);
  const chunksRef = useRef<string[]>([]);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const load = () => {
      const v = window.speechSynthesis.getVoices();
      setVoices(v || []);
    };

    load();
    window.speechSynthesis.addEventListener("voiceschanged", load);
    return () => {
      window.speechSynthesis.removeEventListener("voiceschanged", load);
    };
  }, []);

  useEffect(() => {
    // restore preferences asynchronously to avoid synchronous setState in effect
    if (typeof window === "undefined") return;
    setTimeout(() => {
      try {
        const raw = localStorage.getItem(LS_KEY(storySlug));
        if (raw) {
          const parsed = JSON.parse(raw);
          setSelectedProfileId(parsed.profileId ?? null);
          setSpeed(parsed.speed ?? 1);
          return;
        }

        const def = profiles.find((p) => p.is_default === true) ?? profiles[0];
        setSelectedProfileId(def?.id ?? null);
        const defProfile = voiceProfiles.find((vp) => vp.id === def?.voice_profile_id);
        setSpeed(defProfile?.speech_rate ?? 1);
} catch {
        // ignore
      }
    }, 0);
  }, [profiles, voiceProfiles, storySlug]);

  useEffect(() => {
    return () => {
      if (typeof window !== "undefined" && window.speechSynthesis) {
        window.speechSynthesis.cancel();
      }
    };
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem(LS_KEY(storySlug), JSON.stringify({ profileId: selectedProfileId, speed }));
    } catch {
      // ignore
    }
  }, [selectedProfileId, speed, storySlug]);

  function buildChunks(textIn: string) {
    const cleaned = stripHtml(textIn);
    const paras = cleaned.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
    const chunks: string[] = [];
    for (const p of paras) {
      if (p.length < 2000) {
        chunks.push(p);
      } else {
        // split long paragraphs into sentences
        const s = p.match(/[^.!?]+[.!?]?/g) || [p];
        let buf = "";
        for (const sent of s) {
          if ((buf + " " + sent).length > 2000) {
            chunks.push(buf.trim());
            buf = sent;
          } else {
            buf = (buf + " " + sent).trim();
          }
        }
        if (buf) chunks.push(buf.trim());
      }
    }
    return chunks;
  }

  function stopSpeech() {
    if (typeof window !== "undefined" && window.speechSynthesis) {
      window.speechSynthesis.cancel();
    }
    setIsPlaying(false);
    setIsPaused(false);
    chunkIndexRef.current = 0;
  }

  function pauseSpeech() {
    if (typeof window !== "undefined" && window.speechSynthesis && window.speechSynthesis.speaking) {
      window.speechSynthesis.pause();
      setIsPaused(true);
    }
  }

  function resumeSpeech() {
    if (typeof window !== "undefined" && window.speechSynthesis && window.speechSynthesis.paused) {
      window.speechSynthesis.resume();
      setIsPaused(false);
    }
  }

  function playSpeech() {
    if (!supported) return;
    stopSpeech();
    const chunks = buildChunks(text || "");
    if (chunks.length === 0) return;
    chunksRef.current = chunks;
    chunkIndexRef.current = 0;
    setIsPlaying(true);
    setIsPaused(false);
    playNextChunk();
  }

  function playNextChunk() {
    const idx = chunkIndexRef.current;
    const chunks = chunksRef.current;
    if (idx >= chunks.length) {
      stopSpeech();
      return;
    }

    const chunk = chunks[idx];
    const utter = new SpeechSynthesisUtterance(chunk);

    const profileEntry = profiles.find((p) => p.id === selectedProfileId);
    const profile = voiceProfiles.find((vp) => vp.id === profileEntry?.voice_profile_id) ?? null;

    try {
      const matched = matchBrowserVoice(voices, profile ?? ({} as VoiceProfile), rules.filter((r) => r.voice_profile_id === profile?.id));
      if (matched) utter.voice = matched;
      else if (profile?.language_code) utter.lang = profile.language_code;
    } catch {
      // ignore matching errors
    }

    utter.rate = (profile?.speech_rate ?? 1) * (speed ?? 1);
    utter.pitch = profile?.speech_pitch ?? 1;

    utter.onend = () => {
      chunkIndexRef.current += 1;
      if (chunkIndexRef.current < chunks.length && isPlaying && !isPaused) {
        playNextChunk();
      } else {
        stopSpeech();
      }
    };

    window.speechSynthesis.speak(utter);
  }

  return (
    <div className="flex w-full flex-col gap-3 rounded-md bg-zinc-900/60 p-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold">Quick Play</h3>
        <p className="text-xs text-zinc-400">Uses voices on your device/browser</p>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <VoiceSelector
          profiles={profiles}
          selectedId={selectedProfileId}
          onSelect={(id) => setSelectedProfileId(id)}
        />

        <div className="flex items-center gap-2">
          <label className="text-sm">Speed</label>
          <input
            aria-label="Reading speed"
            type="range"
            min={0.5}
            max={2}
            step={0.1}
            value={speed}
            onChange={(e) => setSpeed(Number(e.target.value))}
          />
          <span className="text-sm">{speed.toFixed(1)}x</span>
        </div>

        <div className="ml-auto flex items-center gap-2">
          {!isPlaying ? (
            <button onClick={playSpeech} className="rounded-full bg-emerald-400 px-4 py-2 text-sm font-semibold text-zinc-950">
              Play
            </button>
          ) : isPaused ? (
            <>
              <button onClick={resumeSpeech} className="rounded-full bg-emerald-400 px-4 py-2 text-sm font-semibold text-zinc-950">Resume</button>
              <button onClick={stopSpeech} className="rounded-full border border-zinc-700 px-3 py-2 text-sm">Stop</button>
            </>
          ) : (
            <>
              <button onClick={pauseSpeech} className="rounded-full bg-emerald-400 px-4 py-2 text-sm font-semibold text-zinc-950">Pause</button>
              <button onClick={stopSpeech} className="rounded-full border border-zinc-700 px-3 py-2 text-sm">Stop</button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
