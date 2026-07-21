const bucketName = "story-images";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/+$/, "");

if (!supabaseUrl) {
  throw new Error("Missing NEXT_PUBLIC_SUPABASE_URL environment variable.");
}

export function getPublicStorageUrl(path: string): string {
  const trimmedPath = path.replace(/^\/+/, "");
  return `${supabaseUrl}/storage/v1/object/public/${bucketName}/${trimmedPath}`;
}

export function getStorageImageUrl(imagePath: string | null): string {
  if (!imagePath) {
    return "/images/story-placeholder.png";
  }

  return getPublicStorageUrl(imagePath);
}
