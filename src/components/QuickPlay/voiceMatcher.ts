import type { VoiceProfile, VoiceProfileRule } from "./types";

export type BrowserVoiceResolution = {
  voice: SpeechSynthesisVoice | null;
  requestedLanguage: string | null;
  preferredFound: boolean;
  fallbackRequired: boolean;
  matchStage:
    | "exact-name"
    | "provider-language"
    | "language"
    | "general-english"
    | "browser-default"
    | "device-default";
  message: string;
  consideredRules: string[];
};

function normalize(value?: string | null) {
  return (value ?? "").trim().toLowerCase();
}

function matchesLocal(voice: SpeechSynthesisVoice, localOnly?: boolean | null) {
  if (localOnly === true) return voice.localService === true;
  if (localOnly === false) return voice.localService === false;
  return true;
}

function matchesProvider(voice: SpeechSynthesisVoice, provider?: string | null) {
  if (!provider) return true;
  const term = normalize(provider);
  return normalize(voice.name).includes(term) || normalize(voice.voiceURI).includes(term);
}

function languageRank(voiceLangRaw: string | undefined, requestedRaw?: string | null) {
  const voiceLang = normalize(voiceLangRaw);
  const requested = normalize(requestedRaw);

  if (!requested) {
    return voiceLang.startsWith("en") ? 3 : -1;
  }

  const base = requested.split("-")[0];
  if (voiceLang === requested) return 0;

  if (requested === "en-au") {
    if (voiceLang === "en-gb" || voiceLang === "en-us") return 1;
    if (voiceLang.startsWith("en")) return 2;
    return -1;
  }

  if (requested === "en-gb" || requested === "en-us") {
    if (voiceLang.startsWith("en")) return 2;
    return -1;
  }

  if (voiceLang.startsWith(`${base}-`) || voiceLang === base) return 2;
  return -1;
}

function describeRule(rule: VoiceProfileRule) {
  return [
    `rule:${rule.id}`,
    rule.voice_name_contains ? `name~${rule.voice_name_contains}` : null,
    rule.provider_contains ? `provider~${rule.provider_contains}` : null,
    rule.language_code ? `lang=${rule.language_code}` : null,
    rule.local_only === null || rule.local_only === undefined ? null : `local=${String(rule.local_only)}`,
  ]
    .filter(Boolean)
    .join(" ");
}

export function resolveBrowserVoice(
  voices: SpeechSynthesisVoice[],
  profile: VoiceProfile,
  rules: VoiceProfileRule[]
): BrowserVoiceResolution {
  const sortedRules = [...rules].sort((a, b) => (a.priority ?? 0) - (b.priority ?? 0));
  const consideredRules = sortedRules.map(describeRule);
  const requestedLanguage = profile.language_code ?? sortedRules.find((rule) => rule.language_code)?.language_code ?? null;

  if (!voices || voices.length === 0) {
    return {
      voice: null,
      requestedLanguage,
      preferredFound: false,
      fallbackRequired: true,
      matchStage: "device-default",
      message: "No suitable voice found. Using your device's default voice.",
      consideredRules,
    };
  }

  for (const rule of sortedRules) {
    if (!rule.voice_name_contains) continue;

    const candidate = voices.find((voice) => {
      return (
        normalize(voice.name) === normalize(rule.voice_name_contains) &&
        matchesProvider(voice, rule.provider_contains) &&
        matchesLocal(voice, rule.local_only) &&
        (rule.language_code ? languageRank(voice.lang, rule.language_code) >= 0 : true)
      );
    });

    if (candidate) {
      return {
        voice: candidate,
        requestedLanguage,
        preferredFound: true,
        fallbackRequired: false,
        matchStage: "exact-name",
        message: `Voice found: ${candidate.name}`,
        consideredRules,
      };
    }
  }

  for (const rule of sortedRules) {
    const lang = rule.language_code ?? requestedLanguage;
    if (!rule.provider_contains || !lang) continue;

    const candidate = voices.find((voice) => {
      return (
        matchesProvider(voice, rule.provider_contains) &&
        matchesLocal(voice, rule.local_only) &&
        languageRank(voice.lang, lang) >= 0
      );
    });

    if (candidate) {
      return {
        voice: candidate,
        requestedLanguage,
        preferredFound: false,
        fallbackRequired: true,
        matchStage: "provider-language",
        message: `Preferred voice not found. Using ${candidate.name} as fallback.`,
        consideredRules,
      };
    }
  }

  if (requestedLanguage) {
    const languageCandidates = voices
      .filter((voice) => languageRank(voice.lang, requestedLanguage) >= 0)
      .sort((left, right) => languageRank(left.lang, requestedLanguage) - languageRank(right.lang, requestedLanguage));

    if (languageCandidates[0]) {
      return {
        voice: languageCandidates[0],
        requestedLanguage,
        preferredFound: false,
        fallbackRequired: true,
        matchStage: "language",
        message: `Preferred voice not found. Using ${languageCandidates[0].name} as fallback.`,
        consideredRules,
      };
    }
  }

  const englishVoice = voices.find((voice) => normalize(voice.lang).startsWith("en"));
  if (englishVoice) {
    return {
      voice: englishVoice,
      requestedLanguage,
      preferredFound: false,
      fallbackRequired: true,
      matchStage: "general-english",
      message: `Preferred voice not found. Using ${englishVoice.name} as fallback.`,
      consideredRules,
    };
  }

  const browserDefaultVoice = voices.find((voice) => voice.default) ?? voices[0] ?? null;
  if (browserDefaultVoice) {
    return {
      voice: browserDefaultVoice,
      requestedLanguage,
      preferredFound: false,
      fallbackRequired: true,
      matchStage: "browser-default",
      message: `No suitable voice found. Using ${browserDefaultVoice.name} as fallback.`,
      consideredRules,
    };
  }

  return {
    voice: null,
    requestedLanguage,
    preferredFound: false,
    fallbackRequired: true,
    matchStage: "device-default",
    message: "No suitable voice found. Using your device's default voice.",
    consideredRules,
  };
}

export function matchBrowserVoice(
  voices: SpeechSynthesisVoice[],
  profile: VoiceProfile,
  rules: VoiceProfileRule[]
): SpeechSynthesisVoice | null {
  return resolveBrowserVoice(voices, profile, rules).voice;
}
