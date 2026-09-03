CREATE VIEW pro.cluster_topology WITH (security_invoker = on) AS
with recursive
-- Шаг 1. Движемся от листа к корню с целью получить мастер.
m as (
    select not pg_is_in_recovery()                                      as is_primary,
           regexp_replace(t.primary_conninfo, '\m(user|application_name|connect_timeout)=\S*', '', 'g')
               || ' user=psqlrc_user application_name=dblink_topology connect_timeout=5' as conninfo,
           coalesce(inet_server_addr(), '127.0.0.1'::inet)              as addr,
           coalesce(inet_server_port(), current_setting('port')::int)   as port,
           0                                                            as level
    from nullif(trim(current_setting('primary_conninfo')), '') as t(primary_conninfo)
    union all
    select s.*,
           m.level - 1
    from m,
         pro.dblink(  -- в случае недоступности сетевого соединения dblink() возвратит ошибку
             m.conninfo,
             $sql$
                 select
                     not pg_is_in_recovery(),
                     regexp_replace(t.primary_conninfo, '\m(user|application_name|connect_timeout)=\S*', '', 'g')
                          || ' user=psqlrc_user application_name=dblink_topology connect_timeout=5',
                     inet_server_addr(),
                     inet_server_port()
                 from nullif(trim(current_setting('primary_conninfo')), '') as t(primary_conninfo)
             $sql$,
             true --fail_on_error
         ) as s (is_primary bool, conninfo text, addr inet, port int)
    where not m.is_primary and m.conninfo is not null
)
-- select * from m order by m.level desc; -- для отладки
-- Шаг 2. Движемся от корня к листам с целью получить информацию о репликах.
, r as (
    (select 1                          as level,
            m.is_primary               as is_primary,
            null::inet                 as parent_addr,
            m.addr                     as addr,
            m.port                     as port,
            null::pg_lsn               as last_lsn,
            null::pg_stat_replication  as pg_sr,
            null::pg_replication_slots as pg_rs,
            null::interval             as receive_uptime,
            null::interval             as reply_ago
    from m
    order by m.level
    limit 1)
    union all
    select r.level + 1           as level,
           false                 as is_primary,
           r.addr                as parent_addr,
           (s.pg_sr).client_addr as addr,
           r.port,
           s.last_lsn,
           s.pg_sr,
           s.pg_rs,
           s.receive_uptime,
           s.reply_ago
    from r,
         pro.dblink(
            format('user=psqlrc_user host=%s port=%s dbname=postgres application_name=dblink_topology connect_timeout=5', r.addr, r.port),
            $sql$
                select w.last_lsn,
                       pg_sr,
                       pg_rs,
                       now() - pg_sr.backend_start as receive_uptime,
                       now() - pg_sr.reply_time    as reply_ago
                from pg_stat_replication as pg_sr                                        -- https://postgrespro.ru/docs/postgresql/current/monitoring-stats#MONITORING-PG-STAT-REPLICATION-VIEW
                left join pg_replication_slots as pg_rs on pg_sr.pid = pg_rs.active_pid  -- https://postgrespro.ru/docs/postgresql/current/view-pg-replication-slots
                cross join coalesce(case when pg_is_in_recovery() then pg_last_wal_receive_lsn() else pg_current_wal_lsn() end) as w(last_lsn)
            $sql$,
            true --fail_on_error
           ) as s (last_lsn       pg_lsn,
                   pg_sr          pg_stat_replication,
                   pg_rs          pg_replication_slots,
                   receive_uptime interval,
                   reply_ago      interval)
)
-- select * from r order by r.level; -- для отладки
-- Шаг 3. Собираем информацию со всех серверов.
, p as (
    select r.*, s.*
    from r
    left join pro.dblink(
           format('user=psqlrc_user host=%s port=%s dbname=postgres application_name=dblink_topology connect_timeout=5', r.addr, r.port),
           $sql$
               with guc as (
                   select
                       -- https://postgrespro.ru/docs/postgresql/current/runtime-config-replication#RUNTIME-CONFIG-REPLICATION-PRIMARY
                       -- Главный сервер. Эти параметры можно задать на главном/ведущем сервере, который должен передавать данные репликации одному или нескольким ведомым.
                       jsonb_object_agg_strict(name, nullif(trim(setting), '')) filter (where name in ('synchronous_standby_names',
                                                                                                       'synchronized_standby_slots')) as primary,

                       -- https://postgrespro.ru/docs/postgresql/current/runtime-config-replication#RUNTIME-CONFIG-REPLICATION-STANDBY
                       -- Ведомые серверы. Эти параметры управляют поведением ведомого сервера, который будет получать данные репликации. На ведущем сервере они не играют никакой роли.
                       jsonb_object_agg_strict(name, nullif(trim(setting), '')) filter (where name in ('primary_conninfo',
                                                                                                       'primary_slot_name',
                                                                                                       'hot_standby',
                                                                                                       'max_standby_archive_delay',
                                                                                                       'max_standby_streaming_delay',
                                                                                                       'wal_receiver_status_interval',
                                                                                                       'hot_standby_feedback',
                                                                                                       'wal_receiver_timeout',
                                                                                                       'wal_retrieve_retry_interval',
                                                                                                       'recovery_min_apply_delay',
                                                                                                       'sync_replication_slots')) as replica,
                       -- https://postgrespro.ru/docs/enterprise/current/biha-reference
                       jsonb_object_agg_strict(right(name, -5), nullif(trim(setting), '')) filter (where name ~ '^biha\.[a-z]') as biha
                   from pg_settings
               )
               select
                   pg_postmaster_start_time()         as started_at,
                   now() - pg_postmaster_start_time() as start_uptime,
                   pg_conf_load_time()                as loaded_at,
                   now() - pg_conf_load_time()        as load_uptime,
                   case when pg_is_in_recovery() then pg_get_wal_replay_pause_state() end as pause_state, -- not paused / pause requested / paused
                   coalesce(
                       (select nullif(trim(setting), '') from pg_settings where name = 'pgpro_version' limit 1),
                       version()
                   ) as pg_version,
                   guc.primary as guc_primary,
                   guc.replica as guc_replica,
                   guc.biha    as guc_biha,
                   ping.remote_addr as ping_remote_addr,
                   ping.latency     as ping_latency,
                   ping.time_diff   as ping_time_diff
               from guc,
                    pro.ping(
                        regexp_replace(guc.replica->>'primary_conninfo', '\m(application_name|connect_timeout)=\S*', '', 'g')
                        || ' application_name=dblink_topology_ping connect_timeout=5'
                    ) as ping
           $sql$,
           true --fail_on_error
          ) as s (started_at   timestamptz,
                  start_uptime interval,
                  loaded_at    timestamptz,
                  load_uptime  interval,
                  pause_state  text,
                  pg_version   text,
                  guc_primary  jsonb,
                  guc_replica  jsonb,
                  guc_biha     jsonb,
                  ping_remote_addr inet,
                  ping_latency   interval,
                  ping_time_diff interval
          ) on true
)
-- Шаг 4. Финальная сборка колонок.
select
    p.level, p.is_primary,

    (regexp_match(p.guc_replica->>'primary_conninfo', '\mhost=(\S+)'))[1] as parent_host,

    -- p.parent_addr использовать нельзя, т.к. в значении может быть локальный IP 127.0.0.1,
    -- если этот запрос выполняется на мастере с локальным подключением или по сокету, а нам нужен внешний IP
    p.ping_remote_addr as parent_addr,

    coalesce(
        (p.pg_sr).client_hostname, -- это поле будет не null только в случае соединений по IP и только при включённом режиме log_hostname
        p.guc_biha->>'host' -- workaround
    ) as host,

    coalesce(
        (select pp.ping_remote_addr from p as pp where pp.level = 2 and p.is_primary limit 1),
        p.addr
    ) as addr,

    p.port,
    p.last_lsn, p.receive_uptime, p.reply_ago,
    p.started_at, p.start_uptime, p.loaded_at, p.load_uptime,
    p.pause_state, p.pg_version, trim((regexp_match(p.pg_version, ' \d+(?:\.\d+)+'))[1]) as pg_version_dot, -- X.Y[.Z]
    p.guc_primary, p.guc_replica, p.guc_biha,
    p.ping_latency, p.ping_time_diff,
    (p.pg_sr).*, (p.pg_rs).*
from p;

COMMENT ON VIEW pro.cluster_topology IS 'Cluster topology. Returns servers: master and dependent replicas, including cascaded ones.';


------------------------------------------------------------------------------------------------------------------------
create function pro.cluster_topology()
    returns setof pro.cluster_topology
    volatile -- !!!
    returns null on null input
    parallel safe
    SECURITY DEFINER
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
begin atomic
    table pro.cluster_topology;
end;

comment on function pro.cluster_topology() is 'Wrapper for view "pro.cluster_topology" due "SECURITY DEFINER" reason';