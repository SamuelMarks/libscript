#!/bin/sh
# ## Overview
# Provides URL parsing capabilities in pure POSIX `/bin/sh` without external non-POSIX utilities.
# Decomposes a URI into `protocol`, `user`, `pass`, `host`, `port`, and `path`, and exports them.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/url_parser.sh" export SCRIPT_NAME && . "${SCRIPT_NAME}"

set -feu; _url_parser_caller_this="${THIS_FILE:-}"; _url_parser_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    [ -n "$_url_parser_caller_this" ] && THIS_FILE="$_url_parser_caller_this"; [ -n "$_url_parser_caller_dir" ] && SCRIPT_DIR="$_url_parser_caller_dir"; unset SCRIPT_NAME _url_parser_caller_this _url_parser_caller_dir || true; if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *)
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## libscript_url_parser
# Parses a URI string into protocol, user, pass, host, port, and path components using POSIX parameter expansion.
libscript_url_parser() {
  url="${1:-}"
  protocol=""
  user=""
  pass=""
  host=""
  port=""
  path=""
  [ -n "${url}" ] || return 1

  _up_rest="${url}"
  case "${_up_rest}" in
    *://*)
      protocol="${_up_rest%%://*}://"
      _up_rest="${_up_rest#*://}"
      ;;
  esac
  url_no_protocol="${_up_rest}"
  printf 'url_no_protocol="%s"\n' "${url_no_protocol}"

  case "${_up_rest}" in
    */*)
      _up_auth="${_up_rest%%/*}"
      path="${_up_rest#*/}"
      ;;
    *)
      _up_auth="${_up_rest}"
      path=""
      ;;
  esac

  case "${_up_auth}" in
    *@*)
      _up_userpass="${_up_auth%%@*}"
      _up_hostport="${_up_auth#*@}"
      case "${_up_userpass}" in
        *:*)
          user="${_up_userpass%%:*}"
          pass="${_up_userpass#*:}"
          ;;
        *)
          user="${_up_userpass}"
          ;;
      esac
      ;;
    *)
      _up_hostport="${_up_auth}"
      ;;
  esac

  case "${_up_hostport}" in
    *:*)
      host="${_up_hostport%%:*}"
      port="${_up_hostport#*:}"
      ;;
    *)
      host="${_up_hostport}"
      ;;
  esac

  export url protocol user pass host port path
  printf 'protocol = "%s"\n' "${protocol}"
  printf 'host = "%s"\n' "${host}"
  if [ -n "${port}" ]; then printf 'port = %s\n' "${port}"; fi
  printf 'path = "%s"\n' "${path}"
  if [ -n "${user}" ]; then printf 'user = "%s"\n' "${user}"; fi
  unset _up_rest _up_auth _up_userpass _up_hostport || true
}

# ## parse_url
# Alias wrapper around `libscript_url_parser`.
parse_url() {
  libscript_url_parser "$@"
}

# ## git_args_from_url
# Extracts repository base URL and optional branch from a Git URI.
git_args_from_url() {
  libscript_url_parser "${1}" >/dev/null
  if [ -n "${path}" ]; then
    repo="${protocol}${host}/${path}"
  else
    repo="${protocol}${host}"
  fi
  branch="${2:-}"
  export repo branch
  printf '%s\n' "${repo}"
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_url_parser_caller_dir:-}" ] && SCRIPT_DIR="${_url_parser_caller_dir}"
[ -n "${_url_parser_caller_this:-}" ] && THIS_FILE="${_url_parser_caller_this}"
unset SCRIPT_NAME _url_parser_caller_this _url_parser_caller_dir || true
