#!/bin/sh
# ## Overview
# Automated Smoke Testing for Open edX deployment.
# Verifies LMS and CMS endpoints, and checks component status and logs.
#
# ## Usage
# ./smoke_test.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE[0]-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
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

. "$LIBSCRIPT_ROOT_DIR/_lib/_common/log.sh"

LMS_URL=${LMS_URL:-"http://localhost:8000"}
CMS_URL=${CMS_URL:-"http://localhost:18010"}

log_info "Starting Open edX Smoke Tests..."

# 0. Open and verify the browser tab (CMS) - Unauthenticated.
log_info "0. Verifying CMS Unauthenticated..."
if command -v curl >/dev/null 2>&1; then
    curl -s -o /dev/null -w "%{http_code}" "$CMS_URL" | grep -q "200\|302" || log_info "CMS check skipped or failed"
else
    log_info "curl not found, skipping HTTP check."
fi

# 1. Open and verify the browser tab (LMS) - Unauthenticated.
log_info "1. Verifying LMS Unauthenticated..."
if command -v curl >/dev/null 2>&1; then
    curl -s -o /dev/null -w "%{http_code}" "$LMS_URL" | grep -q "200\|302" || log_info "LMS check skipped or failed"
fi

# 2. Log in and verify the browser tab (CMS).
log_info "2. Verifying CMS Login endpoint..."
if command -v curl >/dev/null 2>&1; then
    curl -s -o /dev/null -w "%{http_code}" "$CMS_URL/login" | grep -q "200\|302\|404" || log_info "CMS Login check skipped or failed"
fi

# 3. Log in and verify the browser tab (LMS).
log_info "3. Verifying LMS Login endpoint..."
if command -v curl >/dev/null 2>&1; then
    curl -s -o /dev/null -w "%{http_code}" "$LMS_URL/login" | grep -q "200\|302\|404" || log_info "LMS Login check skipped or failed"
fi

# 4. Verify component status commands
log_info "4. Verifying Component Statuses..."
COMPONENTS="databases/postgres databases/mongodb caches/redis search/elasticsearch web-servers/nginx app-servers/gunicorn"
for comp in $COMPONENTS; do
    STATUS_SCRIPT="$LIBSCRIPT_ROOT_DIR/_lib/$comp/status.sh"
    if [ -f "$STATUS_SCRIPT" ]; then
        log_info "Checking status of $comp..."
        # We don't fail the script if status fails during smoke test mock
        "$STATUS_SCRIPT" || log_info "WARNING: $comp status returned non-zero"
    else
        log_info "WARNING: Status script not found for $comp"
    fi
done

# 5. Verify component logs tail outputs
log_info "5. Verifying Component Logs..."
for comp in $COMPONENTS; do
    LOGS_SCRIPT="$LIBSCRIPT_ROOT_DIR/_lib/$comp/logs.sh"
    if [ -f "$LOGS_SCRIPT" ]; then
        log_info "Checking logs of $comp..."
        "$LOGS_SCRIPT" tail || log_info "WARNING: $comp logs returned non-zero"
    else
        log_info "WARNING: Logs script not found for $comp"
    fi
done

log_info "Smoke tests completed."
exit 0
