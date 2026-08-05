-- Utang Tracker — v7: free tier customer limit + manual pro upgrade
--
-- Adds a `profiles` table with a plain `is_pro` boolean column (one row
-- per account, keyed by the Supabase auth user id). This is a real table
-- rather than something stuffed into auth.users' user_metadata JSON so it
-- shows up as an ordinary editable column in Supabase's Table Editor —
-- the intended workflow is manually flipping `is_pro` to true there after
-- verifying a GCash payment, with no in-app payment flow.
--
-- A trigger on auth.users creates the profile row automatically at
-- signup, defaulting new accounts to free (`is_pro = false`, capped at 7
-- customers client-side). Everyone who already has an account as of this
-- migration is grandfathered to `is_pro = true` so current testers don't
-- suddenly hit the wall on customers they've already added.

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  is_pro boolean not null default false,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "Owner can read own profile" on profiles
  for select using (id = auth.uid());

-- Runs as its definer (bypassing RLS) so it can insert a profile row for
-- a brand-new auth user before that user's own session/RLS context exists.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, is_pro) values (new.id, false);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Grandfather every account that already exists as of this migration.
insert into profiles (id, is_pro)
select id, true from auth.users
on conflict (id) do nothing;
