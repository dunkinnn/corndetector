-- Corn Leaf Nutrient Deficiency Detection: Supabase schema.
-- Run this once in your project's SQL Editor (Supabase dashboard > SQL Editor > New query > Run).
-- For an existing project that already has the old single-detection `scans`
-- table, run supabase/migrations/002_multi_detection_scans.sql instead -
-- this file is the fresh-install target schema.

-- 1. Profiles: one row per auth user, holds display name.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  email text not null,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''), new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Scans: one row per leaf photo. A photo can contain more than one leaf
-- or symptom area, so the actual classification results live in
-- scan_detections below (one scan has one or more detections).
create table if not exists public.scans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  image_path text,
  created_at timestamptz not null default now()
);

create index if not exists scans_user_id_created_at_idx
  on public.scans (user_id, created_at desc);

alter table public.scans enable row level security;

create policy "Users can view own scans"
  on public.scans for select
  using (auth.uid() = user_id);

create policy "Users can insert own scans"
  on public.scans for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own scans"
  on public.scans for delete
  using (auth.uid() = user_id);

-- 3. Scan detections: one row per detected region within a scan's photo.
-- user_id is denormalized from the parent scan so RLS here doesn't need a
-- join. box_* columns are the detection's location as fractions (0.0-1.0)
-- of the photo and are nullable since not every detection is localized.
create table if not exists public.scan_detections (
  id uuid primary key default gen_random_uuid(),
  scan_id uuid not null references public.scans (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  label text not null,
  confidence numeric(4,3) not null,
  symptom text not null,
  fertilizer text not null,
  rate text not null,
  timing text not null,
  note text not null,
  box_left numeric(5,4),
  box_top numeric(5,4),
  box_width numeric(5,4),
  box_height numeric(5,4),
  created_at timestamptz not null default now()
);

create index if not exists scan_detections_scan_id_idx
  on public.scan_detections (scan_id);

alter table public.scan_detections enable row level security;

create policy "Users can view own scan detections"
  on public.scan_detections for select
  using (auth.uid() = user_id);

create policy "Users can insert own scan detections"
  on public.scan_detections for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own scan detections"
  on public.scan_detections for delete
  using (auth.uid() = user_id);

-- 4. Deficiency reference data: symptom and fertilizer guidance per label.
-- Readable by any signed-in user; edited only via the SQL editor (no client writes).
create table if not exists public.deficiency_reference (
  label text primary key,
  symptom text not null,
  fertilizer text not null,
  rate text not null,
  timing text not null,
  note text not null
);

alter table public.deficiency_reference enable row level security;

create policy "Authenticated users can read reference data"
  on public.deficiency_reference for select
  using (auth.role() = 'authenticated');

insert into public.deficiency_reference (label, symptom, fertilizer, rate, timing, note)
values
  ('Healthy',
   'Uniform green leaves with no visible discoloration.',
   'No additional fertilizer needed',
   'Maintain current program',
   'Next scheduled application',
   'Re-scan in 7 to 10 days to confirm the crop stays on track.'),
  ('Nitrogen Deficiency',
   'Yellowing along the midrib of older, lower leaves.',
   'Urea (46-0-0)',
   '2 to 3 bags per hectare',
   'Side-dress at V6 to V8, before tasseling',
   'Apply to moist soil and cover lightly to reduce loss to the air.'),
  ('Phosphorus Deficiency',
   'Purple or reddish tint on leaf edges of young plants.',
   'Solophos (0-18-0)',
   '2 bags per hectare',
   'Band near the root zone at planting or early vegetative',
   'Check soil pH; uptake drops sharply in strongly acidic soil.'),
  ('Potassium Deficiency',
   'Yellow to brown scorching along the margins of older leaves.',
   'Muriate of Potash (0-0-60)',
   '1 to 2 bags per hectare',
   'Apply during early vegetative growth',
   'Split the dose on sandy soil to limit leaching.')
on conflict (label) do nothing;

-- 5. Storage bucket for scan photos (private, one folder per user).
insert into storage.buckets (id, name, public)
values ('scan-photos', 'scan-photos', false)
on conflict (id) do nothing;

create policy "Users can upload their own scan photos"
  on storage.objects for insert
  with check (
    bucket_id = 'scan-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can view their own scan photos"
  on storage.objects for select
  using (
    bucket_id = 'scan-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete their own scan photos"
  on storage.objects for delete
  using (
    bucket_id = 'scan-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
