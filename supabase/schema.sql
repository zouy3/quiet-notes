-- 在此项目的 SQL Editor 新建查询并完整运行。
-- 只创建本应用的表和权限，不修改其他业务表。
begin;
create table if not exists public.quiet_watchlist (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  market text not null check (market in ('SH','SZ','BJ','HK','US')),
  symbol text not null check (
    (market in ('SH','SZ','BJ') and symbol ~ '^[0-9]{6}$') or
    (market = 'HK' and symbol ~ '^[0-9]{5}$') or
    (market = 'US' and symbol ~ '^[A-Z][A-Z0-9.\-]{0,19}$')
  ),
  name text not null check (char_length(btrim(name)) between 1 and 40),
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now(),
  primary key (user_id, market, symbol)
);
alter table public.quiet_watchlist enable row level security;
revoke all on public.quiet_watchlist from anon;
revoke all on public.quiet_watchlist from authenticated;
grant select, insert, update, delete on public.quiet_watchlist to authenticated;
drop policy if exists quiet_select_own on public.quiet_watchlist;
create policy quiet_select_own on public.quiet_watchlist for select to authenticated
  using ((select auth.uid()) = user_id);
drop policy if exists quiet_insert_own on public.quiet_watchlist;
create policy quiet_insert_own on public.quiet_watchlist for insert to authenticated
  with check ((select auth.uid()) = user_id);
drop policy if exists quiet_update_own on public.quiet_watchlist;
create policy quiet_update_own on public.quiet_watchlist for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists quiet_delete_own on public.quiet_watchlist;
create policy quiet_delete_own on public.quiet_watchlist for delete to authenticated
  using ((select auth.uid()) = user_id);
commit;
