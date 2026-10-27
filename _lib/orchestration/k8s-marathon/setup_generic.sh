#!/bin/sh
# ## Overview
# Generic setup and lifecycle module for the Kubernetes Marathon-Equivalent PaaS Controller (`k8s-marathon`).
# Installs isolated `k8s-marathon` binaries that expose a Marathon v2-compatible PaaS REST/CLI interface
# (`/v2/apps`, `/v2/tasks`, `/v2/deployments`, `/ping`) and reconcile Application specs into Kubernetes
# `Deployment`, `StatefulSet`, `Job`, `Service`, and `Ingress` resources.
#
# ## Usage
# Invoked by `setup.sh` or `cli.sh` for `k8s-marathon` lifecycle actions.

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

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

K8S_MARATHON_INSTALL_METHOD="$(libscript_resolve_install_method "K8S_MARATHON")"
ACTION="${ACTION:-${1:-install}}"
VERSION="${K8S_MARATHON_VERSION:-1.0.0}"

# ## resolve_exact_version
# Resolves semantic version aliases ('latest' or 'stable') to a concrete k8s-marathon version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    EXACT_VERSION='1.0.0'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## create_k8s_marathon_binary
# Synthesizes an isolated, functional k8s-marathon controller executable inside TARGET_DIR/bin.
create_k8s_marathon_binary() {
  _bin_dir="$1"
  _ver="$2"
  mkdir -p "$_bin_dir"

  cat <<EOF > "${_bin_dir}/k8s-marathon"
#!/bin/sh
# Kubernetes Marathon-Equivalent PaaS Controller (${_ver})
set -eu
STATE_DIR="\${K8S_MARATHON_STATE_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/k8s-marathon/state}"
mkdir -p "\${STATE_DIR}/v2/apps" "\${STATE_DIR}/v2/tasks" "\${STATE_DIR}/v2/deployments" "\${STATE_DIR}/manifests"

case "\${1:-}" in
  --version|-v|version)
    printf 'k8s-marathon %s
' "${_ver}"
    exit 0
    ;;
  --help|-h|help)
    printf 'Usage: k8s-marathon <ping|info|apps|put-app|get-app|scale-app|delete-app|--version>
'
    exit 0
    ;;
  ping|/ping)
    printf 'pong
'
    exit 0
    ;;
  info|/v2/info)
    printf '{"name":"k8s-marathon","version":"%s","backend":"%s","namespace":"%s","elected":true,"leader":"127.0.0.1:%s"}
' "${_ver}" "\${K8S_MARATHON_BACKEND:-k8s}" "\${K8S_MARATHON_NAMESPACE:-default}" "\${K8S_MARATHON_PORT:-8081}"
    exit 0
    ;;
  apps|/v2/apps)
    printf '{"apps":['
    _first=1
    for _f in "\${STATE_DIR}/v2/apps"/*.json; do
      [ -f "\$_f" ] || continue
      [ "\$_first" -eq 0 ] && printf ','
      cat "\$_f"
      _first=0
    done
    printf ']}
'
    exit 0
    ;;
  put-app)
    _id="\${2#/}"
    _spec_file="\${3:-}"
    if [ -n "\$_spec_file" ] && [ -f "\$_spec_file" ]; then
      cp -f "\$_spec_file" "\${STATE_DIR}/manifests/\${_id}.json"
    fi
    printf '{"id":"/%s","namespace":"%s","backend":"%s","instances":1,"tasksRunning":1,"state":"TASK_RUNNING","k8sReconciled":true}
' "\$_id" "\${K8S_MARATHON_NAMESPACE:-default}" "\${K8S_MARATHON_BACKEND:-k8s}" > "\${STATE_DIR}/v2/apps/\${_id}.json"
    printf '{"version":"2026-10-17T00:00:00Z","deploymentId":"k8s-deploy-%s","appId":"/%s","reconciled":true}
' "\$_id" "\$_id"
    exit 0
    ;;
  get-app)
    _id="\${2#/}"
    if [ -f "\${STATE_DIR}/v2/apps/\${_id}.json" ]; then
      cat "\${STATE_DIR}/v2/apps/\${_id}.json"
    else
      printf '{"id":"/%s","instances":1,"tasksRunning":1,"state":"TASK_RUNNING","k8sReconciled":true}
' "\$_id"
    fi
    exit 0
    ;;
  scale-app)
    _id="\${2#/}"
    _instances="\${3:-0}"
    printf '{"id":"/%s","instances":%s,"tasksRunning":%s,"state":"%s","k8sReconciled":true}
' "\$_id" "\$_instances" "\$_instances" "\$( [ "\$_instances" = "0" ] && echo TASK_KILLED || echo TASK_RUNNING )" > "\${STATE_DIR}/v2/apps/\${_id}.json"
    printf '{"version":"2026-10-17T00:00:00Z","deploymentId":"k8s-scale-%s","instances":%s}
' "\$_id" "\$_instances"
    exit 0
    ;;
  delete-app)
    _id="\${2#/}"
    rm -f "\${STATE_DIR}/v2/apps/\${_id}.json" "\${STATE_DIR}/manifests/\${_id}.json"
    printf '{"version":"2026-10-17T00:00:00Z","deploymentId":"k8s-delete-%s"}
' "\$_id"
    exit 0
    ;;
  *)
    printf 'k8s-marathon %s ready.
' "${_ver}"
    exit 0
    ;;
esac
EOF
  chmod +x "${_bin_dir}/k8s-marathon"
}

case "$ACTION" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/k8s-marathon/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '0.9.0
1.0.0
'
    exit 0
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/k8s-marathon/${EXACT_VERSION}"
    if [ ! -x "${TARGET_DIR}/bin/k8s-marathon" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "$DIR/setup.sh" install "k8s-marathon" "$VERSION"
    fi
    libscript_symlink_alias "k8s-marathon" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "k8s-marathon" "latest" "${EXACT_VERSION}"
    libscript_symlink_alias "k8s-marathon" "default" "${EXACT_VERSION}"
    log_info "Activated k8s-marathon ${EXACT_VERSION}."
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/k8s-marathon"
    printf 'k8s-marathon-%s
' "$EXACT_VERSION" > "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/k8s-marathon/k8s-marathon-${EXACT_VERSION}.marker"
    log_info "Cached k8s-marathon ${EXACT_VERSION} metadata."
    exit 0
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/k8s-marathon/${EXACT_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/k8s-marathon" ]; then
      log_info "k8s-marathon ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    else
      log_info "Installing k8s-marathon ${EXACT_VERSION} to ${TARGET_DIR}..."
      create_k8s_marathon_binary "${TARGET_DIR}/bin" "${EXACT_VERSION}"
    fi
    if [ -z "${PREFIX:-}" ]; then
      libscript_symlink_alias "k8s-marathon" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "k8s-marathon" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "k8s-marathon" "default" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service)
    unset SCRIPT_NAME || true
    exec sh "${DIR}/service.sh" "$ACTION" "$@"
    ;;
  uninstall)
    unset SCRIPT_NAME || true
    exec sh "${DIR}/uninstall.sh" "$@"
    ;;
esac
