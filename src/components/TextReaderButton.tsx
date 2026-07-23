"use client";

import { useEffect, useMemo, useRef, useState } from "react";

export default function TextReaderButton({ text }: { text: string }) {
  const [isReading, setIsReading] = useState(false);
  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);

  const canSpeak = useMemo(() => {
    return typeof window !== "undefined" && "speechSynthesis" in window;
  }, []);

  useEffect(() => {
    return () => {
      if (typeof window !== "undefined" && window.speechSynthesis) {
        window.speechSynthesis.cancel();
      }
    };
  }, []);

  const startReading = () => {
    if (!canSpeak || !text) return;

    if (utteranceRef.current) {
      window.speechSynthesis.cancel();
      utteranceRef.current = null;
    }

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "en-US";
    utterance.onend = () => setIsReading(false);
    utterance.onerror = () => setIsReading(false);
    utteranceRef.current = utterance;
    window.speechSynthesis.speak(utterance);
    setIsReading(true);
  };

  const stopReading = () => {
    if (typeof window !== "undefined" && window.speechSynthesis) {
      window.speechSynthesis.cancel();
      setIsReading(false);
    }
  };

  const handleToggle = () => {
    if (isReading) {
      stopReading();
    } else {
      startReading();
    }
  };

  if (!canSpeak) {
    return null;
  }

  return (
    <button
      type="button"
      onClick={handleToggle}
      className="inline-flex items-center justify-center rounded-full border border-zinc-700 bg-zinc-950/90 px-3 py-2 text-sm font-semibold text-white transition hover:border-emerald-400 hover:text-emerald-300"
    >
      {isReading ? "Stop read" : "Quick read"}
    </button>
  );
}
