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
red='\e[1;31m'
green='\e[0;32m'
yellow='\e[38;5;220m'
blue='\e[38;5;39m'
orange='\e[38;5;214m'
magenta='\e[0;35m'
cyan='\e[0;36m'
gray='\e[0;37m'
white='\e[1;37m'
reset='\e[0m'

# colored messages
echoerr()  { echo -e "${red}ERROR: $@${reset}"      1>&2; } # ошибки
echowarn() { echo -e "${orange}WARNING: $@${reset}" 1>&2; } # предупреждения
echohint() { echo -e "${yellow}HINT: $@${reset}"    1>&2; } # подсказки
echohead() { echo -e "${blue}$@${reset}"  ; } # заголовок или этап
echoinfo() { echo -e "${white}$@${reset}" ; } # важные сообщения
echosucc() { echo -e "${green}$@${reset}" ; } # сообщения об успехе

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

CUR_DIR=$(pwd)
CUR_LOG_FILES="$CUR_DIR/current_logfiles"
if test ! -f "$CUR_LOG_FILES"; then
    echoerr "file '$CUR_LOG_FILES' does not exist!"
    echohint "is current directory '$CUR_DIR' PGDATA?"
    exit 1
fi

LOG_FILE=$(cat "$CUR_LOG_FILES" | grep csvlog | cut -d' ' -f2)
if test -z "$LOG_FILE"; then
    echoerr "file '$CUR_LOG_FILES': string 'csvlog' does not exist!"
    echohint "check PostgreSQL params logging_collector = 'on', log_destination = 'csvlog'"
    exit 1
elif test ! -f "$LOG_FILE"; then
    echoerr "file '$LOG_FILE' does not exist!"
    echohint "just repeat it, file may be rotated to next one"
    exit 1
fi

if test "$1" -gt 1; then
    LOG_DIR=$(dirname "$LOG_FILE")
    # https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
    FILE=$(ls -1 -U "$LOG_DIR" | grep -P '^postgres.*\.csv(\.[^.]+)?$' | sort -r | tail -n+$1 | head -1)
    test -z "$FILE" && exit 0 # exit if file does not exist
    LOG_FILE="$LOG_DIR/$FILE"
    test ! -f "$LOG_FILE" && exit 0 # exit if file does not exist
fi

LOG_FILE_EXT=$(echo "$LOG_FILE" | grep -oP '\.\K[^.]+$')
# compare [de]compression speed and ratio - https://github.com/rin-nas/postgresql-patterns-library/blob/master/pg_archive_log/README.md
case "$LOG_FILE_EXT" in
    csv)
        test "$1" = 0 && tail -n 1000 "$LOG_FILE" || cat "$LOG_FILE"; exit ;;
    zst)
        zstdcat "$LOG_FILE"; exit ;;
    lz4)
        lz4cat  "$LOG_FILE"; exit ;;
    xz)
        xzcat   "$LOG_FILE"; exit ;;
    bz3)
        bz3cat  "$LOG_FILE"; exit ;;
    gz)
        zcat    "$LOG_FILE"; exit ;;
    *)
        echoerr "file '$LOG_FILE': file extension '$LOG_FILE_EXT' does not support"; exit 1 ;;
esac