# Удобное приглашение командной строки в `psql` (Convenient command line prompt in `psql`)

## Назначение

Функциональность предназначена для администраторов СУБД [PostgreSQL](https://www.postgresql.org/) и [Postgres Pro](https://postgrespro.ru/).

По умолчанию [`psql`](https://postgrespro.ru/docs/postgresql/current/app-psql) показывает в приглашении командной строки только название текущей базы и всё.
Используя файл [`~/.psqlrc`](https://postgrespro.ru/docs/postgresql/current/app-psql#APP-PSQL-FILES-PSQLRC) можно значительно улучшить приглашение, 
а при запуске `psql` выводить дополнительную полезную информацию для поверхностной оценки состояния сервера СУБД и текущей базы.   

## Инсталляция

```bash
# 1) из репозитория скопируйте папку psqlrc в домашнюю папку  

# 2) создайте символическую ссылку
ln -sv ~/psqlrc/main.psql ~/.psqlrc

# 3) сохраните пароль для пользователя postgres, при необходимости
nano ~/.pgpass
```

## Использование

Интерактивный режим:
```bash
# подключитесь локально по сокету
psql -v pro=1

# или подключитесь сразу к мастеру
psql -v pro=1 'postgresql://postgres@host-1,host-2,host-3,host-4/postgres?target_session_attrs=read-write&connect_timeout=3'

# только приглашение командной строки без информационных сообщений и проверок (с флагом -q)
psql -v pro=0 -q
```

Значения опции `pro`

1. `psql -v pro=1` — с вычислением размера директорий для локальных подключений (медленно при большом количестве файлов), игнорируется с флагом `-q`
1. `psql -v pro=0` — без вычисления размера директорий (быстро)

Встраивание в `bash` скрипты на примере выполнения коротких SQL команд:
```bash
psql -v pro=0 -q -f ~/psqlrc/command_T.psql -P title="Cluster topology at ($(date --rfc-3339=seconds | sed 's/:00$//'))"

psql -v pro=0 -q -f ~/psqlrc/command_B.psql -P title="BiHA cluster state and config" biha_db
```

## Что отображается в командной строке `psql`

В первой строке — информация, относящаяся к ОС текущего сервера:
1. дата и время с часовой зоной (в формате [RFC 3339](https://ijmacd.github.io/rfc3339-iso8601/))
1. `user@host[IP_addresses] current_directory`

Во второй строке — информация, относящаяся к СУБД:
1. название сервера, версия и хеш сборки сервера
1. DSN подключения: `user@host:port/database`

Во третьей строке — приглашение для ввода команд `psql` и SQL запросов к СУБД

## Что отображается при запуске `psql`

### Сервер СУБД

1. systemd unit name, включена ли автозагрузка, PID основного процесса
1. дата и время, когда был запущен сервер (и сколько времени прошло)
1. дата и время, когда в последний раз сервер загружал файлы конфигурации (и сколько времени прошло)
1. директория с выполняемыми файлами (`bin`) для локального подключения
1. директория с данными (`data_directory`), занятый и свободный размер для локального подключения
1. директория с протоколами (`log_directory`), занятый и свободный размер для локального подключения 
1. директория с WAL, занятый и свободный размер для локального подключения; 
   для символической ссылки дополнительно отображается настоящая директория
1. количество подключений: текущее, максимальное и сколько использовано в процентах
1. размер кеша текущий, максимальный и сколько использовано в процентах
1. роль сервера: основной (мастер) `primary` или резервный (реплика) `replica`
1. откуда принимаются WAL файлы (мастер или реплика - всегда одна):
    * название слота или подключения
    * DSN подключения: `user@host:port/database`
    * статус: `starting/stopped/stopping/streaming`
    * пауза: `not paused / pause requested / paused`
    * отставание во времени и байтах (форматированное)
1. куда передаются WAL файлы (в скобках указано количество реплик):
   * название слота или подключения
   * DSN подключения: `user@host:port/database`
   * тип репликации: `physical/logical`
   * тип слота: `temporary/persistent/unknown`
   * тип синхронизации: `async/potential/sync/quorum`
   * состояние репликации: `startup/catchup/streaming/backup/stopping`
   * отставание во времени и байтах (форматированное)
1. `synchronous_commit`: `on /off`
1. `synchronous_standby_names`
1. `shared_preload_libraries`
1. `walsender_plugin_libraries`
1. архивация:
   * режим (`archive_mode`): `off/on/always`
   * ограничение времени существования неархивированных данных (`archive_timeout`)
   * команда ОС для архивации (`archive_command`)
   * команда ОС для восстановления (`restore_command`)

### Текущая база данных

1. название базы и её размер
1. процент попадания в кеш 
1. установленные расширения и их версии

### Короткие SQL команды
* `:W` — who am i (информация о текущем пользователе, схеме и т.д.).
* `:A` — агрегированная информация из `pg_stat_activity`.
* `:T` — топология кластера СУБД. Возвращает серверы: мастер и зависимые реплики, включая каскадные.
  Для каждой реплики имеется детализированная информация о размере и длительности отставания от зависимых серверов.
* `:B` — [BiHA](https://postgrespro.ru/docs/enterprise/current/biha-reference): состояние и конфигурация узлов кластера.
* `:BB` — [BiHA](https://postgrespro.ru/docs/enterprise/current/biha-reference) шпаргалка: сопоставление параметров конфигурации с функциями управления.
  
Для выполнения команды просто введите её в приглашении `psql` и нажмите клавишу `Enter`. 

## Валидация при запуске `psql`

1. Отображаются ошибки в конфигурационном файле `postgresql.conf`, если такие имеются.
   Выводится название конфигурационного файла, номера строк, название параметра, текст ошибки.
1. Отображаются ошибки в конфигурационном файле `pg_hba.conf`, если такие имеются. 
   Выводится название конфигурационного файла, номера строк, название параметра, текст ошибки.

## Поддержка внешнего ПО

Используется пейджер [`pspg`](https://github.com/okbob/pspg), если он установлен. 
Иначе используется [`less`](https://en.wikipedia.org/wiki/Less_(Unix)), если он установлен.

## Примеры

Примеры могут быть не полностью актуальными, т.к. функциональность развивается быстрее, чем создаются примеры. 

### Автономная СУБД

#### Без применения `.psqlrc` 

```
[postgres@rmukhtarov-redos1 ~]$ psql demo
psql (18.3, server 17.9)
Type "help" for help.

demo=# \d+
                                    List of relations
 Schema |   Name   | Type  |  Owner   | Persistence | Access method | Size  | Description 
--------+----------+-------+----------+-------------+---------------+-------+-------------
 public | my_table | table | postgres | permanent   | heap          | 16 kB | 
(1 row)

demo=#  
```

#### С применением `.psqlrc`

```
[postgres@rmukhtarov-redos1 ~]$ psql -v pro=1 demo
~/.psqlrc version: 697fd3f0  https://github.com/rin-nas/psqlrc

# OS
top - 11:01:45 up 21 days, 18:00,  1 user,  load average: 0.01, 0.01, 0.00
Tasks: 144 total,   1 running, 141 sleeping,   2 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7937.3 total,    227.7 free,    441.3 used,   7268.3 buff/cache
MiB Swap:   1881.0 total,   1878.2 free,      2.8 used.   7083.5 avail Mem 

# SERVER
Systemd unit:          postgrespro-ent-17.service (pid: 1465665, autostart: enabled)
Started at:            2026-06-03 16:57:18+03 (1 day 21:45:52 ago)
Config loaded at:      2026-06-05 00:01:06+03 (14:42:04 ago)
Bin directory:         /opt/pgpro/ent-17/bin
Data directory:        /var/lib/pgpro/ent-17/data (size: 2.9G total, 74G free)
WAL directory:         /var/lib/pgpro/ent-17/data/pg_wal (size: 993M total, 74G free)
Log directory:         /var/lib/pgpro/ent-17/data/log (size: 2.1M files, 74G free)
Connections:           12 of 61 (used 20%)
Shared buffers/cache:  7608 kB of 492 MB (used 2%)
Server role:           primary (read-write)
WAL send (0):          
Synchronous commit:    on
Shared preload libs:   pgpro_bindump, ptrack
Walsender plugin libs: pgpro_bindump
Archive mode:          off

# DATABASE
Current database:      demo (size: 1379 MB total)
Cache hit ratio:       0%
Installed extensions:  btree_gist 1.8.1, cube 1.5, earthdistance 1.2, pg_buffercache 1.6, plpgsql 1.0.1, ptrack 2.5

# SHORT SQL
:W — Who am i.
:A — Stat activity groups counts.
:T — Cluster topology. Returns servers: primary and dependent replicas, including cascaded ones.
:B — BiHA cluster state and config, see https://postgrespro.ru/docs/enterprise/current/biha-reference
:BB — BiHA cheat sheet: config settings to management functions mapping

psql (18.3, server 17.9)
Type "help" for help.


2026-06-05 14:43:10+03  postgres@rmukhtarov-redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=# \d+
                                    List of relations
┌────────┬──────────┬────────┬──────────┬─────────────┬───────────────┬───────┬─────────────┐
│ Schema │   Name   │  Type  │  Owner   │ Persistence │ Access method │ Size  │ Description │
├────────┼──────────┼────────┼──────────┼─────────────┼───────────────┼───────┼─────────────┤
│ public │ my_table │ table  │ postgres │ permanent   │ heap          │ 16 kB │ ¤           │
└────────┴──────────┴────────┴──────────┴─────────────┴───────────────┴───────┴─────────────┘
(1 row)


2026-06-05 14:48:59+03  postgres@rmukhtarov-redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=# 
```

### Кластерная СУБД

#### С применением `.psqlrc`, мастер

```
postgres@sdm18-1:~$ psql -v pro=1
~/.psqlrc version: 697fd3f0  https://github.com/rin-nas/psqlrc

# OS 
top - 11:01:45 up 21 days, 18:00,  1 user,  load average: 0.01, 0.01, 0.00
Tasks: 144 total,   1 running, 141 sleeping,   2 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7937.3 total,    227.7 free,    441.3 used,   7268.3 buff/cache
MiB Swap:   1881.0 total,   1878.2 free,      2.8 used.   7083.5 avail Mem 

# SERVER
Systemd unit:          postgrespro-ent-18.service (pid: 1465665, autostart: enabled)
Started at:            2026-05-06 10:36:04+00 (30 days 01:10:49 ago)
Config loaded at:      2026-05-06 10:36:17+00 (30 days 01:10:36 ago)
Data directory:        /pgdata/keeper-sdm18-test-shard-1-1/postgres (size: 15G total, 74G free)
WAL directory:         /pgdata/keeper-sdm18-test-shard-1-1/postgres/pg_wal (size: 13G total, 74G free)
Log directory:         /pgdata (size: 348M files, 74G free)
Connections:           40 of 1000 (used 4%)
Shared buffers/cache:  13 MB of 2600 MB (used 0%)
Server role:           primary (read-write)
WAL send (1):          biha_node_2  biha_replication_user@192.168.22.141:57560  physical persistent  quorum streaming  (lag: 1ms, 128 bytes)
Synchronous commit:    on
Shared preload libs:   shardman, biha, pgpro_bindump, pg_stat_statements
Walsender plugin libs: pgpro_bindump
Archive mode:          on (timeout: 1800)
Archive command:       /usr/bin/pg_probackup3 archive-push -B /backups/sdm --instance shard-1 --wal-file-path=%p --wal-file-name=%f --log-level-console=debug -j 1 --compress-algorithm zstd --compress-level 3

# DATABASE
Current database:      postgres (size: 125 MB total)
Cache hit ratio:       0%
Installed extensions:  pg_buffercache 1.6, pg_stat_statements 1.12, pgstattuple 1.5, plpgsql 1.0.1, shardman 0.2.106

# SHORT SQL
:W — Who am i.
:A — Stat activity groups counts.
:T — Cluster topology. Returns servers: primary and dependent replicas, including cascaded ones.
:B — BiHA cluster state and config, see https://postgrespro.ru/docs/enterprise/current/biha-reference
:BB — BiHA cheat sheet: config settings to management functions mapping

psql (18.3)
Type "help" for help.


2026-06-05 14:46:52+03  postgres@sdm18-1[192.168.22.146] /home/postgres
Postgres Pro (shardman) 18.3.3 fbc0896965c  postgres@[local]:5432/postgres
=# 
```

#### С применением `.psqlrc`, реплика

```
postgres@sdm18-4:~$ psql -v pro=1
~/.psqlrc version: 697fd3f0  https://github.com/rin-nas/psqlrc

# OS 
top - 11:01:45 up 21 days, 18:00,  1 user,  load average: 0.01, 0.01, 0.00
Tasks: 144 total,   1 running, 141 sleeping,   2 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7937.3 total,    227.7 free,    441.3 used,   7268.3 buff/cache
MiB Swap:   1881.0 total,   1878.2 free,      2.8 used.   7083.5 avail Mem 

# SERVER
Systemd unit:          postgrespro-ent-18.service (pid: 1465665, autostart: enabled)
Started at:            2026-05-06 10:36:16+00 (30 days 01:10:07 ago)
Config loaded at:      2026-05-06 10:36:23+00 (30 days 01:10:00 ago)
Data directory:        /pgdata/keeper-sdm18-test-shard-1-2/postgres (size: 1.1G total, 74G free)
WAL directory:         /pgdata/keeper-sdm18-test-shard-1-2/postgres/pg_wal (size: 17M total, 74G free)
Log directory:         /pgdata (size: 348M files, 74G free)
Connections:           32 of 1000 (used 3%)
Shared buffers/cache:  2600 MB
Server role:           replica (read only)
WAL receive (1):       biha_node_2  biha_replication_user@sdm18-1:5432  streaming  not paused  (lag: 1s 158ms, 296 bytes)
WAL send (0):
Synchronous commit:    on
Shared preload libs:   shardman, biha, pgpro_bindump, pg_stat_statements, pgpro_activity_collector
Walsender plugin libs: pgpro_bindump
Archive mode:          on (timeout: 1800)
Archive command:       /usr/bin/pg_probackup3 archive-push -B /backups/sdm --instance shard-1 --wal-file-path=%p --wal-file-name=%f --log-level-console=debug -j 1 --compress-algorithm zstd --compress-level 3

# DATABASE
Current database:      postgres (size: 118 MB total)
Cache hit ratio:       0%
Installed extensions:  pg_stat_statements 1.12, pgstattuple 1.5, plpgsql 1.0.1, shardman 0.2.106

# SHORT SQL
:W — Who am i.
:A — Stat activity groups counts.
:T — Cluster topology. Returns servers: primary and dependent replicas, including cascaded ones.
:B — BiHA cluster state and config, see https://postgrespro.ru/docs/enterprise/current/biha-reference
:BB — BiHA cheat sheet: config settings to management functions mapping

psql (18.3)
Type "help" for help.


2026-06-05 14:46:23+03  postgres@sdm18-4[192.168.22.141] /home/postgres
Postgres Pro (shardman) 18.3.3 fbc0896965c  postgres@[local]:5432/postgres
=# 
```

### Пример вывода коротких команд

#### :W
```
2026-08-18 11:51:52+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :W
                                                  Who am i (at 2026-08-18 11:54:05+00)
┌────┬───────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  # │         name          │                                                  value                                                  │
├────┼───────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  1 │ now()                 │ 2026-08-18 11:54:06+00                                                                                  │
│  2 │ pg_backend_pid()      │ 2117045                                                                                                 │
│  3 │ is_superuser          │ true                                                                                                    │
│  4 │ CURRENT_USER          │ postgres                                                                                                │
│  5 │ SESSION_USER          │ postgres                                                                                                │
│  6 │ current_database()    │ biha_db                                                                                                 │
│  7 │ current_schema()      │ public                                                                                                  │
│  8 │ current_schemas(true) │ {pg_catalog,public}                                                                                     │
│  9 │ current_xact_id       │ ¤                                                                                                       │
│ 10 │ current_xact_status   │ ¤                                                                                                       │
│ 11 │ pg_current_logfile()  │ ¤                                                                                                       │
│ 12 │ inet_client_addr()    │ ¤                                                                                                       │
│ 13 │ inet_client_port()    │ ¤                                                                                                       │
│ 14 │ inet_server_addr()    │ ¤                                                                                                       │
│ 15 │ inet_server_port()    │ ¤                                                                                                       │
│ 16 │ pg_jit_available()    │ false                                                                                                   │
│ 17 │ pg_numa_available()   │ true                                                                                                    │
│ 18 │ version()             │ PostgreSQL 18.4 on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0, 64-bit │
│ 19 │ unicode_version()     │ 16.0                                                                                                    │
│ 20 │ icu_unicode_version() │ 14.0                                                                                                    │
└────┴───────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(20 rows)

Time: 0.900 ms
```

#### :A
```
2026-08-18 11:54:05+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :A
                                                    Stat activity groups counts (at 2026-08-18 11:54:30+00)
┌──────────────────────────────┬────────────┬─────────┬───────────────────────┬───────────────────┬─────────────────────┬───────────────┬─────────────────────┐
│        backend_type ↓        │ database ↓ │ state ↓ │        user ↓         │ wait_event_type ↓ │    wait_event ↓     │ count_total ↓ │ count_state_changed↵│
│                              │            │         │                       │                   │                     │               │  > 1s/5s/1m/1h ago  │
├──────────────────────────────┼────────────┼─────────┼───────────────────────┼───────────────────┼─────────────────────┼───────────────┼─────────────────────┤
│ BiHA pgc worker              │ biha_db    │ ¤       │ postgres              │ Extension         │ Extension           │             1 │   0   0   0   0     │
│ BiHA worker                  │ biha_db    │ ¤       │ postgres              │ ¤                 │ ¤                   │             1 │   0   0   0   0     │
│ CFS GC worker                │ ¤          │ idle    │ ¤                     │ Activity          │ CfsGcEnable         │             1 │   1   0   0   0     │
│ autovacuum launcher          │ ¤          │ ¤       │ ¤                     │ Activity          │ AutovacuumMain      │             1 │   0   0   0   0     │
│ background freezer           │ ¤          │ ¤       │ ¤                     │ Activity          │ BgfreezerMain       │             1 │   0   0   0   0     │
│ background writer            │ ¤          │ ¤       │ ¤                     │ Activity          │ BgwriterHibernate   │             1 │   0   0   0   0     │
│ cfs gc launcher              │ ¤          │ ¤       │ ¤                     │ Activity          │ CfsGcEnable         │             1 │   0   0   0   0     │
│ checkpointer                 │ ¤          │ ¤       │ ¤                     │ Activity          │ CheckpointerMain    │             1 │   0   0   0   0     │
│ client backend               │ biha_db    │ active  │ postgres              │ ¤                 │ ¤                   │             1 │   0   0   0   0     │
│ client backend               │ biha_db    │ idle    │ postgres              │ Client            │ ClientRead          │             4 │   3   3   0   0     │
│ io worker                    │ ¤          │ ¤       │ ¤                     │ Activity          │ IoWorkerMain        │             3 │   0   0   0   0     │
│ logical replication launcher │ ¤          │ ¤       │ postgres              │ Activity          │ LogicalLauncherMain │             1 │   0   0   0   0     │
│ walsender                    │ ¤          │ active  │ biha_replication_user │ Activity          │ WalSenderMain       │             2 │   2   2   2   2     │
│ walwriter                    │ ¤          │ ¤       │ ¤                     │ Activity          │ WalWriterMain       │             1 │   0   0   0   0     │
└──────────────────────────────┴────────────┴─────────┴───────────────────────┴───────────────────┴─────────────────────┴───────────────┴─────────────────────┘
(14 rows)

Time: 1.478 ms
```

#### :T
```
2026-08-18 11:54:30+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :T
                                                                                      Cluster topology (at 2026-08-18 11:56:59+00)
┌─────────┬─────────┬────────────────┬────────────────┬───────────┬──────────┬────────────┬─────────────────────────────────┬────────────────────┬───────────┬──────────────┬───────────────┬─────────────┬─────────────┐
│ level ↓ │  role   │  parent_host  ↵│      host     ↵│   ping   ↵│  mode ↑ ↵│  state ↓   │            lag_size            ↵│      lag_time     ↵│ reply_ago↵│ start_uptime↵│ hold_wal_size↵│  slot_name ↵│  slot_type ↵│
│         │         │  parent_addr   │      addr      │ time_diff │ priority │            │  send+write+flush+replay=total  │ write<flush<replay │ feedback  │ load_uptime  │ safe_wal_size │ wal_status  │ active temp │
├─────────┼─────────┼────────────────┼────────────────┼───────────┼──────────┼────────────┼─────────────────────────────────┼────────────────────┼───────────┼──────────────┼───────────────┼─────────────┼─────────────┤
│    1   ↵│ primary │                │ dprs-ent-2    ↵│           │          │            │ SSN:                           ↵│                    │           │    5d 20h 4m↵│               │             │            ↵│
│        ↵│         │                │ 127.0.0.1      │           │          │            │ ANY 1 (biha_node_1,biha_node_2) │                    │           │   3d 23h 40m │               │             │             │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
│    2   ↵│ replica │ dprs-ent-2    ↵│ dprs-ent-1    ↵│ 1ms      ↵│ quorum  ↵│ streaming ↵│ 0 + 0 + 0 + 264 B = 264 B       │ 0 < 0 < 6s 809ms   │ 5s 212ms ↵│  14d 18h 36m↵│ 0            ↵│ biha_node_1↵│ physical   ↵│
│        ↵│         │ 127.0.0.1      │ 192.168.22.104 │         0 │ 1        │ not paused │                                 │                    │ f         │   3d 23h 38m │ 5131 MB       │ reserved    │ t f         │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
│    2   ↵│ replica │ dprs-ent-2    ↵│ dprs-ent-3    ↵│ 1ms      ↵│ async   ↵│ streaming ↵│ 0 + 0 + 0 + 264 B = 264 B       │ 0 < 0 < 6s 810ms   │ 5s 209ms ↵│  21d 18h 56m↵│ 0            ↵│ biha_node_3↵│ physical   ↵│
│        ↵│         │ 127.0.0.1      │ 192.168.22.145 │         0 │ 0        │ not paused │                                 │                    │ f         │   3d 23h 37m │ 5131 MB       │ reserved    │ t f         │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
│    3   ↵│ replica │ dprs-ent-3    ↵│ dprs-ent-4    ↵│ 1ms      ↵│ async   ↵│ streaming ↵│ 0 + 0 + 0 + 264 B = 264 B       │ 0 < 0 < 6s 810ms   │ 5s 304ms ↵│    5d 20h 4m↵│ 0            ↵│ biha_node_4↵│ physical   ↵│
│        ↵│         │ 192.168.22.145 │ 192.168.22.86  │         0 │ 0        │ not paused │                                 │                    │ f         │   5d 19h 57m │ 52 GB         │ reserved    │ t f         │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
└─────────┴─────────┴────────────────┴────────────────┴───────────┴──────────┴────────────┴─────────────────────────────────┴────────────────────┴───────────┴──────────────┴───────────────┴─────────────┴─────────────┘
(4 rows)

Time: 204.150 ms
```

#### :B
```
2026-08-18 11:51:26+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :B
BiHA cluster state and config (at 2026-08-18 11:51:49+00)
┌────────────────┬─────────────────────────────────┐
│    function    │             return              │
├────────────────┼─────────────────────────────────┤
│ now()          │ 2026-08-18 11:51:49+00          │
│ biha.get_ssn() │ ANY 1 (biha_node_1,biha_node_2) │
└────────────────┴─────────────────────────────────┘
(2 rows)

Time: 0.935 ms
                                                                         BiHA cluster state and config (at 2026-08-18 11:51:49+00)
┌──────┬──────┬────────────┬────────────┬────────────┬──────────────┬─────────┬────────────────┬──────────────┬──────────┬───────────┬────────────┬───────────────────┬───────────────┬────────────────────┐
│ id ↓ │ term │    host   ↵│ biha_state↵│  pg_state ↵│ referee_mode↵│ last_hb↵│ hb_send_period↵│  pref_roles ↵│ priority↵│  nquorum ↵│  minnodes ↵│ sync_standbys_min↵│ can_be_leader↵│ no_wal_on_follower↵│
│      │      │    name    │ last_known │ conn_state │ service_mode │ online  │  hb_max_lost   │ max_replicas │ (delay)  │ (on fail) │ (for L rw) │  (for L commit)   │   can_vote    │     (timeout)      │
├──────┼──────┼────────────┼────────────┼────────────┼──────────────┼─────────┼────────────────┼──────────────┼──────────┼───────────┼────────────┼───────────────────┼───────────────┼────────────────────┤
│  1  ↵│   34 │ dprs-ent-1 │ FOLLOWER   │ Recovery  ↵│ regular     ↵│ 1s 60ms↵│ 1000 ms       ↵│ L           ↵│ 100 ms   │         2 │          2 │                -1 │ t            ↵│ 500000 ms          │
│     ↵│      │            │            │ ACTIVE     │ f            │ t       │ 10             │            2 │          │           │            │                   │ t             │                    │
│      │      │            │            │            │              │         │                │              │          │           │            │                   │               │                    │
│  2  ↵│   34 │ dprs-ent-2 │ LEADER_RW  │            │ regular     ↵│ 1s 60ms↵│ 1000 ms       ↵│ L            │ 300 ms   │         2 │          2 │                -1 │ t            ↵│ 500000 ms          │
│     ↵│      │            │            │            │ f            │ t       │ 10             │              │          │           │            │                   │ t             │                    │
│      │      │            │            │            │              │         │                │              │          │           │            │                   │               │                    │
│  3  ↵│   34 │ dprs-ent-3 │ FOLLOWER   │ Recovery  ↵│ regular     ↵│ 1s 60ms↵│ 1000 ms       ↵│ L            │ 200 ms   │         2 │          2 │                -1 │ t            ↵│ 500000 ms          │
│     ↵│      │            │            │ ACTIVE     │ f            │ t       │ 10             │              │          │           │            │                   │ t             │                    │
│      │      │            │            │            │              │         │                │              │          │           │            │                   │               │                    │
│  4  ↵│   34 │ dprs-ent-4 │ FOLLOWER   │ Recovery  ↵│ regular     ↵│ 1s 60ms↵│ 1000 ms       ↵│ FL           │ 400 ms   │         2 │          2 │                -1 │ t            ↵│ 500000 ms          │
│     ↵│      │            │            │ ACTIVE     │ f            │ t       │ 10             │              │          │           │            │                   │ t             │                    │
│      │      │            │            │            │              │         │                │              │          │           │            │                   │               │                    │
└──────┴──────┴────────────┴────────────┴────────────┴──────────────┴─────────┴────────────────┴──────────────┴──────────┴───────────┴────────────┴───────────────────┴───────────────┴────────────────────┘
(4 rows)

Time: 1.175 ms
```

#### :BB
```
2026-08-18 11:51:49+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :BB
                 BiHA cheat sheet: config settings to management functions mapping (at 2026-08-18 11:51:52+00)
┌────┬────────────────────────────┬─────────────────────────────────┬──────────────────────────────────────────────────────────┐
│  # │       setting_name ↓       │          setting_value          │                   management_functions                   │
├────┼────────────────────────────┼─────────────────────────────────┼──────────────────────────────────────────────────────────┤
│  1 │ *                          │ ./pg_biha/biha.conf             │ biha.add_node(id int, parent_id int) bool               ↵│
│    │                            │                                 │ biha.remove_node(id int) bool                           ↵│
│    │                            │                                 │ biha.set_leader(id int) bool                            ↵│
│    │                            │                                 │ biha.reset_node_error() bool                             │
│  2 │ *.can_vote                 │ true                            │ biha.set_can_vote(id int, can_vote bool) bool            │
│  3 │ *.max_replicas             │ 2147483647                      │ biha.set_max_replicas(id int, value int) bool            │
│  4 │ *.minnodes                 │ 2                               │ biha.set_minnodes(id int, minnodes int) bool             │
│  5 │ *.nquorum                  │ 2                               │ biha.set_nquorum(id int, nquorum int) bool               │
│  6 │ *.preferred_roles          │ L                               │ biha.set_pref_roles(id int, value text) bool             │
│  7 │ *.priority                 │ 300                             │ biha.set_priority(id int, value int) bool                │
│  8 │ *.service_mode             │ false                           │ biha.service_mode(enable bool, force bool) bool          │
│  9 │ biha.asyncaction_timeout   │ 30000                           │ ¤                                                        │
│ 10 │ biha.autorewind            │ off                             │ ¤                                                        │
│ 11 │ biha.autowaltrim           │ on                              │ ¤                                                        │
│ 12 │ biha.callbacks_timeout     │ 10000                           │ ¤                                                        │
│ 13 │ biha.can_be_leader         │ on                              │ biha.set_can_be_leader(id int, can_be_leader bool) bool  │
│ 14 │ biha.flw_ro                │ on                              │ ¤                                                        │
│ 15 │ biha.heartbeat_max_lost    │ 10                              │ biha.set_heartbeat_max_lost(int) bool                    │
│ 16 │ biha.heartbeat_send_period │ 1000                            │ biha.set_heartbeat_send_period(int) bool                 │
│ 17 │ biha.host                  │ dprs-ent-2                      │ ¤                                                        │
│ 18 │ biha.id                    │ 2                               │ ¤                                                        │
│ 19 │ biha.manage_slots_xmin     │ on                              │ ¤                                                        │
│ 20 │ biha.no_wal_on_follower    │ 500000                          │ biha.set_no_wal_on_follower(int) bool                    │
│ 21 │ biha.port                  │ 5435                            │ ¤                                                        │
│ 22 │ biha.proxima_status        │ 0                               │ biha.enable_proxima() bool                              ↵│
│    │                            │                                 │ biha.disable_proxima() bool                              │
│ 23 │ biha.ssl_certificate       │ ./pg_biha/biha_pub_cert.pem     │ ¤                                                        │
│ 24 │ biha.ssl_mode              │ ¤                               │ ¤                                                        │
│ 25 │ biha.ssl_private_key       │ ./pg_biha/biha_priv_key.pem     │ ¤                                                        │
│ 26 │ biha.use_ssl               │ off                             │ ¤                                                        │
│ 27 │ biha.user_biha_cert        │ ¤                               │ ¤                                                        │
│ 28 │ biha.user_biha_key         │ ¤                               │ ¤                                                        │
│ 29 │ biha.wal_validation        │ on                              │ ¤                                                        │
│ 30 │ biha.watchdog_timeout      │ 2                               │ ¤                                                        │
│ 31 │ synchronous_standby_names  │ ANY 1 (biha_node_1,biha_node_2) │ biha.get_ssn() text                                     ↵│
│    │                            │                                 │ biha.set_sync_standbys(ANY int) bool                    ↵│
│    │                            │                                 │ biha.set_sync_standbys_min(MIN int) bool /* -1 to off */↵│
│    │                            │                                 │ biha.set_ssn(VARIADIC ids int) bool                     ↵│
│    │                            │                                 │ biha.add_to_ssn(id int) returns bool                    ↵│
│    │                            │                                 │ biha.remove_from_ssn(id int) bool                        │
└────┴────────────────────────────┴─────────────────────────────────┴──────────────────────────────────────────────────────────┘
(31 rows)

Time: 2.853 ms
```

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
* https://wiki.postgresql.org/wiki/Psqlrc
* [Как использовать `pspg`, видео на русском языке](https://pgconf.ru/talk/1589147)
