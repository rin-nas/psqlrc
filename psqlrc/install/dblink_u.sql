-- https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/dblink_u.sql
create function pro.dblink_u(connection_str text, sql text, record_definition text)
    returns setof record
    immutable
    returns null on null input
    parallel safe
    SECURITY DEFINER -- so that the invoker user does not have access to dblink()
    language plpgsql
    set search_path = ''
as $$
declare
    conn_name text := 'tmp_conn_' || extract('epoch' from clock_timestamp());
begin
    perform pro.dblink_connect_u(conn_name, connection_str);
    --return next pro.dblink(conn_name, sql); -- throw error
    --return query select * from pro.dblink(conn_name, sql); -- throw error
    return query execute format('select * from pro.dblink($1, $2) as s(%s)', record_definition) using conn_name, sql;
    perform pro.dblink_disconnect(conn_name);
end;
$$;

/*
Если подключиться к СУБД не под суперпользователем и выполнить функцию dblink() без явного указания пароля в строке подключения, то получим ошибку:
    ERROR:  password or GSSAPI delegated credentials required
    DETAIL:  Non-superusers must provide a password in the connection string or send delegated GSSAPI credentials.
Поведение ожидаемое согласно документации: https://postgrespro.ru/docs/postgresql/current/contrib-dblink-connect
*/
comment on function pro.dblink_u(connection_str text, sql text, record_definition text)
    is 'Аналог функции dblink(), но для не суперпользователя позволяет не указывать пароль в строке подключения, а брать его из файла "~postgres/.pgpass"';

-- TEST
-- select * from pro.dblink_u('user=psqlrc_user host=192.168.20.152 port=5432 dbname=postgres', 'select 1', 'f int') as s(f int);