#!/bin/bash
# https://habr.com/ru/company/ruvds/blog/325522/ - Bash documentation
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -e - прекращает выполнение скрипта, если команда завершилась ошибкой
# set -u - прекращает выполнение скрипта, если встретилась несуществующая переменная
# set -x - выводит выполняемые команды в stdout перед выполнением (только для отладки, а то замусоривает журнал!)
# set -o pipefail - прекращает выполнение скрипта, даже если одна из частей пайпа завершилась ошибкой
set -euo pipefail
SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FILE")
bash -n "$SCRIPT_FILE" || exit # check syntax this file

# colors
Red='\e[1;31m'
Green='\e[0;32m'
Yellow='\e[38;5;220m'
Blue='\e[38;5;39m'
Orange='\e[38;5;214m'
Magenta='\e[0;35m'
Cyan='\e[0;36m'
Gray='\e[0;37m'
White='\e[1;37m'
Reset='\e[0m'

# colored messages
echoerr()  { echo -e "${Red}$@${Reset}"    1>&2; } # ошибки
echowarn() { echo -e "${Yellow}$@${Reset}" 1>&2; } # предупреждения
echohead() { echo -e "${Blue}$@${Reset}" ; } # заголовок или этап
echoinfo() { echo -e "${White}$@${Reset}" ; } # важные сообщения
echosucc() { echo -e "${Green}$@${Reset}" ; } # сообщения об успехе

#------------------------------------------------------------------
if test "$#" -ne 1; then
    echoinfo "Usage: $0 NUMBER" >&2
    echo "Reads last PostgreSQL log file (.csv, .csv.{zst,lz4,xz,bz3,gz}) to standard output." >&2
    echo "If log file does not exist, no error throw, just empty output." >&2
    echo "Examples:" >&2
    echo "  $0 0    reads last log file, tail of 1000 lines (.csv only)" >&2
    echo "  $0 1    reads last log file (.csv only)" >&2
    echo "  $0 2    reads previous log file (may be compressed), and so on" >&2
    exit 2
elif ! (echo "$1" | grep -qP '^\d+$'); then
    echoerr "Error: digits only expected in first parameter, '$1' given"
    exit 2
fi

LOG_DIR=$(cat current_logfiles | grep csvlog | cut -d' ' -f2 | xargs dirname)
test ! -d "$LOG_DIR" && exit 0 # exit if directory does not exist

if test "$1" -le 1; then
    FILE=$(cat current_logfiles | grep csvlog | cut -d' ' -f2 | xargs basename)
else
    # https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
    FILE=$(ls -1 -U "$LOG_DIR" | grep -P '^postgres.*\.csv(\.[^.]+)?$' | sort -r | tail -n+$1 | head -1)
fi
test ! -f "$LOG_DIR/$FILE" && exit 0 # exit if file does not exist

FILE_EXT=$(echo "$FILE" | grep -oP '\.\K[^.]+$')

# compare [de]compression speed and ratio - https://github.com/rin-nas/postgresql-patterns-library/blob/master/pg_archive_log/README.md
case "$FILE_EXT" in
    csv)
        test "$1" = 0 && tail -n 1000 "$LOG_DIR/$FILE" || cat "$LOG_DIR/$FILE"; exit ;;
    zst)
        zstdcat "$LOG_DIR/$FILE"; exit ;;
    lz4)
        lz4cat  "$LOG_DIR/$FILE"; exit ;;
    xz)
        xzcat   "$LOG_DIR/$FILE"; exit ;;
    bz3)
        bz3cat  "$LOG_DIR/$FILE"; exit ;;
    gz)
        zcat    "$LOG_DIR/$FILE"; exit ;;
    *)
        echoerr "Error: file '$LOG_DIR/$FILE': file extension '$FILE_EXT' does not support"; exit 1 ;;
esac