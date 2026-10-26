-- 在原 Supabase 项目 SQL Editor 中完整运行一次；不删除数据，不修改用户权限。
begin;
alter table public.quiet_watchlist drop constraint if exists quiet_watchlist_market_check;
alter table public.quiet_watchlist drop constraint if exists quiet_watchlist_check;
alter table public.quiet_watchlist drop constraint if exists quiet_watchlist_market_allowed_v2;
alter table public.quiet_watchlist drop constraint if exists quiet_watchlist_symbol_valid_v2;
alter table public.quiet_watchlist add constraint quiet_watchlist_market_allowed_v2
  check (market in ('SH','SZ','BJ','HK','US','KR'));
alter table public.quiet_watchlist add constraint quiet_watchlist_symbol_valid_v2 check (
 (market in ('SH','SZ','BJ','KR') and symbol ~ '^[0-9]{6}$') or
 (market = 'HK' and symbol ~ '^[0-9]{5}$') or
 (market = 'US' and symbol ~ '^[A-Z][A-Z0-9.\-]{0,19}$')
);
commit;
