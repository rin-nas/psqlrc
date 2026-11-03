
CREATE EXTENSION IF NOT EXISTS file_fdw SCHEMA pro;
CREATE SERVER IF NOT EXISTS file_srv FOREIGN DATA WRAPPER file_fdw;

-- DROP FOREIGN TABLE /*IF EXISTS*/ pro.log_all CASCADE; -- для тестов

CREATE FOREIGN TABLE pro.log_all (
    log_time timestamp(3) with time zone,
    user_name text,
    database_name text,
    process_id integer,
    connection_from text,
    session_id text,
    session_line_num bigint,
    command_tag text,
    session_start_time timestamp with time zone,
    virtual_transaction_id text,
    transaction_id bigint,
    error_severity text,
    sql_state_code text,
    message text,
    detail text,
    hint text,
    internal_query text,
    internal_query_pos integer,
    context text,
    query text,
    query_pos integer,
    location text,
    application_name text,
    backend_type text,
    leader_pid integer, -- PostgreSQL v14+
    query_id bigint     -- PostgreSQL v14+
)
SERVER file_srv
OPTIONS (program 'true', format 'csv');

CREATE FOREIGN TABLE pro.log_0 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 0', format 'csv');

CREATE FOREIGN TABLE pro.log ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 1', format 'csv');

CREATE FOREIGN TABLE pro.log_1 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 1', format 'csv');

CREATE FOREIGN TABLE pro.log_2 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 2', format 'csv');

CREATE FOREIGN TABLE pro.log_3 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 3', format 'csv');

CREATE FOREIGN TABLE pro.log_4 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 4', format 'csv');

CREATE FOREIGN TABLE pro.log_5 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 5', format 'csv');

CREATE FOREIGN TABLE pro.log_6 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 6', format 'csv');

CREATE FOREIGN TABLE pro.log_7 ()
INHERITS (pro.log_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/csvlog_read.sh 7', format 'csv');

/*
-- Тестирование:
TABLE pro.log_all LIMIT 10; -- выборка данных будет из всех наследуемых таблиц!
SELECT count(*) FROM pro.log_all;
TABLE pro.log LIMIT 10;
TABLE pro.log_2 LIMIT 10;
*/