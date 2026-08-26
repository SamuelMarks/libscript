#!/bin/sh
# ## Overview
# Alpine stub for systemctl functionality.
# 
# ## Usage
# Used internally to mock systemd commands on Alpine Linux.

set -e

# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

CMD=$1
SVC=${2%.service}

if [ "$CMD" = "daemon-reload" ] || [ "$CMD" = "enable" ]; then
    exit 0
fi

if [ "$CMD" = "start" ]; then
    # Simple parse of ExecStart (assuming continuation lines with \)
    awk -v svc="$SVC" '
    BEGIN { in_exec = 0; cmd = "" }
    /^ExecStart=/ {
        in_exec = 1;
        sub(/^ExecStart=/, "");
    }
    in_exec {
        line = $0;
        if (line ~ /\\$/) {
            sub(/\\$/, "", line);
            cmd = cmd " " line;
        } else {
            cmd = cmd " " line;
            in_exec = 0;
            # Output the command wrapped in nohup
            print "nohup " cmd " > /var/log/" svc ".log 2>&1 &"
        }
    }
    ' "/etc/systemd/system/${SVC}.service" > "/tmp/start_${SVC}.sh"
    
    sh "/tmp/start_${SVC}.sh"
    exit 0
fi
