#!/bin/bash
# https://habr.com/ru/company/ruvds/blog/325522/ - Bash documentation
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -e - прекращает выполнение скрипта, если команда завершилась ошибкой
# set -u - прекращает выполнение скрипта, если встретилась несуществующая переменная
# set -x - выводит выполняемые команды в stdout перед выполнением (только для отладки, а то замусоривает журнал!)
# set -o pipefail - прекращает выполнение скрипта, даже если одна из частей пайпа завершилась ошибкой
set -euo pipefail
SCRIPT_FILE=$(readlink -f ~/.psqlrc)
SCRIPT_DIR=$(dirname "$SCRIPT_FILE")
bash -n "$SCRIPT_FILE" || exit # check syntax this file

#-----------------------------------------------------------------------------------------------------------------------
# интерактивный режим с приглашением командной строки

sudo su - postgres

psql -v pro=0 -q biha_db
psql -v pro=0 biha_db
psql -v pro=1 biha_db
psql -v pro=color biha_db

#-----------------------------------------------------------------------------------------------------------------------
# встраивание в bash скрипты

psql -v pro=0 -q -f $SCRIPT_DIR/commands/W.psql -U psqlrc_user psqlrc_db | sed -E -f $SCRIPT_DIR/colorize.sed
psql -v pro=0 -q -f $SCRIPT_DIR/commands/A.psql -U psqlrc_user psqlrc_db | sed -E -f $SCRIPT_DIR/colorize.sed
psql -v pro=0 -q -f $SCRIPT_DIR/commands/T.psql -U psqlrc_user psqlrc_db | sed -E -f $SCRIPT_DIR/colorize.sed
psql -v pro=0 -q -f $SCRIPT_DIR/commands/B.psql -U biha_replication_user biha_db | sed -E -f $SCRIPT_DIR/colorize.sed
psql -v pro=0 -q -f $SCRIPT_DIR/commands/TB.psql -U biha_replication_user biha_db | sed -E -f $SCRIPT_DIR/colorize.sed
psql -v pro=0 -v emoji=0 -q -f $SCRIPT_DIR/commands/TB.psql -U biha_replication_user biha_db | sed -E -f $SCRIPT_DIR/colorize.sed

