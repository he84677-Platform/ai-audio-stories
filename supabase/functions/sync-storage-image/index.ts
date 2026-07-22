import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL")!;
const bucket = Deno.env.get("SUPABASE_STORAGE_BUCKET") ?? "story-images";
const db = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (request) => {
  try {
    const payload = await request.json();
    const objectName = payload?.record?.name as string | undefined;
    const bucketId = payload?.record?.bucket_id as string | undefined;
    const metadata = payload?.record?.metadata ?? {};
    const mimeType = metadata.mimetype ?? metadata.mimeType ?? "";

    if (!objectName || bucketId !== bucket || !mimeType.startsWith("image/")) {
      return Response.json({ ignored: true });
    }

    const storySlug = objectName.split("/")[0];
    const story = await db.from("stories").select("id").eq("slug", storySlug).single();
    if (story.error) throw new Error(`Story '${storySlug}' not found: ${story.error.message}`);
    const publicUrl = `${url}/storage/v1/object/public/${bucket}/${objectName}`;
    let assetType: "cover_image" | "episode_image";
    let episodeId: string | null = null;

    if (/\/cover\.[a-z0-9]+$/i.test(objectName)) {
      assetType = "cover_image";
      const result = await db.from("stories").update({ cover_image_path: objectName, cover_image_url: publicUrl, updated_at: new Date().toISOString() }).eq("id", story.data.id);
      if (result.error) throw result.error;
    } else if (/\/banner\.[a-z0-9]+$/i.test(objectName)) {
      assetType = "cover_image";
      const result = await db.from("stories").update({ banner_image_path: objectName, updated_at: new Date().toISOString() }).eq("id", story.data.id);
      if (result.error) throw result.error;
    } else {
      const match = objectName.match(/\/episodes\/episode-([0-9]+)\.[a-z0-9]+$/i);
      if (!match) return Response.json({ ignored: true, reason: "Unsupported filename" });
      const episode = await db.from("episodes").select("id").eq("story_id", story.data.id).eq("episode_number", Number(match[1])).single();
      if (episode.error) throw new Error(`Episode ${match[1]} not found: ${episode.error.message}`);
      assetType = "episode_image";
      episodeId = episode.data.id;
      const result = await db.from("episodes").update({ artwork_path: objectName, artwork_url: publicUrl, updated_at: new Date().toISOString() }).eq("id", episodeId);
      if (result.error) throw result.error;
    }

    const result = await db.from("media_assets").upsert({
      story_id: assetType === "cover_image" ? story.data.id : null,
      episode_id: episodeId,
      asset_type: assetType,
      storage_provider: "supabase",
      storage_path: objectName,
      public_url: publicUrl,
      mime_type: mimeType,
      file_size_bytes: Number(metadata.size ?? 0) || null,
    }, { onConflict: "storage_path" });
    if (result.error) throw result.error;

    return Response.json({ updated: true, objectName });
  } catch (error) {
    console.error(error);
    return Response.json({ error: String(error) }, { status: 500 });
  }
});
