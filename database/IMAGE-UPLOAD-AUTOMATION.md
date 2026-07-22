# Automatic image upload process

Use the `story-images` bucket and upload files using:

```text
the-cartographers-dream/cover.png
the-cartographers-dream/banner.png
the-cartographers-dream/episodes/episode-01.png
```

The story folder must exactly match `stories.slug`; episode numbers must match
`episodes.episode_number`.

## Setup

1. Run `database/007_image_upload_automation.sql` in the Supabase SQL Editor.
2. Deploy the `sync-storage-image` Edge Function from `supabase/functions/sync-storage-image/index.ts`.
3. Create Database Webhooks on `storage.objects` for events `INSERT` and `UPDATE`, targeting that Edge Function. `UPDATE` allows replacing an image at the same path.
4. Run the one-time backfill:

```sql
select * from public.sync_existing_story_images(
  'story-images', 'https://YOUR_PROJECT_REF.supabase.co'
);
```

After setup, uploading a correctly named image updates the database within a
few seconds. Replacing an image at the same path is safe.
