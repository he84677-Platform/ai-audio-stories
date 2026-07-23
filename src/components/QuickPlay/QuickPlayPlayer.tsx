"use client";
import React, { useEffect, useRef, useState } from "react";
import VoiceSelector from "./VoiceSelector";
import { resolveBrowserVoice, type BrowserVoiceResolution } from "./voiceMatcher";
import type { StoryQuickVoice, VoiceProfile, VoiceProfileRule, StorySpeakerVoice } from "./types";

type Props = {
  storySlug: string;
  text: string;
  profiles: StoryQuickVoice[];
  voiceProfiles: VoiceProfile[];
  rules: VoiceProfileRule[];
  speakerVoices: StorySpeakerVoice[];
};

const LS_KEY = (slug: string) => `discover-stories:quick-play:${slug}`;
const SAMPLE_TEXT = "This is a sample of the voice selected for Quick Play.";

function stripHtml(s: string) {
  return s.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

function isDevEnvironment() {
  return process.env.NODE_ENV !== "production";
}

export default function QuickPlayPlayer({ storySlug, text, profiles, voiceProfiles, rules, speakerVoices }: Props) {
  const supported = typeof window !== "undefined" && "speechSynthesis" in window;
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [selectedProfileId, setSelectedProfileId] = useState<string | null>(null);
  const [speed, setSpeed] = useState<number>(1);
  const [voiceCheck, setVoiceCheck] = useState<BrowserVoiceResolution | null>(null);
  const [isVoiceHelpOpen, setIsVoiceHelpOpen] = useState(false);
  const chunkIndexRef = useRef(0);
  const chunksRef = useRef<{ text: string; speakerTag: string | null }[]>([]);
  const stopRequestedRef = useRef(false);

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

  function parseSpeakerSegments(input: string) {
    // returns ordered segments with speakerTag (uppercased) or null
    // only recognized tags change speaker; unrecognized tags are stripped
    const segments: { speakerTag: string | null; text: string }[] = [];
    const re = /\[([A-Za-z0-9_ -]+)\]\s*/g;
    const recognizedTags = new Set([
      "NARRATOR",
      ...speakerVoices.map((voice) => voice.speaker_tag?.toUpperCase()).filter(Boolean),
    ]);
    let lastIndex = 0;
    let match: RegExpExecArray | null;
    let currentSpeaker: string | null = null;
    while ((match = re.exec(input)) !== null) {
      const before = input.slice(lastIndex, match.index);
      if (before.trim()) {
        segments.push({ speakerTag: currentSpeaker, text: before });
      }
      const matchedTag = match[1].toUpperCase();
      if (recognizedTags.has(matchedTag)) {
        currentSpeaker = matchedTag;
      }
      lastIndex = match.index + match[0].length;
    }
    const rest = input.slice(lastIndex);
    if (rest.trim()) segments.push({ speakerTag: currentSpeaker, text: rest });
    return segments;
  }

  function buildChunksFromSegments(input: string) {
    const cleaned = stripHtml(input);
    const segments = parseSpeakerSegments(cleaned);
    const out: { text: string; speakerTag: string | null }[] = [];
    for (const seg of segments) {
      const paras = seg.text.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
      for (const p of paras) {
        if (p.length < 2000) {
          out.push({ text: p, speakerTag: seg.speakerTag });
        } else {
          const s = p.match(/[^.!?]+[.!?]?/g) || [p];
          let buf = "";
          for (const sent of s) {
            if ((buf + " " + sent).length > 2000) {
              out.push({ text: buf.trim(), speakerTag: seg.speakerTag });
              buf = sent;
            } else {
              buf = (buf + " " + sent).trim();
            }
          }
          if (buf) out.push({ text: buf.trim(), speakerTag: seg.speakerTag });
        }
      }
    }
    return out;
  }

  function stopSpeech() {
    stopRequestedRef.current = true;
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
    stopRequestedRef.current = false;
    const chunks = buildChunksFromSegments(text || "");
    if (chunks.length === 0) return;
    chunksRef.current = chunks;
    chunkIndexRef.current = 0;
    setIsPlaying(true);
    setIsPaused(false);
    playNextChunk();
  }

  function getSelectedNarratorProfile() {
    const selectedProfileEntry = profiles.find((p) => p.id === selectedProfileId) ?? profiles.find((p) => p.is_default === true) ?? profiles[0] ?? null;
    const profile = voiceProfiles.find((voiceProfile) => voiceProfile.id === selectedProfileEntry?.voice_profile_id) ?? null;

    return {
      selectedProfileEntry,
      profile,
    };
  }

  function resolveProfileForSpeaker(speakerTag: string | null) {
    const normalizedSpeakerTag = speakerTag?.toUpperCase() ?? null;
    const { selectedProfileEntry, profile: narratorProfile } = getSelectedNarratorProfile();

    if (!normalizedSpeakerTag || normalizedSpeakerTag === "NARRATOR") {
      return {
        quickVoice: selectedProfileEntry,
        profile: narratorProfile,
        speakerTag: normalizedSpeakerTag,
      };
    }

    const speakerAssignment = speakerVoices.find((entry) => entry.speaker_tag?.toUpperCase() === normalizedSpeakerTag);
    if (!speakerAssignment) {
      return {
        quickVoice: selectedProfileEntry,
        profile: narratorProfile,
        speakerTag: normalizedSpeakerTag,
      };
    }

    return {
      quickVoice: null,
      profile: voiceProfiles.find((voiceProfile) => voiceProfile.id === speakerAssignment.voice_profile_id) ?? narratorProfile,
      speakerTag: normalizedSpeakerTag,
    };
  }

  function resolveVoiceForSpeaker(speakerTag: string | null) {
    const { profile, quickVoice, speakerTag: resolvedSpeakerTag } = resolveProfileForSpeaker(speakerTag);
    const profileRules = rules.filter((rule) => rule.voice_profile_id === profile?.id);
    const resolution = resolveBrowserVoice(voices, profile ?? ({} as VoiceProfile), profileRules);

    if (isDevEnvironment()) {
      console.info("[QuickPlay] voice resolution", {
        selectedVoiceProfile: quickVoice?.display_name ?? profile?.name ?? "Automatic",
        requestedLanguage: resolution.requestedLanguage,
        matchingRulesConsidered: resolution.consideredRules,
        actualBrowserVoiceSelected: resolution.voice?.name ?? null,
        fallbackRequired: resolution.fallbackRequired,
        currentSpeakerTag: resolvedSpeakerTag,
      });
    }

    return {
      profile,
      resolution,
    };
  }

  function playNextChunk() {
    const idx = chunkIndexRef.current;
    const chunks = chunksRef.current;
    if (idx >= chunks.length) {
      stopSpeech();
      return;
    }

    const chunk = chunks[idx];
    const utter = new SpeechSynthesisUtterance(chunk.text);

    const { profile, resolution } = resolveVoiceForSpeaker(chunk.speakerTag);

    try {
      if (resolution.voice) utter.voice = resolution.voice;
      else if (profile?.language_code) utter.lang = profile.language_code;
    } catch {
      // ignore matching errors
    }

    utter.rate = (profile?.speech_rate ?? 1) * (speed ?? 1);
    utter.pitch = profile?.speech_pitch ?? 1;

    utter.onend = () => {
      if (stopRequestedRef.current) {
        stopRequestedRef.current = false;
        return;
      }

      chunkIndexRef.current += 1;
      if (chunkIndexRef.current < chunks.length && isPlaying && !isPaused) {
        playNextChunk();
      } else {
        stopSpeech();
      }
    };

    window.speechSynthesis.speak(utter);
  }

  function handleCheckVoices() {
    if (!supported || typeof window === "undefined") {
      setVoiceCheck({
        voice: null,
        requestedLanguage: null,
        preferredFound: false,
        fallbackRequired: true,
        matchStage: "device-default",
        message: "No suitable voice found. Using your device's default voice.",
        consideredRules: [],
      });
      return;
    }

    const browserVoices = window.speechSynthesis.getVoices();
    if (browserVoices.length > 0) {
      setVoices(browserVoices);
    }

    const { resolution } = resolveVoiceForSpeaker("NARRATOR");
    setVoiceCheck(resolution);
  }

  function handleTestSelectedVoice() {
    if (!supported || typeof window === "undefined") return;

    const { profile, resolution } = resolveVoiceForSpeaker("NARRATOR");
    window.speechSynthesis.cancel();
    const utter = new SpeechSynthesisUtterance(SAMPLE_TEXT);
    if (resolution.voice) {
      utter.voice = resolution.voice;
    } else if (profile?.language_code) {
      utter.lang = profile.language_code;
    }
    utter.rate = (profile?.speech_rate ?? 1) * speed;
    utter.pitch = profile?.speech_pitch ?? 1;
    window.speechSynthesis.speak(utter);
  }

  const selectedNarrator = profiles.find((profile) => profile.id === selectedProfileId) ?? profiles.find((profile) => profile.is_default === true) ?? profiles[0] ?? null;

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

        <button
          type="button"
          onClick={handleCheckVoices}
          className="rounded-full border border-zinc-700 px-3 py-2 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
        >
          Check available voices
        </button>

        <button
          type="button"
          onClick={handleTestSelectedVoice}
          className="rounded-full border border-zinc-700 px-3 py-2 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
        >
          Test selected voice
        </button>

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

      {voiceCheck ? (
        <div className="rounded-xl border border-zinc-800 bg-zinc-950/80 p-3 text-sm text-zinc-200">
          <p className="font-semibold text-white">{voiceCheck.message}</p>
          <p className="mt-1 text-zinc-400">Selected profile: {selectedNarrator?.display_name ?? "Automatic"}</p>
          <p className="text-zinc-400">Actual browser voice: {voiceCheck.voice?.name ?? "Device default"}</p>
          <p className="text-zinc-400">Preferred voice found: {voiceCheck.preferredFound ? "Yes" : "No"}</p>
          <p className="mt-2 text-zinc-400">Available voices: {voices.length > 0 ? voices.map((voice) => voice.name).join(", ") : "Voices are still loading from your browser."}</p>
        </div>
      ) : null}

      <div className="rounded-xl border border-zinc-800 bg-zinc-950/60 p-3 text-sm text-zinc-300">
        <button
          type="button"
          onClick={() => setIsVoiceHelpOpen((current) => !current)}
          className="flex w-full items-center justify-between text-left font-semibold text-white"
          aria-expanded={isVoiceHelpOpen}
        >
          <span>How do voices work?</span>
          <span>{isVoiceHelpOpen ? "Hide" : "Show"}</span>
        </button>

        {isVoiceHelpOpen ? (
          <div className="mt-3 space-y-2 text-zinc-400">
            <p>Quick Play uses voices already available on your device. Discover Stories cannot install Microsoft voices automatically from a website.</p>
            <ol className="list-decimal space-y-1 pl-5">
              <li>Open Windows Settings.</li>
              <li>Select Time &amp; language.</li>
              <li>Select Language &amp; region.</li>
              <li>Add or select English (Australia) or English (United Kingdom).</li>
              <li>Open Language options.</li>
              <li>Install the Text-to-speech language feature.</li>
              <li>Restart Edge or Chrome.</li>
              <li>Return to Discover Stories and select Check available voices.</li>
            </ol>
            <p>Different devices may provide different voices. If your preferred voice is unavailable, Quick Play will automatically use the closest available voice.</p>
          </div>
        ) : null}
      </div>
    </div>
  );
}
