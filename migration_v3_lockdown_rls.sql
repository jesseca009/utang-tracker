-- Utang Tracker — v3: require login for all database access
-- Run this AFTER you've confirmed signup + login work end-to-end in the app
-- (stage 4). Before this, anyone with the anon/publishable key could read
-- and write data directly, no login needed — fine while building, not fine
-- once real customer data is in there.
--
-- Unlike a staff-provisioned app, this one keeps public signup ENABLED in
-- Supabase Auth (the app's own signup screen is the intended way in) — this
-- migration only tightens the table policies, it does not touch Auth
-- provider settings.

drop policy if exists "Allow anon read" on customers;
drop policy if exists "Allow anon insert" on customers;
drop policy if exists "Allow anon update" on customers;

drop policy if exists "Allow anon read" on utang_entries;
drop policy if exists "Allow anon insert" on utang_entries;
drop policy if exists "Allow anon update" on utang_entries;
drop policy if exists "Allow anon delete" on utang_entries;

drop policy if exists "Allow anon read" on payments;
drop policy if exists "Allow anon insert" on payments;
drop policy if exists "Allow anon update" on payments;

create policy "Staff can read" on customers
  for select using (auth.role() = 'authenticated');
create policy "Staff can insert" on customers
  for insert with check (auth.role() = 'authenticated');
create policy "Staff can update" on customers
  for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Staff can read" on utang_entries
  for select using (auth.role() = 'authenticated');
create policy "Staff can insert" on utang_entries
  for insert with check (auth.role() = 'authenticated');
create policy "Staff can update" on utang_entries
  for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Staff can delete" on utang_entries
  for delete using (auth.role() = 'authenticated');

create policy "Staff can read" on payments
  for select using (auth.role() = 'authenticated');
create policy "Staff can insert" on payments
  for insert with check (auth.role() = 'authenticated');
create policy "Staff can update" on payments
  for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
