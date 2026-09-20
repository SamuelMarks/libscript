#!/bin/sh
# ## Overview
# Diagnostic healthcheck helper utility for Open edX.
# Validates connectivity and responsiveness across databases, caches, and web services.
#
# ## Usage
# ./stacks/cms/openedx/health_helper.sh <is_json> <lms_h> <lms_p> <cms_h> <cms_p> <my_h> <my_p> <mg_h> <mg_p> <rd_h> <rd_p> <me_h> <me_p> <sm_h> <sm_p>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

# ## show_help
# Displays usage instructions.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <is_json> <lms_h> <lms_p> <cms_h> <cms_p> <my_h> <my_p> <mg_h> <mg_p> <rd_h> <rd_p> <me_h> <me_p> <sm_h> <sm_p>"
  exit 0
}

# ## test_tcp
# Tests whether a TCP port is open.
#
# Inputs:
#   $1 - Host
#   $2 - Port
test_tcp() {
  _host="$1"
  _port="$2"
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w 1 "${_host}" "${_port}" >/dev/null 2>&1; then
      printf 'OK'
      return 0
    fi
  elif command -v curl >/dev/null 2>&1; then
    if curl -s --connect-timeout 1 "telnet://${_host}:${_port}" >/dev/null 2>&1 || [ $? -eq 49 ] || [ $? -eq 52 ]; then
      printf 'OK'
      return 0
    fi
  fi
  printf 'FAIL'
  return 1
}

# ## test_http
# Tests an HTTP endpoint for reachability.
#
# Inputs:
#   $1 - URL
test_http() {
  _url="$1"
  if command -v curl >/dev/null 2>&1; then
    _code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "${_url}" 2>/dev/null || printf '000')
    case "${_code}" in
      200|301|302|401|403)
        printf 'OK (%s)' "${_code}"
        return 0
        ;;
      *)
        printf 'FAIL (%s)' "${_code}"
        return 1
        ;;
    esac
  fi
  printf 'FAIL'
  return 1
}

# ## main
# Main entrypoint parsing endpoint arguments and executing diagnostics.
main() {
  if [ $# -lt 15 ]; then
    show_help
  fi

  _is_json="$1"
  _lms_h="$2"; _lms_p="$3"
  _cms_h="$4"; _cms_p="$5"
  _my_h="$6";  _my_p="$7"
  _mg_h="$8";  _mg_p="$9"
  _rd_h="${10}"; _rd_p="${11}"
  _me_h="${12}"; _me_p="${13}"
  _sm_h="${14}"; _sm_p="${15}"

  _mysql=$(test_tcp "${_my_h}" "${_my_p}" || true)
  _mongo=$(test_tcp "${_mg_h}" "${_mg_p}" || true)
  _redis=$(test_tcp "${_rd_h}" "${_rd_p}" || true)
  _meili=$(test_http "http://${_me_h}:${_me_p}/health" || true)
  _lms=$(test_http "http://${_lms_h}:${_lms_p}/" || true)
  _cms=$(test_http "http://${_cms_h}:${_cms_p}/signin" || true)
  _workers="WARN (inactive)"
  _smtp=$(test_tcp "${_sm_h}" "${_sm_p}" || true)
  if [ "${_smtp}" = "FAIL" ]; then
    _smtp="WARN (offline)"
  fi

  _fails=0
  for _res in "${_mysql}" "${_mongo}" "${_redis}" "${_meili}" "${_lms}" "${_cms}"; do
    case "${_res}" in
      FAIL*) _fails=$((_fails + 1)) ;;
    esac
  done

  if [ "${_is_json}" = "1" ]; then
    _status="healthy"
    if [ $_fails -gt 0 ]; then
      _status="degraded"
    fi
    cat <<EOF
{
  "status": "${_status}",
  "failures": ${_fails},
  "services": {
    "mysql": "${_mysql}",
    "mongodb": "${_mongo}",
    "redis": "${_redis}",
    "meilisearch": "${_meili}",
    "lms": "${_lms}",
    "cms": "${_cms}",
    "workers": "${_workers}",
    "smtp": "${_smtp}"
  }
}
EOF
  else
    printf '========================================================================
'
    printf '               Open edX Full-Stack Health Diagnostics                   
'
    printf '========================================================================
'
    printf '%-20s %-32s %-16s
' "SERVICE" "TARGET ENDPOINT" "STATUS"
    printf '%-20s %-32s %-16s
' "--------------------" "--------------------------------" "----------------"
    printf '%-20s %-32s %-16s
' "MySQL" "${_my_h}:${_my_p}" "${_mysql}"
    printf '%-20s %-32s %-16s
' "MongoDB" "${_mg_h}:${_mg_p}" "${_mongo}"
    printf '%-20s %-32s %-16s
' "Redis" "${_rd_h}:${_rd_p}" "${_redis}"
    printf '%-20s %-32s %-16s
' "Meilisearch" "http://${_me_h}:${_me_p}" "${_meili}"
    printf '%-20s %-32s %-16s
' "LMS Web" "http://${_lms_h}:${_lms_p}/" "${_lms}"
    printf '%-20s %-32s %-16s
' "Studio Web" "http://${_cms_h}:${_cms_p}/signin" "${_cms}"
    printf '%-20s %-32s %-16s
' "Celery Workers" "celery-lms, cms-worker" "${_workers}"
    printf '%-20s %-32s %-16s
' "SMTP Mail Relay" "${_sm_h}:${_sm_p}" "${_smtp}"
    printf '========================================================================
'
    if [ $_fails -eq 0 ]; then
      printf '[SUCCESS] All Open edX core services and endpoints are healthy.
'
    else
      printf '[WARN] Healthcheck detected %d degraded or offline service(s).
' "$_fails"
    fi
  fi

  if [ $_fails -gt 0 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
