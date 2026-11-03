-- https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/interval_pretty.sql
create function pro.interval_pretty(interval)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
begin atomic
    select
        case when gi < '1ms'::interval then '0'
             when gi <  '1s'::interval then regexp_replace(to_char($1,                    'FMMS"ms"'), '(?<!\d)0+(?=\d+ms$)', '')
             when gi < '10s'::interval then regexp_replace(to_char($1,            'FMSS"s" FMMS"ms"'), '(?<!\d)0+(?=\d+ms$)', '')
             when gi <  '1m'::interval then to_char($1,                           'FMSS"s"')
             when gi <  '1h'::interval then to_char($1,                   'FMMI"m" FMSS"s"')
             when gi <  '1d'::interval then to_char($1,         'FMHH24"h" FMMI"m"')
             else                           to_char($1, 'FMDD"d" FMHH24"h" FMMI"m"')
        end
    from greatest($1, $1 * -1) as gi;
end;

comment on function pro.interval_pretty(interval) is 'Formats the size interval (time period) to a human readable string';
