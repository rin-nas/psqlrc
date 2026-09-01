# Улучшенное приглашение командной строки в `psql`, информация о сервере СУБД, короткие команды для DBA

## Назначение

Функциональность предназначена для администраторов СУБД [PostgreSQL](https://www.postgresql.org/) и [Postgres Pro](https://postgrespro.ru/).

По умолчанию [`psql`](https://postgrespro.ru/docs/postgresql/current/app-psql) показывает в приглашении командной строки только название текущей базы и всё.
Используя файл [`~/.psqlrc`](https://postgrespro.ru/docs/postgresql/current/app-psql#APP-PSQL-FILES-PSQLRC) можно значительно улучшить приглашение, 
а при запуске `psql` выводить дополнительную полезную информацию для поверхностной оценки состояния сервера СУБД и текущей базы.   

## Что отображается в командной строке `psql`

**Было:**
```
[postgres@redos1 ~]$ psql -q demo
demo=#
```

**Стало:**
```
[postgres@redos1 ~]$ psql -v pro=0 -q demo

2026-06-05 14:43:10+03  postgres@redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=#
```

В первой строке — информация, относящаяся к ОС текущего сервера:
1. текущая дата и время с часовой зоной (в формате [RFC 3339](https://ijmacd.github.io/rfc3339-iso8601/))
1. `user@host[IP_addresses] current_directory`

Во второй строке — информация, относящаяся к СУБД:
1. название сервера, версия; хеш сборки сервера (для `Postgres Pro`)
1. DSN подключения: `user@host:port/database`

Во третьей строке — приглашение для ввода команд `psql` и SQL запросов к СУБД

## Использование

**Интерактивный режим с приглашением командной строки:**
```bash
# подключитесь локально по сокету
psql -v pro=1

# или подключитесь сразу к мастеру
psql -v pro=1 'postgresql://postgres@host-1,host-2,host-3,host-4/postgres?target_session_attrs=read-write&connect_timeout=3'

# только приглашение командной строки без вывода информационных сообщений, предупреждений, ошибок, подсказок,
# без кол-ва строк под таблицами, без времени выполнения запросов (с флагом -q)
psql -v pro=0 -q
```

Значения опции `pro`:

1. `psql -v pro=1` — с вычислением размера директорий для локальных подключений (медленно при большом количестве файлов), игнорируется с флагом `-q`
1. `psql -v pro=0` — без вычисления размера директорий (быстро) и секции **`# OS`**

**Встраивание в `bash` скрипты на примере выполнения коротких команд:**
```bash
psql -v pro=0 -q -f ~/psqlrc/command_T.psql -P title="Cluster topology at ($(date --rfc-3339=seconds | sed 's/:00$//'))" | sed 's/[↵¤]/ /g'

psql -v pro=0 -q -f ~/psqlrc/command_B.psql -P title="BiHA cluster state and config" biha_db | sed 's/[↵¤]/ /g'
```

## Короткие команды для DBA

Короткие команды — это сценарии psql, в которых выполняется один или несколько SQL запросов и выводится результат их выполнения в виде таблиц и/или сообщений.

* `:H` — помощь и полный список коротких команд
* `:W` — информация о текущем пользователе, сессии, схеме и т.д.
* `:A` — агрегированная информация из `pg_stat_activity`.
* `:T` — топология кластера СУБД. Возвращает серверы: мастер и зависимые реплики, включая каскадные.
  Для каждой реплики имеется детализированная информация о размере и длительности отставания от зависимых серверов.
  Запускать лучше на мастере, но это не обязательно.
* `:B` — [BiHA](https://postgrespro.ru/docs/enterprise/current/biha-reference): состояние и конфигурация узлов кластера.
* `:BB` — [BiHA](https://postgrespro.ru/docs/enterprise/current/biha-reference) шпаргалка: сопоставление параметров конфигурации с функциями управления.

Для выполнения команды просто введите её в приглашении `psql` и нажмите клавишу `Enter`.

<details>
<summary>Описание некоторых колонок таблицы для команды :T (показать/скрыть)</summary>

1. `ping` — показывает сетевую задержку между серверами `host` и `parent_host`
1. `time_diff` — показывает разницу во времени между серверами `host` и `parent_host`
1. `reply_ago` — показывает сколько времени прошло с момента последнего ответа реплики
1. `feedback` — показывает значение параметра `hot_standby_feedback`
1. `start_uptime`, `load_uptime` — показывает сколько времени прошло с момента (ре)старта сервера, (пере)загрузки конфигурации сервера
1. `hold_wal_size` — показывает сохранённый размер WAL, удерживаемый слотом (`pg_last_wal_receive_lsn() - pg_replication_slots.restart_lsn`)
1. `safe_wal_size` — показывает предел размера WAL, который ещё можно сохранить на диск до момента потери реплики
</details>

### Предупреждения для значений с отклонениями от нормы

В `psql` при выводе данных в табличном виде выделить текст цветом затруднительно, а рамки таблиц отображаются некорректно.
Поэтому перед «проблемными» значениями показывается знак предупреждения ⚠️.

<details>
<summary>Условия отображения предупреждения ⚠️ с примером для команды :T (показать/скрыть)</summary>

1. если `ping_latency` > 100ms
1. если `ping_time_diff` > 1s
1. если отставание реплики > 100 MB или 30s
1. если `state` отличается от значения "streaming"
1. если `pause_state` отличается от значения "not paused"
1. если версии узлов отличаются
1. и т.д.
</details>

## Поддержка внешнего ПО

Используется пейджер [`pspg`](https://github.com/okbob/pspg), если он установлен.
Иначе используется [`less`](https://en.wikipedia.org/wiki/Less_(Unix)), если он установлен.

Пейджер — важный вспомогательный инструмент при просмотре больших результатов запросов, когда таблицы не помещаются на экране по ширине или длине.
Например, по умолчанию результат простого запроса `select * from pg_stat_activity` обычно не помещается, а таблица «разваливается» с переносами строк.
Пейджер позволяет просматривать таблицу в читабельном виде по частям, прокручивая её влево-вправо и вверх-вниз.

## Инсталляция, обновление, удаление

### ✅ Инсталляция
```bash
sudo su - postgres

# 1) из репозитория скопируйте папку psqlrc в домашнюю папку пользователя postgres, установите владельца и права на папку и файлы 
sudo chown -R postgres: ~/psqlrc
sudo chmod -R 600 ~/psqlrc
sudo chmod 700 ~/psqlrc

# 2) создайте символическую ссылку
ln -sv ~/psqlrc/main.psql ~/.psqlrc

# 3) добавьте служебные объекты в схему "pro"
psql -v pro=0 -q -f ~/psqlrc/command_INSTALL.psql postgres
psql -v pro=0 -q -f ~/psqlrc/command_INSTALL.psql biha_db  # для BiHA, при наличии

# 4) при необходимости, проверьте возможность удалённой аутентификации для пользователя postgres на каждом сервере кластера (см. файлы "~/.pgpass" и "pg_hba.conf")
```

### 🆙 Обновление на новую версию

```bash
sudo su - postgres

# 1) переименуйте старую папку psqlrc
mv ~/psqlrc ~/psqlrc.$(date +%Y-%m-%d.%H%M%S)

# 2) из репозитория скопируйте папку psqlrc в домашнюю папку пользователя postgres, установите владельца и права на папку и файлы 
sudo chown -R postgres: ~/psqlrc
sudo chmod -R 600 ~/psqlrc
sudo chmod 700 ~/psqlrc

# 3) обновите служебные объекты в схеме "pro"
psql -v pro=0 -q -f ~/psqlrc/command_REINSTALL.psql postgres
psql -v pro=0 -q -f ~/psqlrc/command_REINSTALL.psql biha_db  # для BiHA, при наличии
```

### ❌ Удаление

```bash
sudo su - postgres

# 1) удалите служебные объекты в схеме "pro"
psql -v pro=0 -q -f ~/psqlrc/command_UNINSTALL.psql postgres
psql -v pro=0 -q -f ~/psqlrc/command_UNINSTALL.psql biha_db  # для BiHA, при наличии

# 2) удалите папку psqlrc и символическую ссылку
rm -R ~/psqlrc && rm ~/.psqlrc 
```

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

## Валидация при запуске `psql`

1. Отображаются ошибки в конфигурационном файле `postgresql.conf`, если такие имеются.
   Выводится название конфигурационного файла, номера строк, название параметра, текст ошибки.
1. Отображаются ошибки в конфигурационном файле `pg_hba.conf`, если такие имеются. 
   Выводится название конфигурационного файла, номера строк, название параметра, текст ошибки.

## Примеры

Примеры могут быть не полностью актуальными, т.к. функциональность развивается быстрее, чем создаются примеры. 

### Автономная СУБД

<details>
<summary>Без применения .psqlrc (показать/скрыть)</summary>

```
[postgres@redos1 ~]$ psql demo
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
</details>

<details>
<summary>С применением .psqlrc (показать/скрыть)</summary>

```
[postgres@redos1 ~]$ psql -v pro=1 demo
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

# SHORT COMMANDS
:H — Help and full list short commands

psql (18.3, server 17.9)
Type "help" for help.


2026-06-05 14:43:10+03  postgres@redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=# \d+
                                    List of relations
┌────────┬──────────┬────────┬──────────┬─────────────┬───────────────┬───────┬─────────────┐
│ Schema │   Name   │  Type  │  Owner   │ Persistence │ Access method │ Size  │ Description │
├────────┼──────────┼────────┼──────────┼─────────────┼───────────────┼───────┼─────────────┤
│ public │ my_table │ table  │ postgres │ permanent   │ heap          │ 16 kB │ ¤           │
└────────┴──────────┴────────┴──────────┴─────────────┴───────────────┴───────┴─────────────┘
(1 row)


2026-06-05 14:48:59+03  postgres@redos1[192.168.23.239] /var/lib/pgsql
Postgres Pro (enterprise) 17.9.2 c3d046b75bf  postgres@[local]:5432/demo
=# 
```
</details>

### Кластерная СУБД

<details>
<summary>С применением .psqlrc, мастер (показать/скрыть)</summary>

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

# SHORT COMMANDS
:H — Help and full list short commands

psql (18.3)
Type "help" for help.


2026-06-05 14:46:52+03  postgres@sdm18-1[192.168.22.146] /home/postgres
Postgres Pro (shardman) 18.3.3 fbc0896965c  postgres@[local]:5432/postgres
=# 
```
</details>

<details>
<summary>С применением .psqlrc, реплика (показать/скрыть)</summary>

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

# SHORT COMMANDS
:H — Help and full list short commands

psql (18.3)
Type "help" for help.


2026-06-05 14:46:23+03  postgres@sdm18-4[192.168.22.141] /home/postgres
Postgres Pro (shardman) 18.3.3 fbc0896965c  postgres@[local]:5432/postgres
=# 
```
</details>

### Короткие команды

<details>
<summary>:W (показать/скрыть)</summary>

```
2026-08-18 11:51:52+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :W
                                                  Who am I (at 2026-08-18 11:54:05+00)
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

</details>

<details>
<summary>:A (показать/скрыть)</summary>

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
</details>

<details>
<summary>:T (показать/скрыть)</summary>

```
postgres@dprs-ent-2:~$ psql -v pro=0 -q -f ~/psqlrc/command_T.psql -P title="Cluster topology at ($(date --rfc-3339=seconds | sed 's/:00$//'))" | sed 's/[↵¤]/ /g'
                                                                                      Cluster topology at (2026-08-22 19:47:37+00)
┌─────────┬─────────┬────────────────┬────────────────┬───────────┬──────────┬────────────┬─────────────────────────────────┬────────────────────┬───────────┬──────────────┬───────────────┬─────────────┬─────────────┐
│ level ↓ │  role   │  parent_host   │      host      │   ping    │  mode ↑  │  state ↓   │            lag_size             │      lag_time      │ reply_ago │ start_uptime │ hold_wal_size │  slot_name  │  slot_type  │
│         │ version │  parent_addr   │      addr      │ time_diff │ priority │            │  send+write+flush+replay=total  │ write<flush<replay │ feedback  │ load_uptime  │ safe_wal_size │ wal_status  │ active temp │
├─────────┼─────────┼────────────────┼────────────────┼───────────┼──────────┼────────────┼─────────────────────────────────┼────────────────────┼───────────┼──────────────┼───────────────┼─────────────┼─────────────┤
│    1    │ primary │                │ dprs-ent-2     │           │          │            │ SSN: ANY 1 (biha_node_1         │                    │           │   10d 3h 55m │               │             │             │
│         │ 18.4.1  │                │ 192.168.20.152 │           │          │            │ ,biha_node_2)                   │                    │           │    8d 7h 31m │               │             │             │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
│    2    │ replica │ dprs-ent-2     │ dprs-ent-1     │ 1ms       │ quorum   │ streaming  │ 0 + 0 + 0 + 224 B = 224 B       │ 0 < 0 < 6s 9ms     │ 2s 522ms  │   19d 2h 27m │ 0             │ biha_node_1 │ physical    │
│         │ 18.4.1  │ 192.168.20.152 │ 192.168.22.104 │       3ms │ 1        │ not paused │                                 │                    │ f         │    8d 7h 29m │ 5134 MB       │ reserved    │ t f         │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
│    2    │ replica │ dprs-ent-2     │ dprs-ent-3     │ 1ms       │ async    │ streaming  │ 0 + 0 + 0 + 224 B = 224 B       │ 0 < 1ms < 6s 9ms   │ 2s 513ms  │   26d 2h 47m │ 0             │ biha_node_3 │ physical    │
│         │ 18.4.1  │ 192.168.20.152 │ 192.168.22.145 │       5ms │ 0        │ not paused │                                 │                    │ f         │    8d 7h 27m │ 5134 MB       │ reserved    │ t f         │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
│    3    │ replica │ dprs-ent-3     │ dprs-ent-4     │ 1ms       │ async    │ streaming  │ 0 + 0 + 0 + 224 B = 224 B       │ 0 < 0 < 6s 9ms     │ 2s 629ms  │   10d 3h 54m │ 0             │ biha_node_4 │ physical    │
│         │ 18.4.1  │ 192.168.22.145 │ 192.168.22.86  │       8ms │ 0        │ not paused │                                 │                    │ f         │   10d 3h 47m │ 52 GB         │ reserved    │ t f         │
│         │         │                │                │           │          │            │                                 │                    │           │              │               │             │             │
└─────────┴─────────┴────────────────┴────────────────┴───────────┴──────────┴────────────┴─────────────────────────────────┴────────────────────┴───────────┴──────────────┴───────────────┴─────────────┴─────────────┘
```
</details>

<details>
<summary>:B (показать/скрыть)</summary>

```
postgres@dprs-ent-2:~$ psql -v pro=0 -q -f ~/psqlrc/command_B.psql -P title="BiHA cluster state and config" biha_db | sed 's/[↵¤]/ /g'
           BiHA cluster state and config
┌────────────────┬─────────────────────────────────┐
│    function    │             return              │
├────────────────┼─────────────────────────────────┤
│ now()          │ 2026-08-22 19:48:27+00          │
│ biha.get_ssn() │ ANY 1 (biha_node_1,biha_node_2) │
└────────────────┴─────────────────────────────────┘

                                                                                       BiHA cluster state and config
┌──────┬──────┬────────────┬──────────────┬────────────┬──────────────┬─────────┬────────────────┬──────────────┬──────────┬───────────┬────────────┬───────────────────┬───────────────┬────────────────────┐
│ id ↓ │ term │    host    │  biha_state  │  pg_state  │ referee_mode │ last_hb │ hb_send_period │  pref_roles  │ priority │  nquorum  │  minnodes  │ sync_standbys_min │ can_be_leader │ no_wal_on_follower │
│      │      │    name    │  last_known  │ conn_state │ service_mode │ online  │  hb_max_lost   │ max_replicas │ (delay)  │ (on fail) │ (for L rw) │  (for L commit)   │   can_vote    │     (timeout)      │
├──────┼──────┼────────────┼──────────────┼────────────┼──────────────┼─────────┼────────────────┼──────────────┼──────────┼───────────┼────────────┼───────────────────┼───────────────┼────────────────────┤
│  1   │   34 │ dprs-ent-1 │ 🟢 FOLLOWER  │ Recovery   │ regular      │ 820ms   │ 1000 ms        │ L            │ 100 ms   │         2 │          2 │                -1 │ t             │ 500000 ms          │
│      │      │            │              │ ACTIVE     │ f            │ t       │ 10             │            2 │          │           │            │                   │ t             │                    │
│      │      │            │              │            │              │         │                │              │          │           │            │                   │               │                    │
│  2   │   34 │ dprs-ent-2 │ 🟢 LEADER_RW │            │ regular      │ 820ms   │ 1000 ms        │ L            │ 300 ms   │         2 │          2 │                -1 │ t             │ 500000 ms          │
│      │      │            │              │            │ f            │ t       │ 10             │              │          │           │            │                   │ t             │                    │
│      │      │            │              │            │              │         │                │              │          │           │            │                   │               │                    │
│  3   │   34 │ dprs-ent-3 │ 🟢 FOLLOWER  │ Recovery   │ regular      │ 820ms   │ 1000 ms        │ L            │ 200 ms   │         2 │          2 │                -1 │ t             │ 500000 ms          │
│      │      │            │              │ ACTIVE     │ f            │ t       │ 10             │              │          │           │            │                   │ t             │                    │
│      │      │            │              │            │              │         │                │              │          │           │            │                   │               │                    │
│  4   │   34 │ dprs-ent-4 │ 🟢 FOLLOWER  │ Recovery   │ regular      │ 820ms   │ 1000 ms        │ FL           │ 400 ms   │         2 │          2 │                -1 │ t             │ 500000 ms          │
│      │      │            │              │ ACTIVE     │ f            │ t       │ 10             │              │          │           │            │                   │ t             │                    │
│      │      │            │              │            │              │         │                │              │          │           │            │                   │               │                    │
└──────┴──────┴────────────┴──────────────┴────────────┴──────────────┴─────────┴────────────────┴──────────────┴──────────┴───────────┴────────────┴───────────────────┴───────────────┴────────────────────┘
```
Цветной круглый индикатор состояния BiHA:
* 🟡 PRESTARTUP, STARTUP, CSTATE_FORMING, FOLLOWER_OFFERED, CANDIDATE
* ⭕ LEADER_RO
* 🟢 LEADER_RW, FOLLOWER, FRONT_FOLLOWER
* 🔵 REFEREE
* 🔴 NODE_ERROR
* ⚪ UNKNOWN

</details>

<details>
<summary>:BB (показать/скрыть)</summary>

```
2026-08-18 11:51:49+00  postgres@dprs-ent-2[192.168.20.152] /home/postgres
Postgres Pro (enterprise) 18.4.1 2a1f89e2632  postgres@[local]:5432/biha_db
=# :BB
                           BiHA cheat sheet: config settings to management functions mapping (at 2026-08-18 11:51:52+00)
┌────┬────────────────────────────┬───────────────────────────────────────────────────┬────────────────────────────────────────────────────────────┐
│  # │       setting_name ↓       │                   setting_value                  ↵│                    management_functions                    │
│    │                            │                   (curent node)                   │                                                            │
├────┼────────────────────────────┼───────────────────────────────────────────────────┼────────────────────────────────────────────────────────────┤
│  1 │ *                          │ ./pg_biha/biha.conf                               │ biha.add_node(id int, parent_id int) bool                 ↵│
│    │                            │                                                   │ biha.remove_node(id int) bool                             ↵│
│    │                            │                                                   │ biha.set_leader(id int) bool                              ↵│
│    │                            │                                                   │ biha.reset_node_error() bool                               │
│  2 │ *.can_be_leader            │ true                                              │ biha.set_can_be_leader(id int, can_be_leader bool) bool    │
│  3 │ *.can_vote                 │ true                                              │ biha.set_can_vote(id int, can_vote bool) bool              │
│  4 │ *.deny_wal_sources         │ 3, 2                                              │ biha.set_deny_wal_sources(id int, deny_node_id int[]) bool │
│  5 │ *.max_replicas             │ 2147483647                                        │ biha.set_max_replicas(id int, value int) bool              │
│  6 │ *.minnodes                 │ 2                                                 │ biha.set_minnodes(id int, minnodes int) bool               │
│  7 │ *.nquorum                  │ 2                                                 │ biha.set_nquorum(id int, nquorum int) bool                 │
│  8 │ *.preferred_roles          │ L                                                 │ biha.set_pref_roles(id int, value text) bool               │
│  9 │ *.priority                 │ -1                                                │ biha.set_priority(id int, value int) bool                  │
│ 10 │ *.service_mode             │ false                                             │ biha.service_mode(enable bool, force bool) bool            │
│ 11 │ biha.asyncaction_timeout   │ 30000                                             │ ¤                                                          │
│ 12 │ biha.autorewind            │ off                                               │ ¤                                                          │
│ 13 │ biha.autowaltrim           │ on                                                │ ¤                                                          │
│ 14 │ biha.callbacks_timeout     │ 10000                                             │ ¤                                                          │
│ 15 │ biha.flw_ro                │ on                                                │ ¤                                                          │
│ 16 │ biha.heartbeat_max_lost    │ 10                                                │ biha.set_heartbeat_max_lost(int) bool                      │
│ 17 │ biha.heartbeat_send_period │ 1000                                              │ biha.set_heartbeat_send_period(int) bool                   │
│ 18 │ biha.host                  │ dprs-biha181-demo2-11                             │ ¤                                                          │
│ 19 │ biha.id                    │ 1                                                 │ ¤                                                          │
│ 20 │ biha.manage_slots_xmin     │ on                                                │ ¤                                                          │
│ 21 │ biha.no_wal_on_follower    │ 20000                                             │ biha.set_no_wal_on_follower(int) bool                      │
│ 22 │ biha.port                  │ 5435                                              │ ¤                                                          │
│ 23 │ biha.proxima_status        │ 0                                                 │ biha.enable_proxima() bool                                ↵│
│    │                            │                                                   │ biha.disable_proxima() bool                                │
│ 24 │ biha.ssl_certificate       │ ./pg_biha/biha_pub_cert.pem                       │ ¤                                                          │
│ 25 │ biha.ssl_mode              │ ¤                                                 │ ¤                                                          │
│ 26 │ biha.ssl_private_key       │ ./pg_biha/biha_priv_key.pem                       │ ¤                                                          │
│ 27 │ biha.use_ssl               │ off                                               │ ¤                                                          │
│ 28 │ biha.user_biha_cert        │ ¤                                                 │ ¤                                                          │
│ 29 │ biha.user_biha_key         │ ¤                                                 │ ¤                                                          │
│ 30 │ biha.wal_validation        │ on                                                │ ¤                                                          │
│ 31 │ biha.watchdog_timeout      │ 2                                                 │ ¤                                                          │
│ 32 │ synchronous_standby_names  │ ANY 1 MIN 0 (biha_node_1,biha_node_2,biha_node_3) │ biha.get_ssn() text                                       ↵│
│    │                            │                                                   │ biha.set_sync_standbys(ANY int) bool                      ↵│
│    │                            │                                                   │ biha.set_sync_standbys_min(MIN int) bool /* -1 to off */  ↵│
│    │                            │                                                   │ biha.set_ssn(VARIADIC ids int) bool                       ↵│
│    │                            │                                                   │ biha.add_to_ssn(id int) returns bool                      ↵│
│    │                            │                                                   │ biha.remove_from_ssn(id int) bool                          │
└────┴────────────────────────────┴───────────────────────────────────────────────────┴────────────────────────────────────────────────────────────┘
(32 rows)

Time: 2.576 ms
```
</details>

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
* https://wiki.postgresql.org/wiki/Psqlrc
* [Как использовать `pspg`, видео на русском языке](https://pgconf.ru/talk/1589147)
