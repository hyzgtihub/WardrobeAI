alter table public.wardrobes
add constraint wardrobes_id_owner_id_key unique (id, owner_id);

create table public.garments (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  wardrobe_id uuid not null,
  image_path text not null,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  category text not null,
  seasons text[] not null check (cardinality(seasons) > 0),
  colors text[] not null default '{}',
  brand text,
  price numeric(12,2) check (price is null or price >= 0),
  size text,
  purchase_date date,
  material text,
  style text,
  storage_location text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  foreign key (wardrobe_id, user_id)
    references public.wardrobes(id, owner_id)
    on delete cascade
);

create index garments_active_wardrobe_created_at_idx
on public.garments (wardrobe_id, created_at desc)
where deleted_at is null;

create trigger garments_set_updated_at
before update on public.garments
for each row execute function public.set_updated_at();

alter table public.garments enable row level security;

create policy garments_select_own
on public.garments
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy garments_insert_own
on public.garments
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.wardrobes
    where wardrobes.id = garments.wardrobe_id
      and wardrobes.owner_id = (select auth.uid())
  )
);

create policy garments_update_own
on public.garments
for update
to authenticated
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.wardrobes
    where wardrobes.id = garments.wardrobe_id
      and wardrobes.owner_id = (select auth.uid())
  )
);

create policy garments_delete_own
on public.garments
for delete
to authenticated
using ((select auth.uid()) = user_id);

revoke all on public.garments from anon;
grant select, insert, update, delete on public.garments to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'garment-images',
  'garment-images',
  false,
  5 * 1024 * 1024,
  array['image/jpeg']::text[]
);

create policy garment_images_select_own
on storage.objects
for select
to authenticated
using (
  bucket_id = 'garment-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy garment_images_insert_own
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'garment-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy garment_images_update_own
on storage.objects
for update
to authenticated
using (
  bucket_id = 'garment-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'garment-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy garment_images_delete_own
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'garment-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
