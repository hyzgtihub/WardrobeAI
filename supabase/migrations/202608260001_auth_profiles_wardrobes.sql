create extension if not exists pgcrypto with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null default '衣序用户'
    constraint profiles_nickname_length check (char_length(btrim(nickname)) between 1 and 30),
  avatar_path text,
  language_code text not null default 'zh-Hans',
  notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wardrobes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default '我',
  is_default boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index wardrobes_one_default_per_owner
on public.wardrobes(owner_id)
where is_default = true;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger wardrobes_set_updated_at
before update on public.wardrobes
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;

  insert into public.wardrobes (owner_id, name, is_default)
  values (new.id, '我', true)
  on conflict (owner_id) where is_default = true do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;

alter table public.profiles enable row level security;
alter table public.wardrobes enable row level security;

create policy profiles_select_own
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

create policy profiles_update_own
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy wardrobes_select_own
on public.wardrobes
for select
to authenticated
using ((select auth.uid()) = owner_id);

revoke all on public.profiles from anon;
revoke all on public.wardrobes from anon;
grant select, update on public.profiles to authenticated;
grant select on public.wardrobes to authenticated;
