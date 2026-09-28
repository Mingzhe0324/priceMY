-- Run in a NEW Supabase project's SQL editor. Infrastructure draft; not deployed.
create extension if not exists pgcrypto;
create type public.price_source as enum ('official_partner','catalogue','receipt_verified','community','older_unverified');
create table public.retailers (
 id uuid primary key default gen_random_uuid(), name text not null,
 slug text not null unique, logo_path text, regions text[] not null default '{}',
 integration_status text not null default 'planned' check(integration_status in ('planned','partner','catalogue','community','paused')),
 active boolean not null default true
);
create table public.branches (
 id uuid primary key default gen_random_uuid(), retailer_id uuid not null references public.retailers,
 name text not null, state text not null, city text, address text,
 latitude numeric check(latitude between -90 and 90), longitude numeric check(longitude between -180 and 180),
 unique(id,retailer_id)
);
create table public.products (
 id uuid primary key default gen_random_uuid(), brand text not null, name text not null,
 variant text not null, size numeric not null check(size>0),
 unit text not null check(unit in ('g','ml','each')), pack_count int not null default 1 check(pack_count>0),
 category text, image_path text, created_at timestamptz not null default now()
);
create table public.product_barcodes (
 gtin text primary key check(gtin ~ '^[0-9]{14}$'),
 product_id uuid not null references public.products, verified boolean not null default false
);
create table public.retailer_products (
 id uuid primary key default gen_random_uuid(), retailer_id uuid not null references public.retailers,
 retailer_sku text not null, product_id uuid references public.products,
 match_method text check(match_method in ('gtin','attribute_verified','manual','ai_candidate')),
 match_status text not null default 'pending' check(match_status in ('pending','approved','rejected')),
 match_confidence numeric check(match_confidence between 0 and 1), unique(retailer_id,retailer_sku),
 check(match_status <> 'approved' or (product_id is not null and match_method is not null and match_method <> 'ai_candidate'))
);
create table public.price_observations (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products,
 retailer_id uuid not null references public.retailers, branch_id uuid not null,
 price_sen int not null check(price_sen>=0), currency text not null default 'MYR' check(currency='MYR'),
 member_price_sen int check(member_price_sen>=0), membership_label text,
 promotion_terms jsonb not null default '{}', min_quantity int not null default 1 check(min_quantity>0),
 source public.price_source not null, source_url text, evidence_path text,
 observed_at timestamptz not null, valid_from timestamptz, valid_until timestamptz,
 available boolean not null default true, approved boolean not null default false,
 is_mock boolean not null default false, created_at timestamptz not null default now(),
 foreign key(branch_id,retailer_id) references public.branches(id,retailer_id),
 check(valid_until is null or valid_from is null or valid_until>valid_from),
 check(member_price_sen is null or membership_label is not null)
);
create index offers_product_time on public.price_observations(product_id,observed_at desc);
create index offers_branch on public.price_observations(branch_id,product_id);
create table public.profiles (
 id uuid primary key references auth.users on delete cascade, display_name text,
 locale text not null default 'en-MY', preferred_state text, created_at timestamptz not null default now()
);
create table public.shopping_lists (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users on delete cascade,
 name text not null default 'My list', created_at timestamptz not null default now()
);
create table public.shopping_list_items (
 list_id uuid not null references public.shopping_lists on delete cascade,
 product_id uuid not null references public.products, quantity int not null check(quantity between 1 and 999),
 primary key(list_id,product_id)
);
create table public.price_alerts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users on delete cascade,
 product_id uuid not null references public.products, target_sen int not null check(target_sen>0),
 enabled boolean not null default true, created_at timestamptz not null default now(), unique(user_id,product_id)
);
create table public.receipts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users on delete cascade,
 object_path text not null, status text not null default 'pending' check(status in ('pending','processing','review','verified','rejected')),
 created_at timestamptz not null default now()
);
create table public.community_submissions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users on delete cascade,
 product_id uuid not null references public.products, branch_id uuid not null references public.branches,
 price_sen int not null check(price_sen>=0), receipt_id uuid references public.receipts,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
-- Public catalogue is readable; writes reserved for trusted import/moderation service.
do $$ declare t text; begin
 foreach t in array array['retailers','branches','products','product_barcodes','retailer_products','price_observations','profiles','shopping_lists','shopping_list_items','price_alerts','receipts','community_submissions'] loop
 execute format('alter table public.%I enable row level security', t);
 end loop;
 foreach t in array array['retailers','branches','products'] loop
 execute format('create policy public_read on public.%I for select to anon, authenticated using (true)',t);
 execute format('grant select on public.%I to anon, authenticated',t);
 end loop;
end $$;
create policy verified_barcode_read on public.product_barcodes for select to anon,authenticated using(verified);
create policy approved_prices_read on public.price_observations for select to anon,authenticated using(approved);
grant select on public.product_barcodes,public.price_observations to anon,authenticated;
-- Mapping table intentionally has no public policies.
create policy own_profile on public.profiles for all to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy own_lists on public.shopping_lists for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy own_items on public.shopping_list_items for all to authenticated
 using(exists(select 1 from public.shopping_lists l where l.id=list_id and l.user_id=(select auth.uid())))
 with check(exists(select 1 from public.shopping_lists l where l.id=list_id and l.user_id=(select auth.uid())));
create policy own_alerts on public.price_alerts for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
-- Users may insert pending receipts/submissions, but cannot self-verify or change moderation state.
create policy own_receipts_read on public.receipts for select to authenticated using(user_id=(select auth.uid()));
create policy own_receipts_insert on public.receipts for insert to authenticated with check(user_id=(select auth.uid()) and status='pending' and split_part(object_path,'/',1)=(select auth.uid())::text);
create policy own_receipts_delete on public.receipts for delete to authenticated using(user_id=(select auth.uid()));
create policy own_submissions_read on public.community_submissions for select to authenticated using(user_id=(select auth.uid()));
create policy own_submissions_insert on public.community_submissions for insert to authenticated with check(user_id=(select auth.uid()) and status='pending' and (receipt_id is null or exists(select 1 from public.receipts r where r.id=receipt_id and r.user_id=(select auth.uid()))));
grant select,insert,update,delete on public.profiles,public.shopping_lists,public.shopping_list_items,public.price_alerts to authenticated;
grant select,insert,delete on public.receipts to authenticated;
grant select,insert on public.community_submissions to authenticated;
-- Private receipt images, max 10 MB. No public bucket or public receipt URLs.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('receipts','receipts',false,10485760,array['image/jpeg','image/png','image/webp']);
create policy own_receipt_objects_read on storage.objects for select to authenticated
 using(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy own_receipt_objects_insert on storage.objects for insert to authenticated
 with check(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy own_receipt_objects_delete on storage.objects for delete to authenticated
 using(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
