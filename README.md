# Rent Tracker

A dashboard for landlords to see who's paid rent, who's overdue, and which units are vacant.
Built with React + Vite, backed by Supabase (Postgres + auth).

## What it does

- Log in with email/password (your own landlord account — data is private to you)
- Add properties and units with rent amounts
- Add a tenant to a vacant unit
- Record a payment (M-Pesa, cash, or bank) — status flips to "paid" for the month automatically
- Mark a unit vacant when a tenant moves out
- See totals: units, paid, overdue, vacant, and total amount owed

Payment status is never manually toggled — it's calculated from whether a payment row exists
for the tenant for the current month. This means the numbers can't drift out of sync.

## Setup

### 1. Create a Supabase project
Go to [supabase.com](https://supabase.com), create a free project, and note your project URL
and anon public key (Settings > API).

### 2. Run the schema
Open the SQL editor in your Supabase project and run everything in `schema.sql`.
This creates the four tables (`properties`, `units`, `tenants`, `payments`) and row-level security policies
so each landlord only ever sees their own data.

> If you see a Supabase error saying `Could not find the table 'public.units'`, it means your database
> is missing the `units` table. Run `schema.sql` from this repo exactly, not any other SQL file.

### 3. Enable email auth
In Supabase, go to Authentication > Providers and make sure Email is enabled (it is by default).
For quick testing, you can also turn off "Confirm email" under Authentication > Settings so you
can sign up and log in immediately without checking an inbox.

### 4. Configure the app
```bash
cp .env.example .env
```
Fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from step 1.

### 5. Install and run
```bash
npm install
npm run dev
```
Open the local URL it prints (usually `http://localhost:5173`).

### 7. Messaging and OpenAI summary
A new messaging workflow is included with Supabase tables for `threads`, `thread_members`, `messages`, and `thread_summaries`.

- Run `supabase_messaging_schema.sql` in your Supabase SQL editor to add these tables and policies.
- Deploy the edge function from `supabase/functions/summarizeThread` with the Supabase CLI.
- Add the secrets `SUPABASE_SERVICE_ROLE` and `OPENAI_API_KEY` in Supabase project settings.
- The client app uses `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`; the function uses the service role and OpenAI secret.

### 8. Deploy
Push this to a GitHub repo, then import it into Vercel or Netlify. Add the same Vite environment variables in the deployment platform's settings. No backend server needed — Supabase is your backend.

## Project structure
```
schema.sql                     Supabase table + security setup
src/
  supabaseClient.js            Supabase connection
  App.jsx                      Main app: data loading, actions, layout
  App.css                      Styling
  components/
    Auth.jsx                   Login/signup form
    MetricCards.jsx             Summary numbers
    Filters.jsx                All/Paid/Overdue/Vacant tabs
    UnitCard.jsx                Single unit row with status + actions
    AddUnitModal.jsx            Add a property/unit
    AddTenantModal.jsx          Add a tenant to a vacant unit
    RecordPaymentModal.jsx      Log a payment
    Modal.jsx                   Shared modal wrapper
```

## Next steps to consider

- **M-Pesa Daraja**: the app includes STK Push and a secured payment callback. Follow
  [MPESA_DARAJA_SETUP.md](MPESA_DARAJA_SETUP.md) to configure sandbox credentials, deploy both
  Supabase Edge Functions, and test with a Daraja sandbox account.
- **Reminders**: a scheduled job (Supabase Edge Function + cron) that checks for unpaid tenants
  a few days before month-end and sends a WhatsApp or SMS reminder (e.g. via Africa's Talking).
- **Multi-user/staff access**: if you ever manage properties with a caretaker, you'd add a
  `property_managers` table and adjust the RLS policies to include manager access, not just owner.
