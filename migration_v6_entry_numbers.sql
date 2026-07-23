-- Utang Tracker — v6: per-customer entry numbers + payment-history accuracy
--
-- Adds a permanent, per-customer entry number (Entry #1, #2, #3...) using
-- the same atomic-counter pattern as the per-account receipt counter from
-- v5, plus a flag on each payment row recording whether that specific
-- payment fully cleared the entry it was applied to. That flag is needed
-- so payment history can permanently and correctly say "paid in full" vs
-- "paid partial" for each entry touched -- recomputing that after the fact
-- from an entry's current (possibly since-changed) remaining balance
-- wouldn't be reliable if an entry received more than one payment over time.

create table entry_counters (
  customer_id uuid primary key references customers(id) on delete cascade,
  next_number integer not null default 1
);

alter table entry_counters enable row level security;

create policy "Owner can read own entry counters" on entry_counters
  for select using (
    exists (select 1 from customers c where c.id = entry_counters.customer_id and c.owner_id = auth.uid())
  );

-- Only this function (running as its definer) is allowed to touch the
-- table -- same tamper-proofing pattern as next_receipt_number(), plus an
-- explicit ownership check since this one takes a customer_id argument.
create or replace function next_entry_number(p_customer_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  result integer;
begin
  if not exists (select 1 from customers where id = p_customer_id and owner_id = auth.uid()) then
    raise exception 'not authorized for this customer';
  end if;

  insert into entry_counters (customer_id, next_number)
  values (p_customer_id, 1)
  on conflict (customer_id) do nothing;

  update entry_counters
  set next_number = next_number + 1
  where customer_id = p_customer_id
  returning next_number - 1 into result;

  return result;
end;
$$;

grant execute on function next_entry_number(uuid) to authenticated;

-- Nullable, no backfill -- same reasoning as receipt_number in v5: only
-- new rows created from here on need it.
alter table utang_entries add column if not exists entry_number integer;
alter table payments add column if not exists is_full_payment boolean;
