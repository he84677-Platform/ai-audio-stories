import type { VoiceProfile, VoiceProfileRule } from "./types";

export function matchBrowserVoice(
  voices: SpeechSynthesisVoice[],
  profile: VoiceProfile,
  rules: VoiceProfileRule[]
): SpeechSynthesisVoice | null {
  if (!voices || voices.length === 0) return null;

  const sorted = [...rules].sort((a, b) => (a.priority ?? 0) - (b.priority ?? 0));

  for (const rule of sorted) {
    const candidate = voices.find((v) => {
      if (rule.voice_name_contains) {
        if (!v.name.toLowerCase().includes(rule.voice_name_contains.toLowerCase())) return false;
      }
      if (rule.provider_contains) {
        const prov = rule.provider_contains.toLowerCase();
        if (!(v.name.toLowerCase().includes(prov) || (v.voiceURI || "").toLowerCase().includes(prov))) return false;
      }
      if (rule.language_code) {
        const lc = rule.language_code.toLowerCase();
        const vlang = (v.lang || "").toLowerCase();
        if (lc.length === 2) {
          if (!vlang.startsWith(lc)) return false;
        } else {
          if (vlang !== lc) return false;
        }
      }
      if (rule.local_only === true && v.localService !== true) return false;
      if (rule.local_only === false && v.localService !== false) return false;
      return true;
    });

    if (candidate) return candidate;
  }

  return null;
}
