begin;

create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(19);

select has_table('public', 'garments', 'garments exists');
select has_column('public', 'garments', 'materials', 'garments has multi-value materials');
select has_column('public', 'garments', 'styles', 'garments has multi-value styles');
select col_type_is('public', 'garments', 'materials', 'text[]', 'materials is a text array');
select col_type_is('public', 'garments', 'styles', 'text[]', 'styles is a text array');
select is(
  (select count(*) from storage.buckets where id = 'garment-images'),
  1::bigint,
  'garment-images bucket exists'
);
select is(
  (
    select (public = false and file_size_limit = 5 * 1024 * 1024
      and allowed_mime_types = array['image/jpeg']::text[])
    from storage.buckets
    where id = 'garment-images'
  ),
  true,
  'garment-images is private and accepts JPEG files up to 5 MB'
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
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'authenticated',
    'authenticated',
    'garment-user-a@example.com',
    crypt('password-a', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'authenticated',
    'authenticated',
    'garment-user-b@example.com',
    crypt('password-b', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

select set_config(
  'test.user_a_wardrobe',
  (select id::text from public.wardrobes
    where owner_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and is_default),
  false
);
select set_config(
  'test.user_b_wardrobe',
  (select id::text from public.wardrobes
    where owner_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' and is_default),
  false
);

insert into public.garments
  (id, user_id, wardrobe_id, image_path, name, category, seasons)
values (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  current_setting('test.user_b_wardrobe')::uuid,
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/bbbbbbbb-0000-0000-0000-000000000001/original.jpg',
  '黑色外套',
  'outerwear',
  array['winter']
);

insert into storage.objects (bucket_id, name)
values (
  'garment-images',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/bbbbbbbb-0000-0000-0000-000000000001/original.jpg'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$insert into public.garments
    (id, user_id, wardrobe_id, image_path, name, category, seasons)
    values (
      'aaaaaaaa-0000-0000-0000-000000000001',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      (select id from public.wardrobes where owner_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and is_default),
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000001/original.jpg',
      '白衬衫', 'tops', array['spring'])$$,
  'owner inserts into owned wardrobe'
);

select is(
  (select count(*) from public.garments),
  1::bigint,
  'owner reads only own garments'
);

with changed as (
  update public.garments
  set name = '更新后的白衬衫'
  where id = 'aaaaaaaa-0000-0000-0000-000000000001'
  returning name
)
select is(
  (select name from changed),
  '更新后的白衬衫'::text,
  'owner updates own garment'
);

insert into public.garments
  (id, user_id, wardrobe_id, image_path, name, category, seasons)
values (
  'aaaaaaaa-0000-0000-0000-000000000002',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  current_setting('test.user_a_wardrobe')::uuid,
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000002/original.jpg',
  '待删除衬衫', 'tops', array['summer']
);

with deleted as (
  delete from public.garments
  where id = 'aaaaaaaa-0000-0000-0000-000000000002'
  returning id
)
select is(
  (select count(*) from deleted),
  1::bigint,
  'owner deletes own garment'
);

select is(
  (select count(*) from public.garments
    where id = 'bbbbbbbb-0000-0000-0000-000000000001'),
  0::bigint,
  'another user garment is invisible'
);

select throws_ok(
  $$insert into public.garments
    (id, user_id, wardrobe_id, image_path, name, category, seasons)
    values (
      'aaaaaaaa-0000-0000-0000-000000000003',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      current_setting('test.user_b_wardrobe')::uuid,
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000003/original.jpg',
      '非法衣物', 'tops', array['spring'])$$,
  '42501',
  null,
  'owner cannot insert into another user wardrobe'
);

select throws_matching(
  $$update public.garments
    set user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  '(row-level security|foreign key)',
  'owner cannot transfer a garment by changing user_id'
);

select throws_matching(
  $$update public.garments
    set wardrobe_id = current_setting('test.user_b_wardrobe')::uuid
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  '(row-level security|foreign key)',
  'owner cannot transfer a garment to another user wardrobe'
);

select lives_ok(
  $$insert into storage.objects (bucket_id, name)
    values (
      'garment-images',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000001/original.jpg'
    )$$,
  'owner creates an object inside own storage folder'
);

select is(
  (select count(*) from storage.objects
    where name like 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/%'),
  0::bigint,
  'another user storage objects are invisible'
);

select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values (
      'garment-images',
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/aaaaaaaa-0000-0000-0000-000000000004/original.jpg'
    )$$,
  '42501',
  null,
  'owner cannot create an object inside another user folder'
);

select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'garment_images_delete_own'
      and cmd = 'DELETE'
      and qual like '%garment-images%'
      and qual like '%auth.uid%'
  ),
  'storage deletion is restricted to the authenticated user folder'
);

select * from finish();
rollback;
