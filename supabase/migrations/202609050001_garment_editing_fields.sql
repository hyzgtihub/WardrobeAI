alter table public.garments
add column materials text[] not null default '{}',
add column styles text[] not null default '{}';

update public.garments
set
  materials = case
    when material is null or btrim(material) = '' then '{}'
    else array[btrim(material)]
  end,
  styles = case
    when style is null or btrim(style) = '' then '{}'
    else array[btrim(style)]
  end;

alter table public.garments
drop column material,
drop column style;

create function public.garment_tags_are_valid(values_to_check text[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  select cardinality(values_to_check) <= 20
    and coalesce(bool_and(length(btrim(value)) between 1 and 20), true)
  from unnest(values_to_check) as value;
$$;

revoke all on function public.garment_tags_are_valid(text[]) from public;

alter table public.garments
add constraint garments_materials_valid check (public.garment_tags_are_valid(materials)),
add constraint garments_styles_valid check (public.garment_tags_are_valid(styles));
