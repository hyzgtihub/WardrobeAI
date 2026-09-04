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
drop column style,
add constraint garments_materials_no_blank check (array_position(materials, '') is null),
add constraint garments_styles_no_blank check (array_position(styles, '') is null);
