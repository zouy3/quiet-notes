begin;
create table if not exists public.quiet_sync_state(user_id uuid primary key references auth.users(id) on delete cascade, revision bigint not null default 0, stocks jsonb not null default '[]', updated_at timestamptz not null default now());
alter table public.quiet_sync_state enable row level security;
revoke all on public.quiet_sync_state from anon;
grant select,insert,update on public.quiet_sync_state to authenticated;
drop policy if exists own_state on public.quiet_sync_state;
create policy own_state on public.quiet_sync_state to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create or replace function public.quiet_sync_read() returns jsonb language plpgsql security invoker set search_path=public as $$
declare r public.quiet_sync_state;
begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 insert into public.quiet_sync_state(user_id,stocks) select auth.uid(),coalesce(jsonb_agg(jsonb_build_object('market',market,'symbol',symbol,'name',name,'position',position) order by position,created_at),'[]'::jsonb) from public.quiet_watchlist where user_id=auth.uid() on conflict do nothing;
 select * into r from public.quiet_sync_state where user_id=auth.uid();
 return jsonb_build_object('revision',r.revision,'stocks',r.stocks);
end $$;
create or replace function public.quiet_sync_write(expected_revision bigint,new_stocks jsonb) returns jsonb language plpgsql security invoker set search_path=public as $$
declare r public.quiet_sync_state;
begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 if jsonb_typeof(new_stocks) <> 'array' or jsonb_array_length(new_stocks)>10000 then raise exception 'Invalid list'; end if;
 select * into r from public.quiet_sync_state where user_id=auth.uid() for update;
 if not found or r.revision<>expected_revision then return jsonb_build_object('conflict',true); end if;
 update public.quiet_sync_state set stocks=new_stocks,revision=revision+1,updated_at=now() where user_id=auth.uid() returning * into r;
 return jsonb_build_object('revision',r.revision,'stocks',r.stocks);
end $$;
revoke all on function public.quiet_sync_read() from public,anon;
revoke all on function public.quiet_sync_write(bigint,jsonb) from public,anon;
grant execute on function public.quiet_sync_read(),public.quiet_sync_write(bigint,jsonb) to authenticated;
commit;
