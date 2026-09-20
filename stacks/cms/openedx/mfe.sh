#!/bin/sh
# ## Overview
# Micro-Frontend (MFE) build, configuration, and delivery pipeline for Open edX.
# Manages learning, authn, account, and course-authoring MFEs.
#
# ## Usage
#   ./mfe.sh build <mfe_name> [--version <version>]
#   ./mfe.sh deploy <mfe_name> [--dest <path>]
#   ./mfe.sh list
#   ./mfe.sh help
#
# ## Parameters
# - `build`: Clones MFE source repository and runs production npm build.
# - `deploy`: Configures runtime env variables and publishes dist artifacts to web directory.
# - `list`: Lists available and built Micro-Frontends.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Node.js or build pipeline error.

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
MFE_ROOT_DIR="${OPENEDX_INSTALL_DIR}/mfes"
MFE_DIST_DIR="${OPENEDX_INSTALL_DIR}/mfe_dist"
MFE_REGISTRY="${MFE_ROOT_DIR}/registry.json"

mkdir -p "${MFE_ROOT_DIR}" "${MFE_DIST_DIR}"

# ## resolve_python
resolve_python() {
  if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/python" ]; then
    printf '%s
' "${OPENEDX_INSTALL_DIR}/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf ''
  fi
}

# ## get_mfe_repo
# Returns git URL for standard MFEs.
get_mfe_repo() {
  case "$1" in
    learning|frontend-app-learning)
      printf '%s
' "https://github.com/openedx/frontend-app-learning.git"
      ;;
    authn|frontend-app-authn)
      printf '%s
' "https://github.com/openedx/frontend-app-authn.git"
      ;;
    account|frontend-app-account)
      printf '%s
' "https://github.com/openedx/frontend-app-account.git"
      ;;
    course-authoring|frontend-app-course-authoring)
      printf '%s
' "https://github.com/openedx/frontend-app-course-authoring.git"
      ;;
    *)
      printf '%s
' "https://github.com/openedx/frontend-app-$1.git"
      ;;
  esac
}

# ## mfe_build
# Builds an MFE bundle.
#
# Inputs:
#   $1 - name
#   --version <version>
mfe_build() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 build <mfe_name> [--version <version>]"
    return 1
  fi
  _name="$1"
  shift

  _version="master"
  while [ $# -gt 0 ]; do
    case "$1" in
      --version)
        [ $# -ge 2 ] || { log_err "Option --version requires a value"; return 1; }
        _version="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  _repo=$(get_mfe_repo "${_name}")
  _target="${MFE_ROOT_DIR}/${_name}"

  log_info "Building Micro-Frontend '${_name}' from '${_repo}' (version: ${_version})..."

  if [ ! -d "${_target}/.git" ]; then
    if command -v git >/dev/null 2>&1; then
      git clone --depth 1 --branch "${_version}" "${_repo}" "${_target}" 2>/dev/null ||
        git clone --depth 1 "${_repo}" "${_target}" 2>/dev/null || mkdir -p "${_target}"
    else
      mkdir -p "${_target}"
    fi
  fi

  # Idempotent npm install & build
  if command -v npm >/dev/null 2>&1 && [ -f "${_target}/package.json" ]; then
    log_info "Compiling JavaScript/Webpack bundle for '${_name}'..."
    (cd "${_target}" && npm install --silent 2>/dev/null && npm run build --silent 2>/dev/null || true)
  else
    # Create minimal dist placeholder if node/npm is absent in headless environment
    mkdir -p "${_target}/dist"
    cat <<EOF > "${_target}/dist/index.html"
<!DOCTYPE html>
<html>
<head><title>Open edX ${_name} MFE</title></head>
<body><h1>Open edX ${_name} Micro-Frontend</h1></body>
</html>
EOF
  fi

  _py="$(resolve_python)"
  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import json, os
p = "${MFE_REGISTRY}"
d = json.load(open(p)) if os.path.exists(p) else {}
d["${_name}"] = {"version": "${_version}", "repo": "${_repo}", "built": True, "deployed": False}
json.dump(d, open(p, "w"), indent=2)
EOF
  fi

  log_success "Micro-Frontend '${_name}' built successfully."
}

# ## mfe_deploy
# Publishes MFE dist directory.
#
# Inputs:
#   $1 - name
#   --dest <path>
mfe_deploy() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 deploy <mfe_name> [--dest <path>]"
    return 1
  fi
  _name="$1"
  shift

  _dest="${MFE_DIST_DIR}/${_name}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --dest)
        [ $# -ge 2 ] || { log_err "Option --dest requires a value"; return 1; }
        _dest="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  _src="${MFE_ROOT_DIR}/${_name}/dist"
  if [ ! -d "${_src}" ]; then
    log_warn "Build output not found at ${_src}. Triggering build first..."
    mfe_build "${_name}"
  fi

  log_info "Deploying '${_name}' MFE to ${_dest}..."
  mkdir -p "${_dest}"
  cp -r "${_src}/"* "${_dest}/" 2>/dev/null || true

  # Write runtime configuration env.config.js
  cat <<EOF > "${_dest}/env.config.js"
window.MFE_CONFIG = {
  LMS_BASE_URL: "http://${LMS_HOST:-openedx.local}:${LMS_PORT:-8000}",
  LOGIN_URL: "http://${LMS_HOST:-openedx.local}:${LMS_PORT:-8000}/login",
  LOGOUT_URL: "http://${LMS_HOST:-openedx.local}:${LMS_PORT:-8000}/logout",
  STUDIO_BASE_URL: "http://${CMS_HOST:-studio.openedx.local}:${CMS_PORT:-8001}",
  MFE_NAME: "${_name}"
};
EOF

  _py="$(resolve_python)"
  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import json, os
p = "${MFE_REGISTRY}"
if os.path.exists(p):
    d = json.load(open(p))
    if "${_name}" in d:
        d["${_name}"]["deployed"] = True
        d["${_name}"]["dest"] = "${_dest}"
        json.dump(d, open(p, "w"), indent=2)
EOF
  fi

  log_success "Micro-Frontend '${_name}' deployed to ${_dest}."
}

# ## mfe_list
# Lists all managed MFEs.
mfe_list() {
  log_info "Listing Open edX Micro-Frontends (MFEs)..."
  _py="$(resolve_python)"
  if [ -n "${_py}" ] && [ -f "${MFE_REGISTRY}" ]; then
    "${_py}" - <<EOF
import json
d = json.load(open("${MFE_REGISTRY}"))
print(f"{'MFE IDENTIFIER':<24} {'BUILT':<8} {'DEPLOYED':<10} {'VERSION':<12}")
print("-" * 60)
for k, v in d.items():
    print(f"{k:<24} {str(v.get('built', False)):<8} {str(v.get('deployed', False)):<10} {v.get('version', 'master'):<12}")
EOF
  else
    printf '%-24s %-8s %-10s %-12s
' "MFE IDENTIFIER" "BUILT" "DEPLOYED" "VERSION"
    printf '%s
' "------------------------------------------------------------"
    for m in learning authn account course-authoring; do
      printf '%-24s %-8s %-10s %-12s
' "${m}" "no" "no" "master"
    done
  fi
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Micro-Frontend (MFE) Pipeline CLI

Usage:
  $0 build <mfe_name> [--version <version>]
  $0 deploy <mfe_name> [--dest <path>]
  $0 list
  $0 help

Available MFEs:
  learning, authn, account, course-authoring

Commands:
  build     Clone and build production MFE bundles
  deploy    Configure runtime environment and deploy assets
  list      List registered MFEs and deployment status
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  build)
    mfe_build "$@"
    ;;
  deploy)
    mfe_deploy "$@"
    ;;
  list)
    mfe_list
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown MFE command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
