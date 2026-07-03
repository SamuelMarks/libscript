#!/bin/sh
# ## Overview
# Implements packaging logic for the 'deb' format.
# 
# ## Usage
# This script is called by the packaging system and should not be executed manually.


set -feu
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
      printf '%s\n' "#!/bin/sh"
      printf '%s\n' "set -e"
      printf '%s\n' "OUT_DIR=\"$OUT_DIR\""
      printf '%s\n' "mkdir -p \"\$OUT_DIR\""
      meta_depends=""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_name="${APP_NAME}-${pkg}"
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends}, "; fi
        meta_depends="${meta_depends}${pkg_name} (= ${APP_VERSION})"
        printf '%s\n' "echo \"Building $pkg_name ...\""
        printf '%s\n' "BUILD_DIR=\"/tmp/${pkg_name}_build\""
        printf '%s\n' "rm -rf \"\$BUILD_DIR\" && mkdir -p \"\$BUILD_DIR/DEBIAN\""
        printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/control\""
        printf '%s\n' "Package: $pkg_name"
        printf '%s\n' "Version: $APP_VERSION"
        printf '%s\n' "Architecture: all"
        printf '%s\n' "Maintainer: $APP_PUBLISHER"
        printf '%s\n' "Description: $APP_NAME deployment - $pkg"
        printf '%s\n' "EOF"
        printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/postinst\""
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "set -e"
        printf '%s\n' "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        printf '%s\n' "EOF"
        printf '%s\n' "chmod 0755 \"\$BUILD_DIR/DEBIAN/postinst\""
        printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/prerm\""
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "set -e"
        printf '%s\n' "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        printf '%s\n' "EOF"
        printf '%s\n' "chmod 0755 \"\$BUILD_DIR/DEBIAN/prerm\""
        printf '%s\n' "mkdir -p \"\$BUILD_DIR/opt/libscript\""; if [ "$OFFLINE" = "1" ]; then printf '%s\n' "cp -a \"$LIBSCRIPT_ROOT_DIR\"/.* \"$LIBSCRIPT_ROOT_DIR\"/* \"\$BUILD_DIR/opt/libscript/\" 2>/dev/null || true"; printf '%s\n' "rm -rf \"\$BUILD_DIR/opt/libscript/.git\""; fi
        printf '%s\n' "dpkg-deb --build \"\$BUILD_DIR\" \"\$OUT_DIR/${pkg_name}_${APP_VERSION}_all.deb\""
        printf '%s\n' "rm -rf \"\$BUILD_DIR\""
      done
      printf '%s\n' "echo \"Building ${APP_NAME}-meta ...\""
      printf '%s\n' "BUILD_DIR=\"/tmp/${APP_NAME}-meta_build\""
      printf '%s\n' "rm -rf \"\$BUILD_DIR\" && mkdir -p \"\$BUILD_DIR/DEBIAN\""
      printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/control\""
      printf '%s\n' "Package: ${APP_NAME}-meta"
      printf '%s\n' "Version: $APP_VERSION"
      printf '%s\n' "Architecture: all"
      printf '%s\n' "Maintainer: $APP_PUBLISHER"
      if [ -n "$meta_depends" ]; then printf '%s\n' "Depends: $meta_depends"; fi
      printf '%s\n' "Description: $APP_NAME deployment metapackage"
      printf '%s\n' "EOF"
      printf '%s\n' "mkdir -p \"\$BUILD_DIR/opt/libscript\""; if [ "$OFFLINE" = "1" ]; then printf '%s\n' "cp -a \"$LIBSCRIPT_ROOT_DIR\"/.* \"$LIBSCRIPT_ROOT_DIR\"/* \"\$BUILD_DIR/opt/libscript/\" 2>/dev/null || true"; printf '%s\n' "rm -rf \"\$BUILD_DIR/opt/libscript/.git\""; fi
      printf '%s\n' "dpkg-deb --build \"\$BUILD_DIR\" \"\$OUT_DIR/${APP_NAME}-meta_${APP_VERSION}_all.deb\""
      printf '%s\n' "rm -rf \"\$BUILD_DIR\""
      printf '%s\n' "echo \"Done!\""
      exit 0
