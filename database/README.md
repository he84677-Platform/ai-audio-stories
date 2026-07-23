# Database scripts

This folder contains SQL migrations, seed data, and automation scripts used by the Discover Stories project.

## Files

- `001_initial_schema.sql` - Initial database schema.
- `002_story_read_policy.sql` - Row-level security and story read policy.
- `002_wiki_story_bible_schema.sql` - Wiki/story bible schema for public story wiki data.
- `003_seed_life_inside_the_dyson_wiki.sql` - Seed story data for "Life Inside the Dyson" and associated wiki content.
- `003_seed_story.sql` - Additional seed data for published stories.
- `004_schema_updates.sql` - Schema updates and migration SQL.
- `005_seed_life_inside_the_dyson_wiki.sql` - Extended seed data for the Dyson story wiki.
- `006_public_wiki_api (1).sql` - Public wiki API and RPC helpers.
- `007_image_upload_automation.sql` - Image upload automation schema for Supabase storage/webhook sync.
- `007_seed_ash_and_silver.sql` - New seed script for the "Ash and Silver" story and its Season 1 episodes.
- `IMAGE-UPLOAD-AUTOMATION.md` - Instructions for the Supabase image upload automation workflow.
