-- Moona: database schema (all access goes through the Edge Function with the service role)
create extension if not exists pg_net;
create extension if not exists pg_cron;

create table public.pairs (
  id uuid primary key default gen_random_uuid(),
  invite_code text unique,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table public.members (
  id uuid primary key default gen_random_uuid(),
  pair_id uuid not null references public.pairs(id) on delete cascade,
  role text not null check (role in ('owner','partner')),
  name text not null default '',
  token_hash text not null unique,
  status text not null default 'active' check (status in ('pending','active')),
  created_at timestamptz not null default now()
);
create index on public.members(pair_id);
create table public.push_subs (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);
create index on public.push_subs(member_id);
create table public.periods (
  id uuid primary key default gen_random_uuid(),
  pair_id uuid not null references public.pairs(id) on delete cascade,
  start_date date not null,
  end_date date,
  created_at timestamptz not null default now()
);
create index on public.periods(pair_id, start_date);
create table public.days (
  pair_id uuid not null references public.pairs(id) on delete cascade,
  date date not null,
  flow text,
  symptoms text[] not null default '{}',
  mood text,
  others text[] not null default '{}',
  memo text,
  updated_at timestamptz not null default now(),
  primary key (pair_id, date)
);
create table public.notices (
  id uuid primary key default gen_random_uuid(),
  pair_id uuid not null references public.pairs(id) on delete cascade,
  kind text not null,
  target text not null,
  title text,
  body text,
  delivered integer not null default 0,
  failed integer not null default 0,
  created_at timestamptz not null default now()
);
create index on public.notices(pair_id, created_at desc);
create table public.reminders_sent (
  pair_id uuid not null references public.pairs(id) on delete cascade,
  kind text not null,
  target_date date not null,
  primary key (pair_id, kind, target_date)
);
create table public.rate_hits (
  id bigserial primary key,
  key text not null,
  at timestamptz not null default now()
);
create index on public.rate_hits(key, at);
create table public.app_secrets (key text primary key, value text not null);

-- RLS on, no policies: nothing is reachable with the public keys
alter table public.pairs enable row level security;
alter table public.members enable row level security;
alter table public.push_subs enable row level security;
alter table public.periods enable row level security;
alter table public.days enable row level security;
alter table public.notices enable row level security;
alter table public.reminders_sent enable row level security;
alter table public.rate_hits enable row level security;
alter table public.app_secrets enable row level security;

-- atomic settings merge (two saves at once never overwrite each other)
create or replace function public.merge_settings(p_pair uuid, p_patch jsonb)
returns jsonb language sql security definer set search_path to 'public' as $$
  update public.pairs set settings = coalesce(settings, '{}'::jsonb) || p_patch where id = p_pair returning settings;
$$;
revoke all on function public.merge_settings(uuid, jsonb) from public, anon, authenticated;
grant execute on function public.merge_settings(uuid, jsonb) to service_role;
