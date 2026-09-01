create extension if not exists pgcrypto;

create table if not exists public.realtors (
    id uuid primary key default gen_random_uuid(),
    profile_key text not null unique,
    name text,
    brokerage text,
    email text,
    phone text,
    languages jsonb not null default '[]'::jsonb,
    transaction_volume bigint,
    loan_count integer,
    loan_officers_used integer,
    loan_companies_used integer,
    updated_at timestamptz not null default now()
);

create table if not exists public.realtor_profile_scans (
    id uuid primary key default gen_random_uuid(),
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    source_file text not null,
    source_hash text not null unique,
    status text not null,
    validation_score integer,
    issues jsonb not null default '[]'::jsonb,
    raw_json jsonb not null,
    scanned_at timestamptz not null default now()
);

create table if not exists public.realtor_lo_relationships (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.realtor_profile_scans(id) on delete cascade,
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    loan_officer_name text,
    company text,
    branch text,
    loan_count integer,
    relationship_percent_raw text
);

create table if not exists public.realtor_company_relationships (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.realtor_profile_scans(id) on delete cascade,
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    company text,
    loan_count integer,
    relationship_percent_raw text
);

create table if not exists public.realtor_transactions (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.realtor_profile_scans(id) on delete cascade,
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    address text,
    sale_date_raw text,
    buyer_agent text,
    buyer_agent_company text,
    seller_agent text,
    seller_agent_company text,
    sale_price_raw text,
    loan_amount_raw text,
    ltv_raw text,
    loan_type text,
    loan_officer text,
    loan_officer_company text
);

create table if not exists public.realtor_loan_details (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.realtor_profile_scans(id) on delete cascade,
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    address text,
    sale_date_raw text,
    sale_price_raw text,
    loan_amount_raw text,
    ltv_raw text,
    loan_type text,
    loan_officer text,
    loan_officer_company text,
    lender text
);

create table if not exists public.realtor_title_relationships (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.realtor_profile_scans(id) on delete cascade,
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    side text,
    company text,
    transaction_count integer,
    relationship_percent_raw text
);

create table if not exists public.realtor_listings (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.realtor_profile_scans(id) on delete cascade,
    realtor_id uuid not null references public.realtors(id) on delete cascade,
    address text,
    list_date_raw text,
    list_price_raw text,
    open_house text
);

create index if not exists idx_realtor_scans_realtor_id on public.realtor_profile_scans(realtor_id);
create index if not exists idx_realtor_transactions_realtor_id on public.realtor_transactions(realtor_id);
create index if not exists idx_realtor_lo_relationships_realtor_id on public.realtor_lo_relationships(realtor_id);
create index if not exists idx_realtor_listings_realtor_id on public.realtor_listings(realtor_id);
