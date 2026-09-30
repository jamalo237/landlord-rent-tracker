-- Supabase schema for Landlord Rent Tracker

create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  created_at timestamptz not null default now()
);

create table if not exists units (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete set null,
  unit_label text,
  rent_amount numeric,
  status text default 'vacant',
  created_at timestamptz not null default now()
);

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid references units(id) on delete set null,
  name text not null,
  phone text,
  lease_start date,
  lease_end date,
  created_at timestamptz not null default now()
);

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) on delete cascade,
  amount numeric not null default 0,
  method text not null default 'cash',
  mpesa_receipt text,
  paid_for_month text,
  paid_at timestamptz not null default now()
);

-- Daraja may retry callbacks; a receipt must never create duplicate payments.
create unique index if not exists payments_mpesa_receipt_unique
  on payments (mpesa_receipt)
  where mpesa_receipt is not null;

-- Enable Row Level Security
alter table properties enable row level security;
alter table units enable row level security;
alter table tenants enable row level security;
alter table payments enable row level security;

-- Allow authenticated users to select
create policy "authenticated_select_properties" on properties for select using (auth.role() = 'authenticated');
create policy "authenticated_select_units" on units for select using (auth.role() = 'authenticated');
create policy "authenticated_select_tenants" on tenants for select using (auth.role() = 'authenticated');
create policy "authenticated_select_payments" on payments for select using (auth.role() = 'authenticated');

-- Allow authenticated users to insert
create policy "authenticated_insert_properties" on properties for insert with check (auth.role() = 'authenticated');
create policy "authenticated_insert_units" on units for insert with check (auth.role() = 'authenticated');
create policy "authenticated_insert_tenants" on tenants for insert with check (auth.role() = 'authenticated');
create policy "authenticated_insert_payments" on payments for insert with check (auth.role() = 'authenticated');

-- Allow authenticated users to update
create policy "authenticated_update_properties" on properties for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_update_units" on units for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_update_tenants" on tenants for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_update_payments" on payments for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Allow authenticated users to delete
create policy "authenticated_delete_properties" on properties for delete using (auth.role() = 'authenticated');
create policy "authenticated_delete_units" on units for delete using (auth.role() = 'authenticated');
create policy "authenticated_delete_tenants" on tenants for delete using (auth.role() = 'authenticated');
create policy "authenticated_delete_payments" on payments for delete using (auth.role() = 'authenticated');
