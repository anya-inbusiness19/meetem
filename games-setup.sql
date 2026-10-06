-- MeetEm' Games: a leaderboard for every game, and saved progress for Side Hustle Tycoon and Pet Hatch.
-- Run once in Supabase: SQL Editor -> New query -> paste everything -> Run. Safe to run again.

-- ---------- Best score per student per game ----------
create table if not exists public.game_bests (
  user_id uuid not null references auth.users(id) on delete cascade,
  game text not null check (game ~ '^[a-z0-9_-]{2,24}$'),
  best bigint not null default 0 check (best between 0 and 1000000000000000000),
  display_name text check (char_length(display_name) <= 40),
  avatar jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, game)
);
create index if not exists game_bests_board_idx on public.game_bests (game, best desc);
alter table public.game_bests enable row level security;

drop policy if exists "game bests readable" on public.game_bests;
create policy "game bests readable" on public.game_bests for select to authenticated using (true);
drop policy if exists "game bests insert own" on public.game_bests;
create policy "game bests insert own" on public.game_bests for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "game bests update own" on public.game_bests;
create policy "game bests update own" on public.game_bests for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- A best score can only go up.
create or replace function public.keep_game_best() returns trigger language plpgsql as $$
begin
  new.best := greatest(new.best, old.best);
  return new;
end $$;
drop trigger if exists keep_game_best on public.game_bests;
create trigger keep_game_best before update on public.game_bests for each row execute function public.keep_game_best();

-- Bring over Campus Dash scores from the old leaderboard, if it exists.
do $$ begin
  if to_regclass('public.game_scores') is not null then
    insert into public.game_bests (user_id, game, best, display_name, avatar, updated_at)
    select user_id, 'dash', best, display_name, avatar, updated_at from public.game_scores
    on conflict (user_id, game) do nothing;
  end if;
end $$;

-- ---------- Saved progress (only you can see your own) ----------
create table if not exists public.game_saves (
  user_id uuid not null references auth.users(id) on delete cascade,
  game text not null check (game ~ '^[a-z0-9_-]{2,24}$'),
  data jsonb not null check (pg_column_size(data) < 20000),
  updated_at timestamptz not null default now(),
  primary key (user_id, game)
);
alter table public.game_saves enable row level security;

drop policy if exists "game saves own read" on public.game_saves;
create policy "game saves own read" on public.game_saves for select to authenticated using (auth.uid() = user_id);
drop policy if exists "game saves own insert" on public.game_saves;
create policy "game saves own insert" on public.game_saves for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "game saves own update" on public.game_saves;
create policy "game saves own update" on public.game_saves for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

notify pgrst, 'reload schema';
