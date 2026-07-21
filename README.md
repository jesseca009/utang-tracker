# Utang Tracker

A mobile-first web app for sari-sari store owners to track customer utang (informal credit), replacing the paper libreta.

This is **stage 3**: dashboard, customer data model, Add utang, Add payment, receipts, customer detail, edit/delete with history, customer settings, and the monthly report.

## Tech

Single static `index.html` (vanilla JS + the Supabase JS client via CDN), a Supabase Postgres backend, no build step — same approach as the Ching Massage booking app.

## Setup

1. Create a new project at [supabase.com](https://supabase.com).
2. Open the SQL editor and run `schema.sql` in this folder. It creates the `customers`, `utang_entries`, and `payments` tables with open (anon) read/write policies — fine while building, but lock these down (see the comment at the top of `schema.sql`) before real customer data goes in. If you already ran `schema.sql` before this stage, run `migration_v2_overdue_behavior.sql` instead of starting over — it adds the new "if overdue" customer setting and an entry-delete policy without touching existing data.
3. In your Supabase project, go to **Project Settings → API** and copy the **Project URL** and **anon public key**.
4. Open `index.html` and fill in the two constants near the top of the `<script>` block:
   ```js
   const SUPABASE_URL = 'YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
   ```
5. Open `index.html` in a browser (or deploy the folder to GitHub Pages / any static host).

## What works right now

- Dashboard: total utang, customer list colored by status (red = overdue, yellow = has active utang, green = paid/no utang), search, sort (Most owed / Most overdue / Alphabetical), Archived tab.
- "+ New customer" (name only — everything else can be set later).
- **Add utang**: pick an existing customer or type a new name, itemized entry, optional due date, live "This entry" / "New total utang" totals. Warns (but doesn't block) if the customer already has an overdue entry. Blocks over the credit limit unless you tap "Add anyway". Store credit from a past overpayment is auto-applied and shown as a line item.
- **Add payment**: pick a customer, enter an amount — it's applied FIFO to their oldest unpaid entry first. If the amount is more than what's owed, you must choose "gave change back" or "keep as store credit" before saving.
- **Receipts**: after saving either flow, a receipt (store name, itemized/payment details, totals, colored status banners) renders on screen and downloads as a PNG via "Save receipt" — no external image library involved.
- **Customer detail** (tap any customer card): header colored by their worst status, quick Add utang/Add payment (pre-filled for that customer), every utang entry listed separately with its own status pill, and a payment history timeline. "Send summary" and "Reminder" are shown but intentionally disabled — reserved for a future stage.
- **Edit / delete an utang entry**: edit items or due date anytime; if the total changes, a permanent "Originally ₱X · added [date]" note appears and never disappears, even after further edits. Delete requires confirming the exact items being removed (not a generic "are you sure?").
- **Customer settings**: payment term, credit limit, and "if overdue" behavior — "Warn me, let me decide" (today's default) or "Block new utang until they pay," which turns the overdue warning in Add utang into a hard block.
- **Monthly report** (top-bar icon): total utang given this month, total collected this month, and the net change — computed from what's already loaded, no extra queries.

Signup/PIN login, receipts sent via Messenger, and CSV export remain out of scope per the spec.
