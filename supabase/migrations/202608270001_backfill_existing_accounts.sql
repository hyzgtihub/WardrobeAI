insert into public.profiles (id)
select users.id
from auth.users as users
on conflict (id) do nothing;

insert into public.wardrobes (owner_id, name, is_default)
select users.id, '我', true
from auth.users as users
where not exists (
  select 1
  from public.wardrobes
  where wardrobes.owner_id = users.id
    and wardrobes.is_default = true
)
on conflict (owner_id) where is_default = true do nothing;
