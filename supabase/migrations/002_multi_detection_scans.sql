

-- 1. Scan_detections (same shape as in schema.sql).
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

drop policy if exists "Users can view own scan detections" on public.scan_detections;
create policy "Users can view own scan detections"
  on public.scan_detections for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own scan detections" on public.scan_detections;
create policy "Users can insert own scan detections"
  on public.scan_detections for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own scan detections" on public.scan_detections;
create policy "Users can delete own scan detections"
  on public.scan_detections for delete
  using (auth.uid() = user_id);

-- 2. Backfill one scan_detections row per existing scans row
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'scans' and column_name = 'label'
  ) then
    insert into public.scan_detections
      (scan_id, user_id, label, confidence, symptom, fertilizer, rate, timing, note, created_at)
    select id, user_id, label, confidence, symptom, fertilizer, rate, timing, note, created_at
    from public.scans;

    alter table public.scans
      drop column label,
      drop column confidence,
      drop column symptom,
      drop column fertilizer,
      drop column rate,
      drop column timing,
      drop column note;
  end if;
end $$;
