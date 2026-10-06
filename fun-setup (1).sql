-- MeetEm' Fun tab setup: avatars, Campus Dash leaderboard, weekly Talent Show.
-- Run this once in Supabase: SQL Editor -> New query -> paste everything -> Run.
-- Safe to run again. Voice rooms (Hangouts) need no tables; they use Supabase Realtime.

-- ---------- Avatars ----------
alter table public.profiles add column if not exists avatar jsonb;

-- ---------- Campus Dash leaderboard ----------
create table if not exists public.game_scores (
  user_id uuid primary key references auth.users(id) on delete cascade,
  best integer not null default 0 check (best between 0 and 500000),
  display_name text check (char_length(display_name) <= 40),
  avatar jsonb,
  updated_at timestamptz not null default now()
);
alter table public.game_scores enable row level security;

drop policy if exists "game scores readable" on public.game_scores;
create policy "game scores readable" on public.game_scores for select to authenticated using (true);
drop policy if exists "game scores insert own" on public.game_scores;
create policy "game scores insert own" on public.game_scores for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "game scores update own" on public.game_scores;
create policy "game scores update own" on public.game_scores for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- A best score can only go up.
create or replace function public.keep_best_score() returns trigger language plpgsql as $$
begin
  new.best := greatest(new.best, old.best);
  return new;
end $$;
drop trigger if exists keep_best_score on public.game_scores;
create trigger keep_best_score before update on public.game_scores for each row execute function public.keep_best_score();

-- ---------- Talent Show ----------
-- Shows run Monday to Sunday, Central time (Huntsville).
create or replace function public.talent_week() returns text language sql stable as $$
  select to_char(date_trunc('week', now() at time zone 'America/Chicago'), 'YYYY-MM-DD')
$$;

create table if not exists public.talent_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  week text not null default public.talent_week(),
  title text not null check (char_length(title) between 2 and 60),
  talent text check (char_length(talent) <= 40),
  video_path text not null check (char_length(video_path) <= 200),
  display_name text check (char_length(display_name) <= 40),
  avatar jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, week)
);

-- Entries always go into the current week, posted as the signed-in student.
create or replace function public.talent_entry_defaults() returns trigger language plpgsql as $$
begin
  new.week := public.talent_week();
  new.user_id := auth.uid();
  return new;
end $$;
drop trigger if exists talent_entry_defaults on public.talent_entries;
create trigger talent_entry_defaults before insert on public.talent_entries for each row execute function public.talent_entry_defaults();

alter table public.talent_entries enable row level security;
drop policy if exists "talent entries readable" on public.talent_entries;
create policy "talent entries readable" on public.talent_entries for select to authenticated using (true);
drop policy if exists "talent entries insert own" on public.talent_entries;
create policy "talent entries insert own" on public.talent_entries for insert to authenticated
  with check (auth.uid() = user_id and video_path like auth.uid()::text || '/%');
drop policy if exists "talent entries delete own" on public.talent_entries;
create policy "talent entries delete own" on public.talent_entries for delete to authenticated using (auth.uid() = user_id);

-- One vote per student per week. Votes are private: only the functions below touch this table.
create table if not exists public.talent_votes (
  voter_id uuid not null references auth.users(id) on delete cascade,
  week text not null,
  entry_id uuid not null references public.talent_entries(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (voter_id, week)
);
alter table public.talent_votes enable row level security;

create or replace function public.talent_vote(entry uuid) returns void
language plpgsql security definer set search_path = public as $$
declare e public.talent_entries%rowtype;
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  select * into e from public.talent_entries where id = entry;
  if not found then raise exception 'entry not found'; end if;
  if e.week <> public.talent_week() then raise exception 'voting closed'; end if;
  if e.user_id = auth.uid() then raise exception 'you cannot vote for yourself'; end if;
  insert into public.talent_votes (voter_id, week, entry_id) values (auth.uid(), e.week, e.id)
  on conflict (voter_id, week) do update set entry_id = excluded.entry_id, created_at = now();
end $$;

create or replace function public.talent_board(wk text default null)
returns table (id uuid, user_id uuid, week text, title text, talent text, video_path text,
               display_name text, avatar jsonb, created_at timestamptz, votes bigint, my_vote boolean)
language sql stable security definer set search_path = public as $$
  select e.id, e.user_id, e.week, e.title, e.talent, e.video_path, e.display_name, e.avatar, e.created_at,
         (select count(*) from public.talent_votes v where v.entry_id = e.id) as votes,
         exists (select 1 from public.talent_votes v where v.entry_id = e.id and v.voter_id = auth.uid()) as my_vote
  from public.talent_entries e
  where e.week = coalesce(wk, public.talent_week())
  order by 10 desc, e.created_at asc
  limit 100
$$;

revoke all on function public.talent_vote(uuid) from public, anon;
revoke all on function public.talent_board(text) from public, anon;
grant execute on function public.talent_vote(uuid) to authenticated;
grant execute on function public.talent_board(text) to authenticated;
grant execute on function public.talent_week() to authenticated;

-- Reports go to you to review (Table Editor -> talent_reports).
create table if not exists public.talent_reports (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid references public.talent_entries(id) on delete cascade,
  reporter_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  reason text check (char_length(reason) <= 200),
  created_at timestamptz not null default now()
);
alter table public.talent_reports enable row level security;
drop policy if exists "talent reports insert own" on public.talent_reports;
create policy "talent reports insert own" on public.talent_reports for insert to authenticated with check (auth.uid() = reporter_id);

-- Private video storage, 50 MB per video. Only signed-in students can watch.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('talent-videos', 'talent-videos', false, 52428800, array['video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v', 'video/3gpp'])
on conflict (id) do update set file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "talent videos readable" on storage.objects;
create policy "talent videos readable" on storage.objects for select to authenticated using (bucket_id = 'talent-videos');
drop policy if exists "talent videos upload own" on storage.objects;
create policy "talent videos upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'talent-videos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "talent videos delete own" on storage.objects;
create policy "talent videos delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'talent-videos' and (storage.foldername(name))[1] = auth.uid()::text);
