-- Allow visitors to read published stories.
create policy "Anyone can read published stories"
on public.stories
for select
to anon, authenticated
using (content_status = 'published');