-- https://postgrespro.ru/docs/enterprise/18/biha-administration#BIHA-CALLBACKS
CREATE OR REPLACE FUNCTION biha.status_changed_log()
    returns void
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
--begin atomic -- 0A000: COPY на данный момент не поддерживается в теле SQL-функции, задаваемом не в кавычках (pg-18)
AS $$
    COPY (
        select json_strip_nulls(to_json(t))::text
        from (
            select
                now()::timestamptz(3) as ts,
                s.*
            from biha.status_v as s
        ) as t
    ) TO PROGRAM '(cat && echo) >> pg_biha/biha.status_changed.$(hostname).$(date +%Y-%m-%d).log';
$$;
--end;

/*
SELECT biha.unregister_callback(id)
FROM biha.callbacks
WHERE (event, func, db, executor) = ('STATUS_CHANGED', 'biha.status_changed_log', 'biha_db', 'postgres');

-- https://postgrespro.ru/docs/enterprise/18/biha-reference#BIHA-REGISTER-CALLBACK-FUNCTION
SELECT biha.register_callback('STATUS_CHANGED', 'biha.status_changed_log', 'biha_db', 'postgres');

-- TEST
SELECT biha.set_leader(11);
SELECT biha.set_leader(12);
*/
