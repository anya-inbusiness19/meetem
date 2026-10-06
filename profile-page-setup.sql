-- MeetEm' profile pages: "About me" description, custom banner, and viewing other students' profiles.
-- Run once in Supabase: SQL Editor -> New query -> paste everything -> Run. Safe to run again.

alter table public.profiles
  add column if not exists bio text,
  add column if not exists banner_style text,
  add column if not exists banner_path text;

do $$ begin
  alter table public.profiles add constraint profiles_bio_length check (char_length(bio) <= 300);
exception when duplicate_object then null; end $$;

-- What a student sees on someone else's profile page.
-- Never includes email, phone number, ZIP code or how they get around.
-- Returns nothing if either student blocked the other.
create or replace function public.public_profile(target uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  p public.profiles%rowtype;
  is_verified boolean;
begin
  if auth.uid() is null then return null; end if;
  if exists (select 1 from public.user_blocks b
             where (b.blocker_id = auth.uid() and b.blocked_id = target)
                or (b.blocker_id = target and b.blocked_id = auth.uid())) then
    return null;
  end if;
  select * into p from public.profiles where id = target;
  if not found then return null; end if;
  select (u.email_confirmed_at is not null and u.email ilike '%.edu') into is_verified from auth.users u where u.id = target;

  -- Students who turned off "Suggest me to other students" only show their name and avatar.
  if p.discoverable is false and target <> auth.uid() then
    return jsonb_build_object('id', p.id, 'first_name', p.first_name, 'last_initial', p.last_initial,
                              'avatar', p.avatar, 'banner_style', p.banner_style, 'private', true);
  end if;

  return jsonb_build_object(
    'id', p.id, 'first_name', p.first_name, 'last_initial', p.last_initial,
    'age', p.age, 'college', p.college, 'major', p.major, 'year', p.year, 'school_level', p.school_level,
    'meet_city', p.meet_city, 'meet_state', p.meet_state,
    'activities', p.activities, 'goals', p.goals, 'social_level', p.social_level, 'free_times', p.free_times,
    'talents', p.talents, 'looking_for', p.looking_for, 'meetup_places', p.meetup_places,
    'likes', p.likes, 'dislikes', p.dislikes, 'fun_fact', p.fun_fact, 'bio', p.bio,
    'photo_path', p.photo_path, 'gallery_paths', p.gallery_paths, 'video_path', p.video_path, 'music', p.music,
    'avatar', p.avatar, 'banner_style', p.banner_style, 'banner_path', p.banner_path,
    'verified', coalesce(is_verified, false));
end $$;

revoke all on function public.public_profile(uuid) from public, anon;
grant execute on function public.public_profile(uuid) to authenticated;

notify pgrst, 'reload schema';
