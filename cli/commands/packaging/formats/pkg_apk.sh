#!/bin/sh
# ## Overview
# Implements packaging logic for the 'apk' format.
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
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends} "; fi
        meta_depends="${meta_depends}${pkg_name}"
        printf '%s\n' "echo \"Building $pkg_name ...\""
        printf '%s\n' "BUILD_DIR=\"/tmp/${pkg_name}_apkbuild\""
        printf '%s\n' "mkdir -p \"\$BUILD_DIR\""
        printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/APKBUILD\""
        printf '%s\n' "pkgname=\"$pkg_name\""
        printf '%s\n' "pkgver=\"$APP_VERSION\""
        printf '%s\n' "pkgrel=1"
        printf '%s\n' "pkgdesc=\"$APP_NAME deployment - $pkg\""
        printf '%s\n' "url=\"$APP_URL\""
        printf '%s\n' "arch=\"noarch\""
        printf '%s\n' "license=\"MIT\""
        printf '%s\n' "depends=\"\""
        printf '%s\n' "install=\"\$pkgname.post-install \$pkgname.pre-deinstall\""
        printf '%s\n' "build() { return 0; }"
        printf '%s\n' "package() {"
        printf '%s\n' "  mkdir -p \"\$pkgdir/var/LIB/libscript\""
        printf '%s\n' "  touch \"\$pkgdir/var/LIB/libscript/.${pkg_name}_installed\""
        printf '%s\n' "}"
        printf '%s\n' "EOF"
        printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/${pkg_name}.post-install\""
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        printf '%s\n' "EOF"
        printf '%s\n' "chmod +x \"\$BUILD_DIR/${pkg_name}.post-install\""
        printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/${pkg_name}.pre-deinstall\""
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        printf '%s\n' "EOF"
        printf '%s\n' "chmod +x \"\$BUILD_DIR/${pkg_name}.pre-deinstall\""
        printf '%s\n' "if [ \"\$(id -u)\" = \"0\" ]; then ABUILD_OPTS=\"-F\"; else ABUILD_OPTS=\"\"; fi"
        printf '%s\n' "cd \"\$BUILD_DIR\" && abuild \$ABUILD_OPTS -P \"\$BUILD_DIR/out\" rootpkg"
        printf '%s\n' "find \"\$BUILD_DIR/out\" -name \"*.apk\" -exec cp {} \"\$OUT_DIR/\" \\;"
        printf '%s\n' "rm -rf \"\$BUILD_DIR\""
      done
      printf '%s\n' "echo \"Building ${APP_NAME}-meta ...\""
      printf '%s\n' "BUILD_DIR=\"/tmp/${APP_NAME}-meta_apkbuild\""
      printf '%s\n' "mkdir -p \"\$BUILD_DIR\""
      printf '%s\n' "cat << 'EOF' > \"\$BUILD_DIR/APKBUILD\""
      printf '%s\n' "pkgname=\"${APP_NAME}-meta\""
      printf '%s\n' "pkgver=\"$APP_VERSION\""
      printf '%s\n' "pkgrel=1"
      printf '%s\n' "pkgdesc=\"$APP_NAME deployment metapackage\""
      printf '%s\n' "url=\"$APP_URL\""
      printf '%s\n' "arch=\"noarch\""
      printf '%s\n' "license=\"MIT\""
      printf '%s\n' "depends=\"$meta_depends\""
      printf '%s\n' "build() { return 0; }"
      printf '%s\n' "package() {"
      printf '%s\n' "  mkdir -p \"\$pkgdir/var/LIB/libscript\""
      printf '%s\n' "  touch \"\$pkgdir/var/LIB/libscript/.${APP_NAME}-meta_installed\""
      printf '%s\n' "}"
      printf '%s\n' "EOF"
      printf '%s\n' "if [ \"\$(id -u)\" = \"0\" ]; then ABUILD_OPTS=\"-F\"; else ABUILD_OPTS=\"\"; fi"
      printf '%s\n' "cd \"\$BUILD_DIR\" && abuild \$ABUILD_OPTS -P \"\$BUILD_DIR/out\" rootpkg"
      printf '%s\n' "find \"\$BUILD_DIR/out\" -name \"*.apk\" -exec cp {} \"\$OUT_DIR/\" \\;"
      printf '%s\n' "rm -rf \"\$BUILD_DIR\""
      printf '%s\n' "echo \"Done!\""
      exit 0
