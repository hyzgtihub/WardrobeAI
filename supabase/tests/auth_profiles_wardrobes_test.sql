begin;

create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(14);

select has_table('public', 'profiles', 'profiles exists');
select has_table('public', 'wardrobes', 'wardrobes exists');
select col_is_pk('public', 'profiles', 'id', 'profiles.id is the primary key');
select policies_are(
  'public',
  'profiles',
  array['profiles_select_own', 'profiles_update_own'],
  'profiles exposes only own-row policies'
);
select policies_are(
  'public',
  'wardrobes',
  array['wardrobes_select_own'],
  'wardrobes exposes only own-row select policy'
);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'user-a@example.com',
    crypt('password-a', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'user-b@example.com',
    crypt('password-b', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

select is(
  (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000001'),
  1::bigint,
  'user A receives one profile'
);
select is(
  (select count(*) from public.wardrobes where owner_id = '00000000-0000-0000-0000-000000000001' and is_default),
  1::bigint,
  'user A receives one default wardrobe'
);
select is(
  (select name from public.wardrobes where owner_id = '00000000-0000-0000-0000-000000000001' and is_default),
  '我'::text,
  'default wardrobe is named 我'
);
select is(
  (select count(*) from public.wardrobes where is_default),
  2::bigint,
  'two users receive exactly two default wardrobes'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is((select count(*) from public.profiles), 1::bigint, 'user A sees only own profile');
select is((select count(*) from public.wardrobes), 1::bigint, 'user A sees only own wardrobe');
with changed as (
  update public.profiles
  set nickname = 'forbidden'
  where id = '00000000-0000-0000-0000-000000000002'
  returning id
)
select is(
  (select count(*) from changed),
  0::bigint,
  'user A cannot update user B profile'
);

reset role;
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

select throws_ok(
  'select count(*) from public.profiles',
  '42501',
  'permission denied for table profiles',
  'anon cannot select profiles'
);
select throws_ok(
  'select count(*) from public.wardrobes',
  '42501',
  'permission denied for table wardrobes',
  'anon cannot select wardrobes'
);

select * from finish();
rollback;
