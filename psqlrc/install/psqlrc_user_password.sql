drop function if exists pro.psqlrc_user_password();

create function pro.psqlrc_user_password()
    returns text
    immutable
    returns null on null input
    parallel safe
    SECURITY DEFINER -- superuser
    language sql
    set search_path = ''
begin atomic
    select t.password
    from pro.read_pgpass(pro.os_home_dir('postgres') || '/.pgpass') as t
    where t.username = 'psqlrc_user';
end;

comment on function pro.psqlrc_user_password() is 'Returns password for user "psqlrc_user" from file "~postgres/.pgpass"';
