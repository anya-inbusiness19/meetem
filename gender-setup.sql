-- MeetEm' gender + "Show me" setting for matches.
-- Run once in Supabase: SQL Editor -> New query -> paste everything -> Run. Safe to run again.

alter table public.profiles
  add column if not exists gender text,
  add column if not exists show_me text not null default 'Both';

do $$ begin
  alter table public.profiles add constraint profiles_gender_values check (gender is null or gender in ('Female', 'Male'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.profiles add constraint profiles_show_me_values check (show_me in ('Women', 'Men', 'Both'));
exception when duplicate_object then null; end $$;

-- Gender for a list of students (used to filter matches).
-- Signed-in students only; skips anyone blocked either way and anyone hidden from suggestions.
create or replace function public.match_genders(ids uuid[]) returns table (id uuid, gender text)
language sql stable security definer set search_path = public as $$
  select p.id, p.gender
  from public.profiles p
  where auth.uid() is not null
    and p.id = any(ids)
    and p.discoverable is not false
    and not exists (select 1 from public.user_blocks b
                    where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                       or (b.blocker_id = p.id and b.blocked_id = auth.uid()));
$$;

revoke all on function public.match_genders(uuid[]) from public, anon;
grant execute on function public.match_genders(uuid[]) to authenticated;

notify pgrst, 'reload schema';
