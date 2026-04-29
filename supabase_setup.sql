-- Valenfoco - Setup de galeria administrable
-- Ejecuta este script en Supabase SQL Editor

-- 1) Tabla de fotos
create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('Eventos', 'Retrato', 'Producto')),
  public_url text not null,
  sort_order integer not null default 1,
  is_active boolean not null default true,
  owner_email text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists photos_category_sort_idx
  on public.photos (category, sort_order);

create index if not exists photos_active_idx
  on public.photos (is_active);

alter table public.photos enable row level security;

-- 2) Lectura publica del portfolio (solo activas)
drop policy if exists "photos_public_read_active" on public.photos;
create policy "photos_public_read_active"
on public.photos
for select
to anon, authenticated
using (is_active = true);

-- 3) Solo Valentina puede insertar
drop policy if exists "photos_admin_insert_only_valentina" on public.photos;
create policy "photos_admin_insert_only_valentina"
on public.photos
for insert
to authenticated
with check (
  lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
);

-- 4) Solo Valentina puede actualizar
drop policy if exists "photos_admin_update_only_valentina" on public.photos;
create policy "photos_admin_update_only_valentina"
on public.photos
for update
to authenticated
using (
  lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
)
with check (
  lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
);

-- 5) Solo Valentina puede eliminar
drop policy if exists "photos_admin_delete_only_valentina" on public.photos;
create policy "photos_admin_delete_only_valentina"
on public.photos
for delete
to authenticated
using (
  lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
);

-- 6) Trigger para autocompletar owner_email
create or replace function public.set_owner_email_on_photo()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.owner_email is null or new.owner_email = '' then
    new.owner_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  else
    new.owner_email := lower(new.owner_email);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_owner_email_on_photo on public.photos;
create trigger trg_set_owner_email_on_photo
before insert or update on public.photos
for each row execute function public.set_owner_email_on_photo();

-- 7) Policies para Storage (bucket: portfolio)
-- Asegurate de crear el bucket "portfolio" en Storage y dejarlo Public.

alter table storage.objects enable row level security;

drop policy if exists "storage_public_read_portfolio" on storage.objects;
create policy "storage_public_read_portfolio"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'portfolio');

drop policy if exists "storage_admin_insert_portfolio_valentina" on storage.objects;
create policy "storage_admin_insert_portfolio_valentina"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'portfolio'
  and lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
);

drop policy if exists "storage_admin_update_portfolio_valentina" on storage.objects;
create policy "storage_admin_update_portfolio_valentina"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'portfolio'
  and lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
)
with check (
  bucket_id = 'portfolio'
  and lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
);

drop policy if exists "storage_admin_delete_portfolio_valentina" on storage.objects;
create policy "storage_admin_delete_portfolio_valentina"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'portfolio'
  and lower(auth.jwt() ->> 'email') = 'valeenfoco@gmail.com'
);
