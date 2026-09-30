# M-Pesa Daraja setup

The app already has an STK Push button in **Record Payment**. It sends the prompt from a Supabase Edge Function, so Safaricom keys stay on the server. Successful Daraja callbacks are matched to a tenant by Kenyan phone number and recorded as payments. Cancelled/failed STK requests are acknowledged but never recorded as payments.

This integration is set up for **Daraja sandbox by default**. A live connection cannot be activated until the project's owner configures Safaricom credentials and deploys the Supabase functions.

## 1. Create Daraja sandbox credentials

1. Sign in at <https://developer.safaricom.co.ke/> and create/use a Daraja app with the **Lipa Na M-Pesa Online** product enabled.
2. Copy the sandbox Consumer Key and Consumer Secret. Keep them private.
3. Use the sandbox Lipa Na M-Pesa Online shortcode and passkey provided for the sandbox.

## 2. Prepare Supabase

1. In the Supabase SQL Editor, run `fix_supabase_schema.sql` if the app tables are not already present.
2. Add the Daraja callback URL token and receipt uniqueness index. `schema.sql` and `fix_supabase_schema.sql` create the index for new setups. For an existing database, first inspect for duplicate non-null receipts; resolve any duplicates, then run:

```sql
create unique index if not exists payments_mpesa_receipt_unique
  on public.payments (mpesa_receipt)
  where mpesa_receipt is not null;
```

3. Install/use the Supabase CLI and link it to this project's Supabase project from the app folder if it is not linked already:

```powershell
cd "C:\xampp\htdocs\landlord rent tracker app"
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
```

The project ref is in Supabase **Settings → General**. Do not put secret keys in the Vite `.env` file.

## 3. Set Edge Function secrets

Generate a long random callback token (at least 32 random characters). Configure the following secrets using the Supabase Dashboard under **Edge Functions → Secrets**, or the CLI. Do not paste them into chat or commit them:

- `DARAJA_CONSUMER_KEY` — Daraja sandbox consumer key
- `DARAJA_CONSUMER_SECRET` — Daraja sandbox consumer secret
- `DARAJA_SHORTCODE` — sandbox Lipa Na M-Pesa Online shortcode
- `DARAJA_PASSKEY` — sandbox Lipa Na M-Pesa Online passkey
- `DARAJA_CALLBACK_SECRET` — your generated random token
- `DARAJA_ENV` — `sandbox`
- `APP_ORIGIN` — `http://localhost:5173` for local development; use the exact deployed app origin in production
- `SUPABASE_URL` — this Supabase project's URL
- `SUPABASE_SERVICE_ROLE_KEY` — Supabase secret service-role key (needed only by the callback function)

Deploy `darajaCallback` first. The callback URL is the deployed function URL with the secret token in its query string:

`https://YOUR_PROJECT_REF.supabase.co/functions/v1/darajaCallback?token=YOUR_RANDOM_CALLBACK_TOKEN`

Set that complete URL as the `DARAJA_CALLBACK_URL` Edge Function secret. Safaricom callbacks do not send custom headers, so the callback token must be included in the URL. Treat the URL as a credential and rotate the token if exposed.

## 4. Deploy functions

From the app folder, deploy both functions:

```powershell
npx supabase functions deploy darajaCallback
npx supabase functions deploy initiateStkPush
```

The Supabase config keeps JWT verification enabled for `initiateStkPush` (the signed-in app calls it) and disables JWT verification only for `darajaCallback` (Safaricom calls it). The callback separately verifies the secret URL token.

## 5. Test a sandbox STK Push

1. Run the app from its folder with `npm run dev`.
2. Sign in, add a tenant with a valid Kenyan mobile number (`07...`, `01...`, or `254...`), and open **Record Payment**.
3. Select **mpesa**, enter a positive whole-number KES amount, and send the prompt.
4. Approve it using a Daraja sandbox test phone/account. The UI confirms the STK request was accepted; the payment is recorded only after a successful callback.
5. Check the `payments` table and Supabase Edge Function logs. A repeated receipt is acknowledged without inserting a duplicate.

A local XAMPP/Vite server is not a public callback host. Safaricom must be able to reach the deployed HTTPS Supabase function URL. No callback tunnel is needed when using the hosted function.

## Go live

Do not set `DARAJA_ENV=production` until Safaricom has approved the live shortcode/product and issued production credentials. Replace the sandbox credentials and passkey with production values, set `DARAJA_ENV=production`, and verify the callback URL and app origin. Test with a low-value transaction and reconcile callbacks against Daraja before relying on this for rent accounting.

## Troubleshooting

- **Daraja credentials not configured / OAuth failure:** verify all shortcode, passkey, consumer key, and secret values and that `DARAJA_ENV` matches them.
- **Origin not allowed:** set `APP_ORIGIN` to the exact browser origin, including scheme and port.
- **Callback returns unauthorized:** compare the `token` in `DARAJA_CALLBACK_URL` with `DARAJA_CALLBACK_SECRET`.
- **No tenant matched phone:** store the tenant phone in a Kenyan format with its complete subscriber number.
- **Multiple tenants matched:** correct duplicate tenant phone records; the callback deliberately refuses ambiguous matches.
- **Duplicate index creation fails:** inspect and resolve existing duplicate non-null `mpesa_receipt` values before retrying.
