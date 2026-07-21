-- Utang Tracker — v4: isolate data per store owner account
-- Run this AFTER migration_v3_lockdown_rls.sql.
--
-- Right now every logged-in account sees the SAME customers/utang/payments —
-- there's no column tying rows to a specific store owner. This adds one,
-- and rewrites the policies so each account only ever sees its own data.
--
-- IMPORTANT: this assumes your current data is just test data. If you have
-- real customers you want to keep, tell Claude Code which account should
-- own them BEFORE running this, so it can backfill instead of wiping.
-- Otherwise, this clears existing rows since there's no safe way to guess
-- which test account should own old test data.

truncate table payments, utang_entries, customers;

alter table customers
  add column owner_id uuid not null references auth.users(id) default auth.uid();

drop policy if exists "Staff can read" on customers;
drop policy if exists "Staff can insert" on customers;
drop policy if exists "Staff can update" on customers;

create policy "Owner can read own customers" on customers
  for select using (owner_id = auth.uid());
create policy "Owner can insert own customers" on customers
  for insert with check (owner_id = auth.uid());
create policy "Owner can update own customers" on customers
  for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "Staff can read" on utang_entries;
drop policy if exists "Staff can insert" on utang_entries;
drop policy if exists "Staff can update" on utang_entries;
drop policy if exists "Staff can delete" on utang_entries;

create policy "Owner can read own entries" on utang_entries
  for select using (
    exists (select 1 from customers c where c.id = utang_entries.customer_id and c.owner_id = auth.uid())
  );
create policy "Owner can insert own entries" on utang_entries
  for insert with check (
    exists (select 1 from customers c where c.id = utang_entries.customer_id and c.owner_id = auth.uid())
  );
create policy "Owner can update own entries" on utang_entries
  for update using (
    exists (select 1 from customers c where c.id = utang_entries.customer_id and c.owner_id = auth.uid())
  ) with check (
    exists (select 1 from customers c where c.id = utang_entries.customer_id and c.owner_id = auth.uid())
  );
create policy "Owner can delete own entries" on utang_entries
  for delete using (
    exists (select 1 from customers c where c.id = utang_entries.customer_id and c.owner_id = auth.uid())
  );

drop policy if exists "Staff can read" on payments;
drop policy if exists "Staff can insert" on payments;
drop policy if exists "Staff can update" on payments;

create policy "Owner can read own payments" on payments
  for select using (
    exists (select 1 from customers c where c.id = payments.customer_id and c.owner_id = auth.uid())
  );
create policy "Owner can insert own payments" on payments
  for insert with check (
    exists (select 1 from customers c where c.id = payments.customer_id and c.owner_id = auth.uid())
  );
create policy "Owner can update own payments" on payments
  for update using (
    exists (select 1 from customers c where c.id = payments.customer_id and c.owner_id = auth.uid())
  ) with check (
    exists (select 1 from customers c where c.id = payments.customer_id and c.owner_id = auth.uid())
  );
