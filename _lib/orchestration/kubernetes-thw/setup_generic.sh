#!/bin/sh
# ## Overview
# Generic setup module for kubernetes-thw.
# 
# ## Usage
# Execute this script to perform generic initialization steps for kubernetes-thw.

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

KUBERNETES_THW_INSTALL_METHOD="$(libscript_resolve_install_method "KUBERNETES_THW")"
ACTION="${ACTION:-install}"
VERSION="${KUBERNETES_THW_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote kubernetes-thw 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "kubernetes-thw" "$ACTION" "$VERSION" "${KUBERNETES_THW_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${KUBERNETES_THW_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${KUBERNETES_THW_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/kubernetes/kubernetes" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "kubernetes-thw" "$ACTION" "$VERSION" "${KUBERNETES_THW_INSTALL_METHOD}"
    ;;
  download)
    if [ "$KUBERNETES_THW_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading kubernetes-thw ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-thw..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-thw"
      if [ -n "${KUBERNETES_THW_DOWNLOAD_URL:-}" ]; then
        libscript_download "${KUBERNETES_THW_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-thw/kubernetes-thw-${VERSION}.tar.gz"
      else
        log_warn "KUBERNETES_THW_DOWNLOAD_URL is not defined for kubernetes-thw ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$KUBERNETES_THW_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'kubernetes-thw'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/kubernetes-thw/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing kubernetes-thw ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-thw/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-thw/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/kubernetes-thw" || true
              chmod +x "${TARGET_DIR}/bin/kubernetes-thw" || true
            fi
          fi
        else
          libscript_depends 'curl' 'tar'
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi
          OS=$(uname -s | tr "[:upper:]" "[:lower:]")
          if [ "$OS" != "linux" ]; then
             log_error 'kubernetes-thw components are currently only compiled for linux in this script.'
             exit 1
          fi

          if [ "${EXACT_VERSION}" = "latest" ]; then
             EXACT_VERSION='v1.32.3'
          elif ! echo "${EXACT_VERSION}" | grep -q "^v"; then
             EXACT_VERSION="v${EXACT_VERSION}"
          fi
          
          # Following KTHW component versions roughly matching K8s 1.32.3
          CRICTL_VERSION='v1.32.0'
          RUNC_VERSION='v1.3.0-rc.1'
          CNI_VERSION='v1.6.2'
          CONTAINERD_VERSION='v2.1.0-beta.0'
          ETCD_VERSION='v3.6.0-rc.3'

          log_info 'Downloading Kubernetes The Hard Way binaries...'
          
          # Download standalone binaries
          for bin in kubectl kube-apiserver kube-controller-manager kube-scheduler kube-proxy kubelet; do
             URL="https://dl.k8s.io/${EXACT_VERSION}/bin/linux/${ARCH}/${bin}"
             libscript_download "$URL" "${TARGET_DIR}/bin/${bin}" || log_error "Failed to download ${bin}"
             chmod +x "${TARGET_DIR}/bin/${bin}" || true
          done

          # Download and rename runc
          URL="https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${ARCH}"
          libscript_download "$URL" "${TARGET_DIR}/bin/runc" || log_error "Failed to download runc"
          chmod +x "${TARGET_DIR}/bin/runc" || true

          # Download and extract tarballs
          TEMP_DIR=$(mktemp -d)
          
          # crictl
          URL="https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"
          libscript_download "$URL" "${TEMP_DIR}/crictl.tar.gz" || log_error "Failed to download crictl"
          tar -xzf "${TEMP_DIR}/crictl.tar.gz" -C "${TARGET_DIR}/bin" || true
          
          # cni-plugins
          mkdir -p "${TARGET_DIR}/bin/cni"
          URL="https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz"
          libscript_download "$URL" "${TEMP_DIR}/cni.tgz" || log_error "Failed to download CNI"
          tar -xzf "${TEMP_DIR}/cni.tgz" -C "${TARGET_DIR}/bin/cni" || true
          
          # containerd
          URL="https://github.com/containerd/containerd/releases/download/${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz"
          libscript_download "$URL" "${TEMP_DIR}/containerd.tar.gz" || log_error "Failed to download containerd"
          tar -xzf "${TEMP_DIR}/containerd.tar.gz" -C "${TARGET_DIR}" bin/ || true
          
          # etcd
          URL="https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"
          libscript_download "$URL" "${TEMP_DIR}/etcd.tar.gz" || log_error "Failed to download etcd"
          tar -xzf "${TEMP_DIR}/etcd.tar.gz" -C "${TARGET_DIR}/bin" --strip-components=1 "etcd-${ETCD_VERSION}-linux-${ARCH}/etcd" "etcd-${ETCD_VERSION}-linux-${ARCH}/etcdctl" || true
          
          rm -rf "${TEMP_DIR}"
        fi
      else
        log_info "kubernetes-thw ${VERSION} is already installed."
      fi
      libscript_symlink_alias "kubernetes-thw" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "kubernetes-thw" "$ACTION" "$VERSION" "${KUBERNETES_THW_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
