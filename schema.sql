-- Utang Tracker — fresh-install schema (v1: dashboard + customer data model)
-- Run this once in a new Supabase project's SQL editor.

create extension if not exists pgcrypto;

drop table if exists payments;
drop table if exists utang_entries;
drop table if exists customers;

create table customers (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  contact text,
  credit_limit numeric,
  payment_term text check (payment_term in ('Payday', 'Weekly', 'No fixed date', 'Custom per entry')),
  store_credit_balance numeric not null default 0,
  archived boolean not null default false
);

create table utang_entries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  customer_id uuid not null references customers(id) on delete cascade,
  items jsonb not null default '[]',
  total_amount numeric not null,
  due_date date,
  amount_remaining numeric not null,
  edited_history jsonb not null default '[]'
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  customer_id uuid not null references customers(id) on delete cascade,
  utang_entry_id uuid references utang_entries(id) on delete set null,
  amount numeric not null,
  date date not null default current_date,
  overpayment_amount numeric,
  overpayment_action text check (overpayment_action in ('change_given', 'store_credit'))
);

create index customers_archived_idx on customers (archived);
create index utang_entries_customer_idx on utang_entries (customer_id);
create index utang_entries_due_date_idx on utang_entries (due_date);
create index payments_customer_idx on payments (customer_id);

-- No staff login built yet (that's a later stage), so the anon/publishable
-- key needs direct read/write access for now. Open to anyone with the URL +
-- key — fine while this is just being built out, but lock this down with
-- "must be logged in" policies (same pattern as the Ching Spa app's
-- migration_v4_auth.sql) before any real customer data goes in.
alter table customers enable row level security;
alter table utang_entries enable row level security;
alter table payments enable row level security;

create policy "Allow anon read" on customers for select using (true);
create policy "Allow anon insert" on customers for insert with check (true);
create policy "Allow anon update" on customers for update using (true) with check (true);

create policy "Allow anon read" on utang_entries for select using (true);
create policy "Allow anon insert" on utang_entries for insert with check (true);
create policy "Allow anon update" on utang_entries for update using (true) with check (true);

create policy "Allow anon read" on payments for select using (true);
create policy "Allow anon insert" on payments for insert with check (true);
create policy "Allow anon update" on payments for update using (true) with check (true);

alter publication supabase_realtime add table customers;
alter publication supabase_realtime add table utang_entries;
alter publication supabase_realtime add table payments;
