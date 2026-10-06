-- MeetEm' locations: meetup city/state + ZIP on profiles, and city/state on events.
-- Run once in Supabase: SQL Editor -> New query -> paste everything -> Run. Safe to run again.

alter table public.profiles
  add column if not exists zip text,
  add column if not exists meet_city text,
  add column if not exists meet_state text;

alter table public.events
  add column if not exists city text,
  add column if not exists state text;

do $$ begin
  alter table public.profiles add constraint profiles_zip_format check (zip is null or zip ~ '^\d{5}$');
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.profiles add constraint profiles_meet_city_length check (char_length(meet_city) <= 60);
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.events add constraint events_city_length check (char_length(city) <= 60);
exception when duplicate_object then null; end $$;

-- Makes "events near me" filtering fast.
create index if not exists events_state_city_idx on public.events (state, lower(city));

-- Tell Supabase to pick up the new columns right away (clears the "schema cache" error).
notify pgrst, 'reload schema';

-- Online events: no city/state needed, they show up in every location filter.
alter table public.events
  add column if not exists is_remote boolean not null default false;

notify pgrst, 'reload schema';
