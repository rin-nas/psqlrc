-- https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/size_pretty.sql
create function pro.size_pretty(bigint)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return
    case when $1 = 0 then '0'
         else replace(pg_size_pretty($1), ' bytes', ' B')
    end;

comment on function pro.size_pretty(bigint) is 'Formats the size to a human readable string';


create function pro.size_pretty(numeric)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return
    case when $1 = 0 then '0'
         else replace(pg_size_pretty($1), ' bytes', ' B')
    end;

comment on function pro.size_pretty(numeric) is 'Formats the size to a human readable string';
