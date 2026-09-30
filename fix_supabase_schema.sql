create extension if not exists pgcrypto;
-- Fix Supabase schema for Landlord Rent Tracker
-- This adds the required application tables and columns if they are missing.

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  created_at timestamptz not null default now()
);

create table if not exists public.units (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references public.properties(id) on delete set null,
  unit_label text,
  rent_amount numeric,
  status text default 'vacant',
  created_at timestamptz not null default now()
);

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid references public.units(id) on delete set null,
  name text not null,
  phone text,
  lease_start date,
  lease_end date,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  amount numeric not null default 0,
  method text not null default 'cash',
  mpesa_receipt text,
  paid_for_month text,
  paid_at timestamptz not null default now()
);

-- Required for safe, idempotent Daraja callback processing.
create unique index if not exists payments_mpesa_receipt_unique
  on public.payments (mpesa_receipt)
  where mpesa_receipt is not null;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'tenants' AND column_name = 'unit_id'
  ) THEN
    ALTER TABLE public.tenants ADD COLUMN unit_id uuid REFERENCES public.units(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'tenants' AND column_name = 'lease_start'
  ) THEN
    ALTER TABLE public.tenants ADD COLUMN lease_start date;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'tenants' AND column_name = 'lease_end'
  ) THEN
    ALTER TABLE public.tenants ADD COLUMN lease_end date;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'tenants' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.tenants ADD COLUMN created_at timestamptz not null default now();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'unit_label'
  ) THEN
    ALTER TABLE public.units ADD COLUMN unit_label text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'rent_amount'
  ) THEN
    ALTER TABLE public.units ADD COLUMN rent_amount numeric;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'status'
  ) THEN
    ALTER TABLE public.units ADD COLUMN status text default 'vacant';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.units ADD COLUMN created_at timestamptz not null default now();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'payments' AND column_name = 'paid_for_month'
  ) THEN
    ALTER TABLE public.payments ADD COLUMN paid_for_month text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'payments' AND column_name = 'method'
  ) THEN
    ALTER TABLE public.payments ADD COLUMN method text not null default 'cash';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'payments' AND column_name = 'mpesa_receipt'
  ) THEN
    ALTER TABLE public.payments ADD COLUMN mpesa_receipt text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'payments' AND column_name = 'paid_at'
  ) THEN
    ALTER TABLE public.payments ADD COLUMN paid_at timestamptz not null default now();
  END IF;
END $$;

alter table public.properties enable row level security;
alter table public.units enable row level security;
alter table public.tenants enable row level security;
alter table public.payments enable row level security;

-- Drop and recreate policies so this migration can be rerun safely.
drop policy if exists "authenticated_select_properties" on public.properties;
create policy "authenticated_select_properties" on public.properties for select using (auth.role() = 'authenticated');
drop policy if exists "authenticated_insert_properties" on public.properties;
create policy "authenticated_insert_properties" on public.properties for insert with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_update_properties" on public.properties;
create policy "authenticated_update_properties" on public.properties for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_delete_properties" on public.properties;
create policy "authenticated_delete_properties" on public.properties for delete using (auth.role() = 'authenticated');

drop policy if exists "authenticated_select_units" on public.units;
create policy "authenticated_select_units" on public.units for select using (auth.role() = 'authenticated');
drop policy if exists "authenticated_insert_units" on public.units;
create policy "authenticated_insert_units" on public.units for insert with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_update_units" on public.units;
create policy "authenticated_update_units" on public.units for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_delete_units" on public.units;
create policy "authenticated_delete_units" on public.units for delete using (auth.role() = 'authenticated');

drop policy if exists "authenticated_select_tenants" on public.tenants;
create policy "authenticated_select_tenants" on public.tenants for select using (auth.role() = 'authenticated');
drop policy if exists "authenticated_insert_tenants" on public.tenants;
create policy "authenticated_insert_tenants" on public.tenants for insert with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_update_tenants" on public.tenants;
create policy "authenticated_update_tenants" on public.tenants for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_delete_tenants" on public.tenants;
create policy "authenticated_delete_tenants" on public.tenants for delete using (auth.role() = 'authenticated');

drop policy if exists "authenticated_select_payments" on public.payments;
create policy "authenticated_select_payments" on public.payments for select using (auth.role() = 'authenticated');
drop policy if exists "authenticated_insert_payments" on public.payments;
create policy "authenticated_insert_payments" on public.payments for insert with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_update_payments" on public.payments;
create policy "authenticated_update_payments" on public.payments for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated_delete_payments" on public.payments;
create policy "authenticated_delete_payments" on public.payments for delete using (auth.role() = 'authenticated');

grant select, insert, update, delete on public.properties to authenticated;
grant select, insert, update, delete on public.units to authenticated;
grant select, insert, update, delete on public.tenants to authenticated;
grant select, insert, update, delete on public.payments to authenticated;
