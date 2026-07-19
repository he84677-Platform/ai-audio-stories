insert into public.stories (
  slug,
  title,
  short_description,
  description,
  content_status,
  published_at
)
values (
  'the-lighthouse-at-dusk',
  'The Lighthouse at Dusk',
  'A quiet mystery begins on a windswept coast.',
  'A short audio story about memory, weather, and an unexpected visitor.',
  'published',
  now()
)
on conflict (slug) do nothing;