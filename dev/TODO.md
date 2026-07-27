# Идеи для доработок

* для `data_directory` вывести Size Used Avail Use%
* https://postgrespro.ru/docs/postgrespro/current/functions-admin

Вычисление отставания реплики (размер и длительность), в зависимости от параметра `synchronous_commit`:  
```sql
SELECT *
FROM pg_stat_replication,
(select nullif(trim(setting), '') from pg_settings where name = 'synchronous_commit') AS synchronous_commit,
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

# Ссылки

## Цвета:

1. https://misc.flogisoft.com/bash/tip_colors_and_formatting (see 256-colors.sh)
1. https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
1. https://postgres.ai/docs/postgres-howtos/development-tools/psql/how-to-format-text-output-in-psql-scripts
