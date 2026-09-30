-- Messaging schema for Supabase

-- Threads container
create table if not exists public.threads (
  id uuid primary key default gen_random_uuid(),
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Thread membership
create table if not exists public.thread_members (
  thread_id uuid not null references public.threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

-- Messages inside a thread
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

-- Summaries generated from a thread
create table if not exists public.thread_summaries (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.threads(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  summary text not null,
  model text,
  message_count int not null,
  created_at timestamptz not null default now()
);

-- update thread timestamp when needed
create or replace function public.set_threads_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_threads_updated_at on public.threads;
create trigger trg_threads_updated_at
before update on public.threads
for each row
execute function public.set_threads_updated_at();

-- Enable Row Level Security
alter table public.threads enable row level security;
alter table public.thread_members enable row level security;
alter table public.messages enable row level security;
alter table public.thread_summaries enable row level security;

-- THREADS: only members can view threads
drop policy if exists threads_select_membership on public.threads;
create policy threads_select_membership
on public.threads
for select
using (
  exists (
    select 1
    from public.thread_members tm
    where tm.thread_id = threads.id
      and tm.user_id = auth.uid()
  )
);

drop policy if exists threads_insert_authenticated on public.threads;
create policy threads_insert_authenticated
on public.threads
for insert
with check (auth.role() = 'authenticated');

-- THREAD MEMBERS: allow users to manage their own membership rows
drop policy if exists thread_members_select_own on public.thread_members;
create policy thread_members_select_own
on public.thread_members
for select
using (user_id = auth.uid());

drop policy if exists thread_members_insert_own on public.thread_members;
create policy thread_members_insert_own
on public.thread_members
for insert
with check (user_id = auth.uid());

drop policy if exists thread_members_delete_own on public.thread_members;
create policy thread_members_delete_own
on public.thread_members
for delete
using (user_id = auth.uid());

-- MESSAGES: only members can read messages
drop policy if exists messages_select_members on public.messages;
create policy messages_select_members
on public.messages
for select
using (
  exists (
    select 1
    from public.thread_members tm
    where tm.thread_id = messages.thread_id
      and tm.user_id = auth.uid()
  )
);

-- MESSAGES: only members can insert messages as themselves
drop policy if exists messages_insert_members on public.messages;
create policy messages_insert_members
on public.messages
for insert
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.thread_members tm
    where tm.thread_id = messages.thread_id
      and tm.user_id = auth.uid()
  )
);

-- THREAD SUMMARIES: only members can read summaries
drop policy if exists thread_summaries_select_members on public.thread_summaries;
create policy thread_summaries_select_members
on public.thread_summaries
for select
using (
  exists (
    select 1
    from public.thread_members tm
    where tm.thread_id = thread_summaries.thread_id
      and tm.user_id = auth.uid()
  )
);

-- THREAD SUMMARIES: only creator can insert summary rows
drop policy if exists thread_summaries_insert_creator on public.thread_summaries;
create policy thread_summaries_insert_creator
on public.thread_summaries
for insert
with check (created_by = auth.uid());

-- Grants for authenticated users
grant select on public.threads to authenticated;
grant select, insert, delete on public.thread_members to authenticated;
grant select, insert on public.messages to authenticated;
grant select, insert on public.thread_summaries to authenticated;
