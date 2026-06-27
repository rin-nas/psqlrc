# TODO

## Приоритет 1
* если pg_is_in_backup(), то вывести pg_backup_start_time() и сколько времени прошло
* для флага `psql -q` не выполнять лишних действий к ФС и запросов к СУБД

## Приоритет 2
* для data_directory вывести Size Used Avail Use%
* https://postgrespro.ru/docs/postgrespro/current/functions-admin


```sql
SELECT *
FROM pg_stat_replication,
(select nullif(setting, '') from pg_settings where name = 'synchronous_commit') AS synchronous_commit,
COALESCE(
    CASE synchronous_commit
      WHEN 'remote_apply' THEN pg_current_wal_flush_lsn() - replay_lsn
      WHEN 'on'           THEN pg_current_wal_flush_lsn() - flush_lsn
      WHEN 'remote_write' THEN pg_current_wal_flush_lsn() - write_lsn
      ELSE NULL
    END
) AS lag_size,
COALESCE(
    CASE synchronous_commit
      WHEN 'remote_apply' THEN replay_lag
      WHEN 'on'           THEN flush_lag
      WHEN 'remote_write' THEN write_lag
      ELSE NULL
    END 
) AS lag_time
```