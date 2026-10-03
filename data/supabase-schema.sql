create table if not exists public.peminjaman (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  institusi text not null,
  item text not null,
  jumlah integer not null check (jumlah > 0),
  keterangan text not null default '',
  waktu timestamptz not null default now(),
  status text not null default 'Menunggu' check (status in ('Menunggu', 'Disetujui', 'Ditolak')),
  diverifikasi_oleh uuid references auth.users(id),
  diverifikasi_pada timestamptz
);

alter table public.peminjaman enable row level security;
revoke all on table public.peminjaman from anon, authenticated;
grant insert on table public.peminjaman to anon, authenticated;
grant select on table public.peminjaman to authenticated;
grant update (status, diverifikasi_oleh, diverifikasi_pada) on table public.peminjaman to authenticated;

drop policy if exists "Public can submit pending loans" on public.peminjaman;
create policy "Public can submit pending loans"
  on public.peminjaman for insert to anon, authenticated
  with check (
    status = 'Menunggu'
    and diverifikasi_oleh is null
    and diverifikasi_pada is null
  );

drop policy if exists "Assistants can read all loans" on public.peminjaman;
create policy "Assistants can read all loans"
  on public.peminjaman for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'lab_role') = 'assistant');

drop policy if exists "Assistants can verify loans" on public.peminjaman;
create policy "Assistants can verify loans"
  on public.peminjaman for update to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'lab_role') = 'assistant')
  with check (
    (auth.jwt() -> 'app_metadata' ->> 'lab_role') = 'assistant'
    and status in ('Disetujui', 'Ditolak')
    and diverifikasi_oleh = auth.uid()
    and diverifikasi_pada is not null
  );

-- This view intentionally excludes borrower names, class, and free-text notes.
drop view if exists public.peminjaman_publik;
create view public.peminjaman_publik
  with (security_barrier = true, security_invoker = false)
as
  select id, item, jumlah, waktu, status
  from public.peminjaman;
revoke all on table public.peminjaman_publik from public;
grant select on table public.peminjaman_publik to anon, authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'peminjaman'
  ) then
    alter publication supabase_realtime add table public.peminjaman;
  end if;
end
$$;
