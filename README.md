This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!
## Image upload automation

This project includes support for syncing Supabase Storage images into the database for story cover, banner, and episode artwork.

1. Apply `database/007_image_upload_automation.sql` in the Supabase SQL editor.
2. Deploy the Edge Function at `supabase/functions/sync-storage-image/index.ts`.
3. Configure a Supabase storage webhook on `storage.objects` for `INSERT` and `UPDATE` events.
4. Run the one-time backfill with:

```sql
select * from public.sync_existing_story_images(
  'story-images', 'https://YOUR_PROJECT_REF.supabase.co'
);
```

For more details, see `database/IMAGE-UPLOAD-AUTOMATION.md`.

### Supabase Edge Function environment variables

Set the following environment variables for the deployed `sync-storage-image` Edge Function:

- `SUPABASE_URL` — your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` — service role key used by the function
- `SUPABASE_STORAGE_BUCKET` — optional, defaults to `story-images`

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
