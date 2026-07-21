-- Utang Tracker — v2: customer settings' "if overdue" behavior + entry delete
-- Run this if you already ran the original schema.sql (stage 1/2). Safe to
-- re-run; skips anything already in place.

alter table customers
  add column if not exists overdue_behavior text not null default 'warn'
    check (overdue_behavior in ('warn', 'block'));

-- The original schema.sql didn't include a delete policy for utang_entries,
-- so deleting an entry (stage 3's edit/delete screen) would otherwise be
-- silently blocked by RLS.
drop policy if exists "Allow anon delete" on utang_entries;
create policy "Allow anon delete" on utang_entries for delete using (true);
