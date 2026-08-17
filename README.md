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

1. systemd unit name (и PID процесса)
1. дата и время, когда был запущен сервер (и сколько времени прошло)
1. дата и время, когда в последний раз сервер загружал файлы конфигурации (и сколько времени прошло)
1. директория с выполняемыми файлами (`bin`) для локального подключения
1. директория с данными (`data_directory`) и её размер для локального подключения
1. директория с протоколами (`log_directory`) и её размер для локального подключения 
1. директория с WAL и её размер для локального подключения; 
   для символической ссылки дополнительно отображается настоящая директория
1. количество подключений текущее, максимальное и сколько использовано в процентах
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

Пример выполнения коротких SQL команд для встраивания в скрипты `bash`:
```bash
psql -v pro=0 -q -c '\echo :T' | psql -v pro=0 -q -P title="Cluster topology at ($(date --rfc-3339=seconds | sed 's/:00$//'))"

psql -v pro=0 -q -c '\echo :B' biha_db | psql -v pro=0 -q -P title="BiHA cluster state and config" biha_db
```

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
# SERVER
Systemd unit:          postgrespro-ent-17.service (pid=643)
Started at:            2026-06-03 16:57:18+03 (1 day 21:45:52 ago)
Config loaded at:      2026-06-05 00:01:06+03 (14:42:04 ago)
Bin directory:         /opt/pgpro/ent-17/bin
Data directory:        /var/lib/pgpro/ent-17/data (size: 2.9G total)
WAL directory:         /var/lib/pgpro/ent-17/data/pg_wal (size: 993M total)
Log directory:         /var/lib/pgpro/ent-17/data/log (size: 2.1M files)
Connections:           12 of 61 (used 20%)
Shared buffers/cache:  7608 kB of 492 MB (used 2%)
Server role:           primary
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
:W - who am i
:A - stat activity groups counts

psql (18.3, server 17.9)
Type "help" for help.


2026-06-05 14:43:10+03:00  postgres@rmukhtarov-redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=# \d+
                                    List of relations
 Schema │   Name   │ Type  │  Owner   │ Persistence │ Access method │ Size  │ Description 
────────┼──────────┼───────┼──────────┼─────────────┼───────────────┼───────┼─────────────
 public │ my_table │ table │ postgres │ permanent   │ heap          │ 16 kB │ ¤
(1 row)


2026-06-05 14:48:59+03:00  postgres@rmukhtarov-redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=# 
```

### Кластерная СУБД

#### С применением `.psqlrc`, мастер

```
postgres@sdm18-1:~$ psql -v pro=1
# SERVER
Systemd unit:          postgrespro-ent-18.service (pid=643)
Started at:            2026-05-06 10:36:04+00 (30 days 01:10:49 ago)
Config loaded at:      2026-05-06 10:36:17+00 (30 days 01:10:36 ago)
Data directory:        /pgdata/keeper-sdm18-test-shard-1-1/postgres (size: 15G total)
WAL directory:         /pgdata/keeper-sdm18-test-shard-1-1/postgres/pg_wal (size: 13G total)
Log directory:         /pgdata (size: 348M files)
Connections:           40 of 1000 (used 4%)
Shared buffers/cache:  13 MB of 2600 MB (used 0%)
Server role:           primary
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
:W - who am i
:A - stat activity groups counts

psql (18.3)
Type "help" for help.


2026-06-05 14:46:52+03:00  postgres@sdm18-1[192.168.22.146] /home/postgres
Postgres Pro (shardman) 18.3.3 fbc0896965c  postgres@[local]:5432/postgres
=# 
```

#### С применением `.psqlrc`, реплика

```
postgres@sdm18-4:~$ psql -v pro=1
# SERVER
Systemd unit:          postgrespro-ent-18.service (pid=643)
Started at:            2026-05-06 10:36:16+00 (30 days 01:10:07 ago)
Config loaded at:      2026-05-06 10:36:23+00 (30 days 01:10:00 ago)
Data directory:        /pgdata/keeper-sdm18-test-shard-1-2/postgres (size: 1.1G total)
WAL directory:         /pgdata/keeper-sdm18-test-shard-1-2/postgres/pg_wal (size: 17M total)
Log directory:         /pgdata (size: 348M files)
Connections:           32 of 1000 (used 3%)
Shared buffers/cache:  2600 MB
Server role:           replica
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
:W - who am i
:A - stat activity groups counts

psql (18.3)
Type "help" for help.


2026-06-05 14:46:23+03:00  postgres@sdm18-4[192.168.22.141] /home/postgres
Postgres Pro (shardman) 18.3.3 fbc0896965c  postgres@[local]:5432/postgres
=# 
```

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
* https://wiki.postgresql.org/wiki/Psqlrc
* [Как использовать `pspg`, видео на русском языке](https://pgconf.ru/talk/1589147)
