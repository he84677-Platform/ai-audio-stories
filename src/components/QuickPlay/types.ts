export type StoryQuickVoice = {
  id: string;
  voice_profile_id: string;
  display_name: string;
  description?: string | null;
  is_default?: boolean;
  display_order?: number;
};

export type VoiceProfileRule = {
  id: string;
  voice_profile_id: string;
  priority?: number | null;
  voice_name_contains?: string | null;
  provider_contains?: string | null;
  language_code?: string | null;
  local_only?: boolean | null;
};

export type VoiceProfile = {
  id: string;
  name?: string | null;
  speech_rate?: number | null;
  speech_pitch?: number | null;
  language_code?: string | null;
};
