-- =============================================================
-- ManteniPro v2.0 – Ferretería Quilvio
-- Base de datos en la nube (Supabase). Ejecutar UNA vez en:
-- Supabase > SQL Editor > New query > pegar todo > Run
-- =============================================================
create table if not exists public.manteni (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb       not null,
  version    integer     not null default 1,
  updated_at timestamptz not null default now()
);

-- Seguridad: cada cuenta solo puede ver y cambiar SUS datos
alter table public.manteni enable row level security;

drop policy if exists "dueno_select" on public.manteni;
drop policy if exists "dueno_insert" on public.manteni;
drop policy if exists "dueno_update" on public.manteni;
drop policy if exists "dueno_delete" on public.manteni;

create policy "dueno_select" on public.manteni for select to authenticated using (auth.uid() = user_id);
create policy "dueno_insert" on public.manteni for insert to authenticated with check (auth.uid() = user_id);
create policy "dueno_update" on public.manteni for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dueno_delete" on public.manteni for delete to authenticated using (auth.uid() = user_id);

grant select, insert, update, delete on public.manteni to authenticated;
revoke all on public.manteni from anon;

-- =============================================================
-- v2.1 – Tablas de EQUIPOS y ÓRDENES DE TRABAJO en la nube
-- (una fila por equipo y una fila por orden; se llenan solas
--  desde ManteniPro). Se puede ejecutar este archivo completo
--  otra vez sin perder datos.
-- =============================================================
create table if not exists public.equipos (
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id          text not null,
  codigo      text,
  nombre      text,
  tipo        text,
  ubicacion   text,
  marca       text,
  serie       text,
  prioridad   integer,
  status      text,     -- Bajo / Medio / Alto
  estado      text,     -- Operativo / En mantenimiento / Fuera de servicio
  actualizado timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.ordenes (
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id            text not null,
  num           text,     -- F1001 ...
  equipo_id     text,
  equipo_codigo text,
  equipo_nombre text,
  tipo          text,     -- PM / CM
  descripcion   text,
  crew          text,
  plan_id       text,
  inicio        date,
  fin           date,     -- fecha límite
  estado        text,     -- Abierta / Completada
  tecnico       text,
  cierre        date,     -- fecha realizada
  horas         numeric,
  resultado     text,
  repuestos     text,
  costo         numeric,
  notas         text,
  checklist     text,
  actualizado   timestamptz not null default now(),
  primary key (user_id, id)
);
create index if not exists ordenes_fin_idx on public.ordenes(user_id, fin);
create index if not exists ordenes_equipo_idx on public.ordenes(user_id, equipo_id);

alter table public.equipos enable row level security;
alter table public.ordenes enable row level security;

drop policy if exists "eq_dueno" on public.equipos;
drop policy if exists "ot_dueno" on public.ordenes;
create policy "eq_dueno" on public.equipos for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "ot_dueno" on public.ordenes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update, delete on public.equipos, public.ordenes to authenticated;
revoke all on public.equipos, public.ordenes from anon;
