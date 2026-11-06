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
escape_text_format() {
    while IFS= read -r LINE; do
        # последовательно меняем символы в текущей строке

        # примеры:
        # LINE="${LINE//-/_}"         # символьный
        # LINE="${LINE//$'\x2d'/_}"   # шестнадцатеричный (Hex)
        # LINE="${LINE//$'\055'/_}"   # восьмеричный (Octal)
        # LINE="${LINE//$'\u002d'/_}" # юникод (UTF-8)

        # https://postgrespro.ru/docs/postgresql/18/sql-copy?lang=en
        LINE="${LINE//\\/$'\x01'}"   # Slash to temp symbol
        LINE="${LINE//$'\b'/\\b}"    # Backspace (ASCII 8)
        LINE="${LINE//$'\f'/\\f}"    # Form feed (ASCII 12)
        LINE="${LINE//$'\n'/\\n}"    # Newline (ASCII 10)
        LINE="${LINE//$'\r'/\\r}"    # Carriage return (ASCII 13)
        LINE="${LINE//$'\t'/\\t}"    # Tab (ASCII 9)
        LINE="${LINE//$'\v'/\\v}"    # Vertical tab (ASCII 11)
        LINE="${LINE//$'\x01'/\\\\}" # Temp symbol to double slash
        echo "$LINE"
    done
}

#------------------------------------------------------------------
if test "$#" -ne 2; then
    echo "Reads current/previous PostgreSQL log file to standard output." >&2
    echo "If log file does not exist, no error throw, just empty output." >&2
    echo "Current log file is uncompressed only." >&2
    echo "Previous log files can be compressed and uncompressed." >&2
    echo "Uncompressed files mask: postgres*.{log,csv}" >&2
    echo "Compressed files mask:   postgres*.{log,csv}.{zst,lz4,xz,bz3,gz}" >&2
    echo >&2
    echoinfo "Usage: $0 NUMBER FORMAT" >&2
    echohead "Parameters:" >&2
    echo "  NUMBER    file ordinal number" >&2
    echo "  FORMAT    one of: log, csv" >&2
    echohead "Examples:" >&2
    echo "  $0 0 log    reads current log file,  log format, tail of 1000 lines" >&2
    echo "  $0 1 log    reads current log file,  log format" >&2
    echo "  $0 2 csv    reads previous log file, csv format" >&2
    echo "  and so on" >&2
    exit 2
elif ! (echo "$1" | grep -qP '^\d+$'); then
    echoerr "digits expected in first parameter, '$1' given"
    exit 2
elif ! (echo "$2" | grep -qP '^(log|csv)$'); then
    echoerr "'log' or 'csv' expected in second parameter, '$2' given"
    exit 2
fi

CUR_DIR=$(pwd)
CUR_LOG_FILES="$CUR_DIR/current_logfiles"
if test ! -f "$CUR_LOG_FILES"; then
    echoerr "file '$CUR_LOG_FILES' does not exist!"
    echohint "check that current directory '$CUR_DIR' is PostgreSQL data directory"
    echohint "check PostgreSQL parameter logging_collector = 'on'"
    exit 1
fi

LOG_FILE_REGEXP="(^|/)postgres[^/]*\.$2(\.[^./]+)?$"
LOG_FILE=$(cat "$CUR_LOG_FILES" | grep -P "$LOG_FILE_REGEXP" | cut -d' ' -f2 || true)
if test -z "$LOG_FILE"; then
    echoerr "file '$CUR_LOG_FILES': regexp '$LOG_FILE_REGEXP' no matches found!"
    echohint "check PostgreSQL parameters logging_collector, log_destination, log_filename"
    exit 1
elif test ! -f "$LOG_FILE"; then
    echoerr "file '$LOG_FILE' does not exist!"
    echohint "just repeat it, file may be rotated to next one"
    exit 1
fi

if test "$1" -gt 1; then
    LOG_DIR=$(dirname "$LOG_FILE")
    # https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
    FILE=$(ls -1 -U "$LOG_DIR" | grep -P "$LOG_FILE_REGEXP" | sort -r | tail -n+$1 | head -1 || true)
    test -z "$FILE" && exit 0 # exit if file does not exist
    LOG_FILE="$LOG_DIR/$FILE"
    test ! -f "$LOG_FILE" && exit 0 # exit if file does not exist
fi

LOG_FILE_EXT=$(echo "$LOG_FILE" | grep -oP '\.\K[^.]+$')
COMMAND=''
case "$LOG_FILE_EXT" in
    log|csv) test "$1" = 0 && COMMAND='tail -n 1000' || COMMAND='cat' ;;
    # compare [de]compression speed and ratio - https://github.com/rin-nas/postgresql-patterns-library/blob/master/pg_archive_log/README.md
    zst) COMMAND='zstdcat' ;;
    lz4) COMMAND='lz4cat'  ;;
    xz)  COMMAND='xzcat'   ;;
    bz3) COMMAND='bz3cat'  ;;
    gz)  COMMAND='zcat'    ;;
    *)   echoerr "file '$LOG_FILE': file extension '$LOG_FILE_EXT' does not support"; exit 1 ;;
esac

$COMMAND "$LOG_FILE" | escape_text_format
