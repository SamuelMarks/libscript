#!/bin/sh
# ## Overview
# Unified Dual-Layer Lifecycle Hook Dispatcher for Tier 1 physical and logical multi-tenant hooks.
#
# ## Usage
# . ./_lib/_common/hooks.sh
# libscript_exec_hook <component_dir> <hook_name> [args...]

set -feu
_hooks_caller_this="${THIS_FILE:-}"; _hooks_caller_dir="${SCRIPT_DIR:-}"

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
    [ -n "$_hooks_caller_this" ] && THIS_FILE="$_hooks_caller_this"
    [ -n "$_hooks_caller_dir" ] && SCRIPT_DIR="$_hooks_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## libscript_resolve_component_dir
# Resolves a component name or relative path to an absolute directory in _lib/.
libscript_resolve_component_dir() {
  comp_arg="${1:-}"
  if [ -d "$comp_arg" ]; then
    (cd -- "$comp_arg" && pwd)
    return 0
  fi
  if [ -d "${LIBSCRIPT_ROOT_DIR}/${comp_arg}" ]; then
    (cd -- "${LIBSCRIPT_ROOT_DIR}/${comp_arg}" && pwd)
    return 0
  fi
  if [ -d "${LIBSCRIPT_ROOT_DIR}/_lib/${comp_arg}" ]; then
    (cd -- "${LIBSCRIPT_ROOT_DIR}/_lib/${comp_arg}" && pwd)
    return 0
  fi
  set +f
  for candidate in "${LIBSCRIPT_ROOT_DIR}/_lib/"*/"${comp_arg}"; do
    if [ -d "$candidate" ]; then
      set -f
      (cd -- "$candidate" && pwd)
      return 0
    fi
  done
  set -f
  return 1
}

# ## libscript_has_hook
# Checks whether the specified component implements a given physical or logical lifecycle hook.
libscript_has_hook() {
  comp_input="${1:-}"
  hook_name="${2:-}"
  if [ -z "$comp_input" ] || [ -z "$hook_name" ]; then
    return 1
  fi
  comp_dir="$(libscript_resolve_component_dir "$comp_input" || true)"
  if [ -z "$comp_dir" ]; then
    return 1
  fi
  if [ -f "${comp_dir}/hooks/${hook_name}.sh" ]; then
    return 0
  fi
  return 1
}

# ## libscript_exec_hook
# Executes a component lifecycle hook with standardized context variables, or safely no-ops if optional.
libscript_exec_hook() {
  comp_input="${1:-}"
  hook_name="${2:-}"
  if [ -z "$comp_input" ] || [ -z "$hook_name" ]; then
    printf '[ERROR] Usage: libscript_exec_hook <component_dir> <hook_name> [args...]\n' >&2
    return 1
  fi
  shift 2

  comp_dir="$(libscript_resolve_component_dir "$comp_input" || true)"
  if [ -z "$comp_dir" ]; then
    printf '[ERROR] Component directory not found for "%s"\n' "$comp_input" >&2
    return 1
  fi

  comp_name="${comp_dir##*/}"
  export LIBSCRIPT_HOOK_ACTION="$hook_name"
  export LIBSCRIPT_COMPONENT_NAME="$comp_name"
  export LIBSCRIPT_INSTANCE_ROOT="${LIBSCRIPT_INSTANCE_ROOT:-${LIBSCRIPT_HOME:-${HOME}/.libscript}/${comp_name}}"
  export LIBSCRIPT_TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  export LIBSCRIPT_TENANT_ID="${LIBSCRIPT_TENANT_ID:-default}"
  export LIBSCRIPT_REMOTE_STRATEGY="${LIBSCRIPT_REMOTE_STRATEGY:-${USER_DB_STRATEGY:-local}}"

  hook_script="${comp_dir}/hooks/${hook_name}.sh"
  if [ ! -f "$hook_script" ]; then
    printf '[DEBUG] Optional hook "%s" not implemented for component "%s"; skipping.\n' "$hook_name" "$comp_name" >&2
    return 0
  fi

  SCRIPT_NAME="$hook_script" sh "$hook_script" "$@"
}

if [ "${1:-}" = "--exec" ]; then
  shift
  libscript_exec_hook "$@"
elif [ "${1:-}" = "--has" ]; then
  shift
  libscript_has_hook "$@"
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_hooks_caller_dir:-}" ] && SCRIPT_DIR="$_hooks_caller_dir"
[ -n "${_hooks_caller_this:-}" ] && THIS_FILE="$_hooks_caller_this"
unset _hooks_caller_this _hooks_caller_dir || true
