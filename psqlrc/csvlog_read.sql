
CREATE EXTENSION IF NOT EXISTS file_fdw SCHEMA pro;
CREATE SERVER IF NOT EXISTS file_srv FOREIGN DATA WRAPPER file_fdw;

-- DROP FOREIGN TABLE /*IF EXISTS*/ pro.csvlog_all CASCADE; -- для тестов

CREATE FOREIGN TABLE pro.csvlog_all (
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

CREATE FOREIGN TABLE pro.csvlog_0 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 0 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_1 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_2 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 2 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_3 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 3 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_4 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 4 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_5 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 5 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_6 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 6 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog_7 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh csv 7', format 'csv');

------------------------------------------------------------------------------------------------------------------------

CREATE FOREIGN TABLE pro.log_0 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 0 log', format 'text');

CREATE FOREIGN TABLE pro.log ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 log', format 'text');

CREATE FOREIGN TABLE pro.log_1 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 log', format 'text');

CREATE FOREIGN TABLE pro.log_2 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 2 log', format 'text');

CREATE FOREIGN TABLE pro.log_3 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 3 log', format 'text');

CREATE FOREIGN TABLE pro.log_4 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 4 log', format 'text');

CREATE FOREIGN TABLE pro.log_5 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 5 log', format 'text');

CREATE FOREIGN TABLE pro.log_6 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 6 log', format 'text');

CREATE FOREIGN TABLE pro.log_7 ()
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 7 log', format 'text');

------------------------------------------------------------------------------------------------------------------------

/*
-- Тестирование:
TABLE pro.csvlog_all LIMIT 10; -- выборка данных будет из всех наследуемых таблиц!
SELECT count(*) FROM pro.csvlog_all;
TABLE pro.csvlog LIMIT 10;
TABLE pro.csvlog_2 LIMIT 10;
*/