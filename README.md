# Utang Tracker

A mobile-first web app for sari-sari store owners to track customer utang (informal credit), replacing the paper libreta.

This is **stage 2**: dashboard, customer data model, Add utang, Add payment, and receipts. Later stages (edit/delete with history, customer settings, monthly report) will build on top of this.

## Tech

Single static `index.html` (vanilla JS + the Supabase JS client via CDN), a Supabase Postgres backend, no build step — same approach as the Ching Massage booking app.

## Setup

1. Create a new project at [supabase.com](https://supabase.com).
2. Open the SQL editor and run `schema.sql` in this folder. It creates the `customers`, `utang_entries`, and `payments` tables with open (anon) read/write policies — fine while building, but lock these down (see the comment at the top of `schema.sql`) before real customer data goes in.
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

Settings, editing/deleting entries (with history), and the monthly report are the next stages.
