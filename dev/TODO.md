# Идеи для доработок

## BiHA 

### Параметры конфигурации кластера
biha.config ()

proxima_enabled (boolean) #                   biha.enable_proxima() и biha.disable_proxima()
service_mode (boolean) #                      biha.service_mode()
ssl_certificate (text) #                      biha.set_ssl_certificate()
ssl_mode (text) #                             biha.set_ssl_mode()
ssl_private_key (text) #                      biha.set_ssl_private_key()
synchronous_standby_names.count (integer) #   biha.set_sync_standbys()
synchronous_standby_names.min (integer) #     biha.set_sync_standbys_min()
synchronous_standby_names.names (integer) #   biha.set_ssn()  biha.add_to_ssn() или biha.get_ssn()
use_ssl (boolean) #                           biha.set_use_ssl()
user_biha_cert (text) #                       biha.set_user_cert()
user_biha_key (text) #                        biha.set_user_key()

### Параметры конфигурации сегмента

heartbeat_max_lost (integer) #                biha.set_heartbeat_max_lost()
heartbeat_send_period (integer) #             biha.set_heartbeat_send_period()
minnodes (integer) #                          biha.set_minnodes()
no_wal_on_follower (integer) #                biha.set_no_wal_on_follower()        
nquorum (integer) #                           biha.set_nquorum()

### Параметры конфигурации узла

asyncaction_timeout (integer) #               biha.set_asyncaction_timeout()
biha_hosts (string) #                         biha.set_biha_hosts()
biha_listen_addresses (string) #              bihactl
biha_port (integer) #                         bihactl, biha.set_biha_hosts(), biha_listen_addresses (string),  biha.set_replication_hosts()
callbacks_timeout (integer) #                 biha.set_callbacks_timeout()
config_send_period (integer) #                biha.set_config_send_period()
deny_wal_sources (string) #                   biha.set_deny_wal_sources()
flw_ro (boolean) #                            biha.set_flw_ro()
leader_timeout (integer) #                    biha.set_leader_timeout()
manage_slots_xmin (boolean) #                 biha.set_manage_slots_xmin()
max_replicas (integer) #                      biha.set_max_replicas()
pg_port (integer) #                           bihactl
replication_hosts (string) #                  biha.set_replication_hosts()
sql_hosts (string) #                          bihactl, biha.set_sql_hosts()
watchdog_timeout (integer) #                  biha.set_watchdog_timeout()

### Параметры конфигурации, общие для узлов и сегментов

can_be_leader (boolean) #                     biha.set_can_be_leader()
can_vote (boolean) #                          biha.set_can_vote()
mode (text) #                                 bihactl
name (text) #                                 bihactl
priority (integer) #                          biha.set_priority()
repl_pref_roles (text) #                      biha.set_pref_roles()

### Необязательные параметры конфигурации
Значения этих параметров на узлах кластера могут отличаться

biha.autorewind (boolean) #                   ALTER SYSTEM SET biha.autorewind = true;
biha.autowaltrim (boolean) #                  ALTER SYSTEM SET biha.autowaltrim = true;
biha.wal_validation (boolean) #               ALTER SYSTEM SET biha.wal_validation = true;

------------------------------------------------------------------------------------------------------------------------
## BiHA minnodes 

Если после отключения узла кол-во работающих узлов будет >= значения minnodes, то лидер останется в статусе RW.

## Добавить leader_timeout

`select leader_timeout from biha.config();`

## Сравнивать на серверах тип и версии ОС

## Считать размер папок через функции СУБД, потому что сейчас это работает только локально

Пример

```sql
2026-10-15 20:11:55+03  postgres@prod-fps-11[172.26.106.114 172.185.2.60] /var/lib/postgresql
Postgres Pro (enterprise) 18.6.1 62b5838ca4a  postgres@[local]:5432/psqlrc_db
=# select sum(size) from pg_ls_logdir();
┌───────────┐
│    sum    │
├───────────┤
│ 305339579 │
└───────────┘
```

## Показывать хвост файлов с логами, брать отсюда:
  ```
  postgres@prod-fpb-11:/pgdata/MR/keeper-fpb-mr-shard-1-1/postgres$ cat current_logfiles
  csvlog /var/log/postgres/postgres-fpb-mr-shard-1-prod-fpb-11-keeper_1.csv
  ```

## psql: путь поиска в приглашении

https://habr.com/ru/companies/postgrespro/articles/992426/#commit_b3ce55f41 

## Выводить предупреждение в случае наличия более новой версии расширения 

* 2026-08-27 21:26:54+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
  Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
  =# \dx
  List of installed extensions
  ┌────────────────┬─────────┬─────────────────┬────────────┬──────────────────────────────────────────────────────────────┐
  │      Name      │ Version │ Default version │   Schema   │                         Description                          │
  ├────────────────┼─────────┼─────────────────┼────────────┼──────────────────────────────────────────────────────────────┤
  │ biha           │ 1.7     │ 1.8             │ biha       │ BiHA                                                         │
  │ dblink         │ 1.2     │ 1.2             │ pro        │ connect to other PostgreSQL databases from within a database │
  │ pg_buffercache │ 1.6     │ 1.6             │ public     │ examine the shared buffer cache                              │
  │ plpgsql        │ 1.0.1   │ 1.0.1           │ pg_catalog │ PL/pgSQL procedural language                                 │
  │ tablefunc      │ 1.0     │ 1.0             │ public     │ functions that manipulate whole tables, including crosstab   │
  └────────────────┴─────────┴─────────────────┴────────────┴──────────────────────────────────────────────────────────────┘
  (5 rows)

## Прочее

* Документация: It is recommended to --- добавить причину performance/reliability reason
* BiHA - Показать уведомление, когда для двух узлов без рефери есть риск split-brain?
* https://wiki.postgresql.org/wiki/Don%27t_Do_This#Don't_use_trust_authentication_over_TCP/IP_(host,_hostssl)
* https://wiki.postgresql.org/wiki/Don%27t_Do_This#Don't_use_psql_-W_or_--password
* `idle_in_transaction_session_timeout` - warn при отсутствии ограничения
* Сделать функцию для выполнения SQL запросов на мастере, находясь на реплике?
  Например, так можно выполнить команды `SHOW` или `select * from pg_hba_file_rules order by rule_number;` или `select pg_reload_conf()`
* Добавить проверку, что установлены права 600 на файл .pgpass (см. https://postgrespro.ru/docs/postgresql/current/libpq-pgpass)?
* Добавить сколько времени назад были изменены файлы `config_file`, `hba_file`, `log_filename`, `~/.pgpass`?
* https://gitlab.com/depesz/pgWikiDont/-/blob/master/pgWikiDont.sql

* max_wal_size - Максимальный размер, до которого может вырастать WAL во время автоматических контрольных точек. Это мягкий предел; размер WAL может превышать max_wal_size при особых обстоятельствах, например при большой нагрузке, сбое в archive_command/archive_library или при большом значении wal_keep_size.
* wal_keep_size - Задаёт минимальный объём прошлых файлов WAL, который будет сохраняться в каталоге pg_wal, чтобы ведомый сервер мог выбрать их при потоковой репликации.
* max_slot_wal_keep_size - Задаёт максимальный размер файлов WAL, который может оставаться в каталоге pg_wal для слотов репликации после выполнения контрольной точки.

* Получить команду запуска `psql` с флагами:
```
\echo `ps -o cmd= -p $(ps -o ppid= -p $$)`
```

Прежде чем смотреть подробные отчёты о производительности часто бывает полезно оценить базовые настройки:
```sql
SELECT name, setting, unit, source
FROM pg_settings
WHERE name IN (
'shared_buffers',
'effective_cache_size',
'work_mem',
'maintenance_work_mem',
'max_connections',
'checkpoint_completion_target',
'checkpoint_timeout',
‘max_wal_size’,
'huge_pages',
'max_worker_processes'
);
```

Обнаруживать разорванные соединения примерно за 5–10 минут вместо стандартных 2 часов:
```
tcp_keepalives_idle = 300      # 5 минут простоя
tcp_keepalives_interval = 30   # повторять каждые 30 секунд
tcp_keepalives_count = 5       # после 5 неудач разорвать соединение
```

Пример получения параметров из `pg_settings` в колонках:
```sql
SELECT *
FROM crosstab(
    $sql$
        select null::text,
               s.name,
               nullif(trim(s.setting), '') 
        from pg_settings as s
        join unnest(array['biha.autorewind', 'biha.autowaltrim', 'biha.asyncaction_timeout']::text[]) 
             with ordinality as n (name, position) on s.name = n.name  
        order by n.position
    $sql$
) as p (category text, autorewind text, autowaltrim text, asyncaction_timeout text);
```

Статистика архивации WAL
```
SELECT archived_count, last_archived_wal, last_archived_time, failed_count, last_failed_time
  FROM pg_stat_archiver;
```

Hit ratio буферного кэша
``` 
SELECT
sum(heap_blks_read)  AS heap_read,
sum(heap_blks_hit)   AS heap_hit,
round(
100.0 * sum(heap_blks_hit) / nullif(sum(heap_blks_read + heap_blks_hit),0),
2
) AS hit_ratio_pct
FROM pg_statio_user_tables;
```

## Юникод

⚠️    U+26A0 U+FE0F    UTF8: 0xE2 0x9A 0xA0

Unicode Character U+FE0F is Variation Selector-16 (VS16), a special hidden code that tells your device to show a character as a colorful emoji instead of plain text


1. https://unicode.org/charts/PDF/U2B00.pdf
1. https://unicode.org/charts/PDF/U25A0.pdf

1. https://stackoverflow.com/questions/8343250/how-can-i-get-position-of-cursor-in-terminal
1. https://unix.stackexchange.com/questions/184345/detect-how-much-of-unicode-my-terminal-supports-even-through-screen
1. https://www.reddit.com/r/bash/comments/139hvju/finding_the_current_cursor_position_in_bash/


## Разное

1. [How to use variables in psql scripts](https://postgres.ai/docs/postgres-howtos/development-tools/psql/how-to-use-variables-in-psql-scripts)
1. [Морской бой в PostgreSQL](https://habr.com/ru/companies/selectel/articles/519010/)


## Цвета:

1. https://misc.flogisoft.com/bash/tip_colors_and_formatting (see `256-colors.sh`)
1. https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
1. https://postgres.ai/docs/postgres-howtos/development-tools/psql/how-to-format-text-output-in-psql-scripts


rabisx@ont-fpk-11:/opt/app/mcoi/menu$ ./manage.sh -bihatag 11 11

select biha.set_leader(11);
select biha.set_minnodes(2);
select biha.set_nquorum(2);
select biha.set_sync_standbys(1);
select biha.set_sync_standbys_min(-1);
select biha.set_ssn(11,21,31,41);

select biha.set_deny_wal_sources(11,'{}'::int[]);
select biha.set_deny_wal_sources(21,'{}'::int[]);
select biha.set_deny_wal_sources(31,'{}'::int[]);
select biha.set_deny_wal_sources(41,'{11,21}'::int[]);

select biha.set_max_replicas(11, 2);
select biha.set_max_replicas(21, 2);
select biha.set_max_replicas(31, 2);
select biha.set_max_replicas(41, 2);

select biha.set_pref_roles(11, 'L');
select biha.set_pref_roles(21, 'L');
select biha.set_pref_roles(31, 'FL');
select biha.set_pref_roles(41, 'FL');

select biha.set_priority(11, 0);
select biha.set_priority(21, 0);
select biha.set_priority(31, 0);
select biha.set_priority(41, 0);

select biha.set_can_be_leader(11,true);
select biha.set_can_be_leader(21,true);
select biha.set_can_be_leader(31,false);
select biha.set_can_be_leader(41,false);

select biha.set_can_vote(11, true);
select biha.set_can_vote(21, true);
select biha.set_can_vote(31, true);
select biha.set_can_vote(41, false);

# pg_replication_slots.wal_status = 'extended'
Статус extended в столбце wal_status представления pg_replication_slots PostgreSQL означает, 
что объём удерживаемых журналов предзаписи (WAL) превысил лимит max_wal_size, 
но нужные сегменты WAL пока сохраняются на диске благодаря слоту репликации или параметру wal_keep_size
