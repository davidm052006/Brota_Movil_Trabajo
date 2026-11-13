-- Link-based collaboration: everyone with the board URL can change only estado.
grant update (estado) on public.tablero_brota_tareas to anon;
create policy "public board update state" on public.tablero_brota_tareas for update to anon using (true) with check (true);
