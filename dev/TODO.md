# Идеи для доработок

* выводить в топологии в колонке `slot_name` для мастера значение из GUC `primary_slot_name`?
* hot_standby_feedback
* сделать функцию для выполнения SQL запросов на мастере и репликах  
  
* max_wal_size - Максимальный размер, до которого может вырастать WAL во время автоматических контрольных точек. Это мягкий предел; размер WAL может превышать max_wal_size при особых обстоятельствах, например при большой нагрузке, сбое в archive_command/archive_library или при большом значении wal_keep_size.
* wal_keep_size - Задаёт минимальный объём прошлых файлов WAL, который будет сохраняться в каталоге pg_wal, чтобы ведомый сервер мог выбрать их при потоковой репликации.
* max_slot_wal_keep_size - Задаёт максимальный размер файлов WAL, который может оставаться в каталоге pg_wal для слотов репликации после выполнения контрольной точки.

* для `data_directory` вывести Size Used Avail Use%

* [load /etc/hosts to postgres](https://www.google.com/search?client=ubuntu-sn&channel=fs&q=load+%2Fetc%2Fhosts+to+postgres)

Получить команду запуска `psql` с флагами:
```
\echo `ps -p $(ps -p $(echo $$) -o ppid=) -o cmd=`
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


# Ссылки

1. [How to use variables in psql scripts](https://postgres.ai/docs/postgres-howtos/development-tools/psql/how-to-use-variables-in-psql-scripts)

## Цвета:

1. https://misc.flogisoft.com/bash/tip_colors_and_formatting (see `256-colors.sh`)
1. https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
1. https://postgres.ai/docs/postgres-howtos/development-tools/psql/how-to-format-text-output-in-psql-scripts
