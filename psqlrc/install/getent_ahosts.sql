--

CREATE EXTENSION IF NOT EXISTS file_fdw SCHEMA pro;
CREATE SERVER IF NOT EXISTS file_srv FOREIGN DATA WRAPPER file_fdw;

-- DROP FOREIGN TABLE IF EXISTS pro.getent_ahosts;
CREATE FOREIGN TABLE pro.getent_ahosts (line text) SERVER file_srv OPTIONS (program 'getent ahosts', format 'text');

-- natural sort https://www.postgresql.org/docs/15/collation.html#COLLATION-CREATE
-- https://testdouble.com/insights/natural-sorting-postgres-collation
CREATE COLLATION pro.natural_sort (provider = icu, locale = 'en-u-kn-true');
--CREATE COLLATION pro.natural_sort (provider = icu, locale = 'en@colNumeric=yes'); -- alternative?

------------------------------------------------------------------------------------------------------------------------
-- drop function if exists pro.getent_ahosts();

create function pro.getent_ahosts()
    returns table (
        addr         inet,
        host         text,
        is_canonical boolean
    )
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    SECURITY DEFINER
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
begin atomic
    select distinct on (h.host collate pro.natural_sort, a.addr)
           --s.line, -- для отладки
           a.addr,
           h.host,
           h.index = 1 as is_canonical
    from pro.getent_ahosts as s,
         regexp_split_to_array(s.line, '\s+') as p(parts),
         coalesce(p.parts[1]::inet) as a(addr),
         unnest(p.parts[2:]) with ordinality as h(host, index)
    order by h.host collate pro.natural_sort, a.addr, h.index;
end;

comment on function pro.getent_ahosts() is 'Linux command `getent ahosts` result';

--alter function pro.getent_ahosts() owner to postgres;

--TEST
--select * from pro.getent_ahosts();

