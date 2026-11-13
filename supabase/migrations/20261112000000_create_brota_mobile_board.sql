-- Applied to the Brota project through Supabase MCP on 2026-11-12.
-- It records the schema contract; the task data seed was applied in the same migration.
create table if not exists public.tablero_brota_miembros (user_id uuid primary key references auth.users(id) on delete cascade, added_at timestamptz not null default now());
create table if not exists public.tablero_brota_tareas (id text primary key check (id in ('E1','E2','E3','E4','J1','J2','J3','J4','B1','B2','B3','B4','D1','D2','D3','D4')), responsable text not null, capa text not null, titulo text not null, estado text not null default 'Por hacer' check (estado in ('Por hacer','En progreso','Bloqueada','Hecha')), updated_at timestamptz not null default now(), updated_by uuid references auth.users(id) on delete set null);
insert into public.tablero_brota_miembros (user_id) select id from public.perfiles where rol = 'admin' and activo is true on conflict do nothing;
alter table public.tablero_brota_miembros enable row level security;
alter table public.tablero_brota_tareas enable row level security;
revoke all on public.tablero_brota_miembros from anon, authenticated;
revoke all on public.tablero_brota_tareas from anon, authenticated;
grant select on public.tablero_brota_miembros to authenticated;
grant select on public.tablero_brota_tareas to authenticated;
grant update (estado) on public.tablero_brota_tareas to authenticated;
drop policy if exists "tablero members read own membership" on public.tablero_brota_miembros;
create policy "tablero members read own membership" on public.tablero_brota_miembros for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "tablero members read tasks" on public.tablero_brota_tareas;
create policy "tablero members read tasks" on public.tablero_brota_tareas for select to authenticated using (exists (select 1 from public.tablero_brota_miembros m where m.user_id = (select auth.uid())));
drop policy if exists "tablero members update state" on public.tablero_brota_tareas;
create policy "tablero members update state" on public.tablero_brota_tareas for update to authenticated using (exists (select 1 from public.tablero_brota_miembros m where m.user_id = (select auth.uid()))) with check (exists (select 1 from public.tablero_brota_miembros m where m.user_id = (select auth.uid())));
create or replace function public.set_tablero_brota_task_audit() returns trigger language plpgsql set search_path = public, pg_temp as $$ begin new.updated_at := now(); new.updated_by := auth.uid(); return new; end; $$;
drop trigger if exists tablero_brota_task_audit on public.tablero_brota_tareas;
create trigger tablero_brota_task_audit before update on public.tablero_brota_tareas for each row execute function public.set_tablero_brota_task_audit();
do $$ begin if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tablero_brota_tareas') then alter publication supabase_realtime add table public.tablero_brota_tareas; end if; end $$;
