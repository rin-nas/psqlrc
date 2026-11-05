
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

CREATE FOREIGN TABLE pro.csvlog0 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 0 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog1 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog2 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 2 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog3 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 3 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog4 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 4 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog5 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 5 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog6 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 6 csv', format 'csv');

CREATE FOREIGN TABLE pro.csvlog7 ()
INHERITS (pro.csvlog_all)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 7 csv', format 'csv');

------------------------------------------------------------------------------------------------------------------------

CREATE FOREIGN TABLE pro.log0 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 0 log', format 'text');

CREATE FOREIGN TABLE pro.log (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 log', format 'text');

CREATE FOREIGN TABLE pro.log1 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 1 log', format 'text');

CREATE FOREIGN TABLE pro.log2 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 2 log', format 'text');

CREATE FOREIGN TABLE pro.log3 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 3 log', format 'text');

CREATE FOREIGN TABLE pro.log4 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 4 log', format 'text');

CREATE FOREIGN TABLE pro.log5 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 5 log', format 'text');

CREATE FOREIGN TABLE pro.log6 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 6 log', format 'text');

CREATE FOREIGN TABLE pro.log7 (line text)
SERVER file_srv
OPTIONS (program 'bash ~postgres/psqlrc/log_read.sh 7 log', format 'text');

------------------------------------------------------------------------------------------------------------------------

/*
-- Тестирование:
TABLE pro.csvlog_all LIMIT 10; -- выборка данных будет из всех наследуемых таблиц!
SELECT count(*) FROM pro.csvlog_all;
TABLE pro.csvlog LIMIT 10;
TABLE pro.csvlog2 LIMIT 10;
*/