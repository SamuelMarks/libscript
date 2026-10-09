#!/bin/sh
# ## Overview
# Abstracts reading logs for a given service across OSes.
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/logs_service.sh"
# read_logs "$*" "postgresql" "/var/log/postgresql/postgresql.log"

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

read_logs() {
    ACTION="$1"
    SVC_NAME="$2"
    shift 2
    LOG_FILES="$*"

    OS_NAME=$(uname -s)
    
    # Check physical log files first if they exist
    set +f
    for f in $LOG_FILES; do
        for expanded_f in $f; do
            if [ -f "$expanded_f" ]; then
                set -f
                if [ "$ACTION" = "tail -f" ]; then
                    tail -f "$expanded_f"
                    return 0
                else
                    tail -n 100 "$expanded_f"
                    return 0
                fi
            fi
        done
    done
    set -f

    # OS native logging
    if [ "$OS_NAME" = "Linux" ]; then
        if command -v journalctl >/dev/null 2>&1; then
            if [ "$ACTION" = "tail -f" ]; then
                journalctl -u "$SVC_NAME" -f
            else
                journalctl -u "$SVC_NAME" -n 100
            fi
            return 0
        elif [ -f "/var/log/syslog" ]; then
            if [ "$ACTION" = "tail -f" ]; then
                tail -f /var/log/syslog | grep "$SVC_NAME"
            else
                grep "$SVC_NAME" /var/log/syslog | tail -n 100
            fi
            return 0
        elif [ -f "/var/log/messages" ]; then
            if [ "$ACTION" = "tail -f" ]; then
                tail -f /var/log/messages | grep "$SVC_NAME"
            else
                grep "$SVC_NAME" /var/log/messages | tail -n 100
            fi
            return 0
        fi
    elif [ "$OS_NAME" = "SunOS" ]; then
        if command -v svcs >/dev/null 2>&1; then
            LOGFILE=$(svcs -L "$SVC_NAME" 2>/dev/null || true)
            if [ -n "$LOGFILE" ] && [ -f "$LOGFILE" ]; then
                if [ "$ACTION" = "tail -f" ]; then
                    tail -f "$LOGFILE"
                else
                    tail -n 100 "$LOGFILE"
                fi
                return 0
            fi
        fi
    elif [ "$OS_NAME" = "FreeBSD" ]; then
        if [ -f "/var/log/messages" ]; then
            if [ "$ACTION" = "tail -f" ]; then
                tail -f /var/log/messages | grep "$SVC_NAME"
            else
                grep "$SVC_NAME" /var/log/messages | tail -n 100
            fi
            return 0
        fi
    elif [ "$OS_NAME" = "Darwin" ]; then
        if [ "$ACTION" = "tail -f" ]; then
            log stream --predicate "process == \"$SVC_NAME\"" 2>/dev/null || tail -f /var/log/system.log | grep -i "$SVC_NAME"
        else
            log show --predicate "process == \"$SVC_NAME\"" --last 100 2>/dev/null || grep -i "$SVC_NAME" /var/log/system.log | tail -n 100
        fi
        return 0
    fi
    
    echo "No logs found for $SVC_NAME."
    return 1
}
