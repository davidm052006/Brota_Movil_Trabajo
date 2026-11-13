-- Public read-only board. Update privileges remain restricted to authenticated members.
grant select on public.tablero_brota_tareas to anon;
create policy "public board read" on public.tablero_brota_tareas for select to anon using (true);
