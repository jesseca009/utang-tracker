-- Utang Tracker — v5: sequential receipt numbers per store account
--
-- Adds a running receipt number (#00001, #00042, ...) shared by both utang
-- and payment receipts — one counter per store account, not per customer,
-- so an utang entry and a payment both consume the next number regardless
-- of which customer they belong to.
--
-- Implemented as a dedicated counter table + an atomic RPC function, rather
-- than "count existing rows + 1", so two saves happening back-to-back can
-- never land on the same number, and a number is fixed the moment it's
-- assigned — editing or deleting an entry later never renumbers anything.

create table receipt_counters (
  owner_id uuid primary key references auth.users(id),
  next_number integer not null default 1
);

alter table receipt_counters enable row level security;

create policy "Owner can read own counter" on receipt_counters
  for select using (owner_id = auth.uid());

-- No insert/update policy on purpose — only this function (running as its
-- definer) is allowed to touch the table, so the counter can't be tampered
-- with via a direct client write.
create or replace function next_receipt_number()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  result integer;
begin
  insert into receipt_counters (owner_id, next_number)
  values (auth.uid(), 1)
  on conflict (owner_id) do nothing;

  update receipt_counters
  set next_number = next_number + 1
  where owner_id = auth.uid()
  returning next_number - 1 into result;

  return result;
end;
$$;

grant execute on function next_receipt_number() to authenticated;

-- Nullable, no backfill: receipts are only ever shown once, right after
-- saving, so rows created before this migration never need a number —
-- only new inserts from here on populate it.
alter table utang_entries add column if not exists receipt_number integer;
alter table payments add column if not exists receipt_number integer;
