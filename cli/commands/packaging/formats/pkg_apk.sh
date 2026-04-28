#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
      echo "#!/bin/sh"
      echo "set -e"
      echo "OUT_DIR=\"$OUT_DIR\""
      echo "mkdir -p \"\$OUT_DIR\""
      meta_depends=""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_name="${APP_NAME}-${pkg}"
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends} "; fi
        meta_depends="${meta_depends}${pkg_name}"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_apkbuild\""
        echo "mkdir -p \"\$BUILD_DIR\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/APKBUILD\""
        echo "pkgname=\"$pkg_name\""
        echo "pkgver=\"$APP_VERSION\""
        echo "pkgrel=1"
        echo "pkgdesc=\"$APP_NAME deployment - $pkg\""
        echo "url=\"$APP_URL\""
        echo "arch=\"noarch\""
        echo "license=\"MIT\""
        echo "depends=\"\""
        echo "install=\"\$pkgname.post-install \$pkgname.pre-deinstall\""
        echo "build() { return 0; }"
        echo "package() {"
        echo "  mkdir -p \"\$pkgdir/var/lib/libscript\""
        echo "  touch \"\$pkgdir/var/lib/libscript/.${pkg_name}_installed\""
        echo "}"
        echo "EOF"
        echo "cat << 'EOF' > \"\$BUILD_DIR/${pkg_name}.post-install\""
        echo "#!/bin/sh"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        echo "EOF"
        echo "chmod +x \"\$BUILD_DIR/${pkg_name}.post-install\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/${pkg_name}.pre-deinstall\""
        echo "#!/bin/sh"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        echo "EOF"
        echo "chmod +x \"\$BUILD_DIR/${pkg_name}.pre-deinstall\""
        echo "if [ \"\$(id -u)\" = \"0\" ]; then ABUILD_OPTS=\"-F\"; else ABUILD_OPTS=\"\"; fi"
        echo "cd \"\$BUILD_DIR\" && abuild \$ABUILD_OPTS -P \"\$BUILD_DIR/out\" rootpkg"
        echo "find \"\$BUILD_DIR/out\" -name \"*.apk\" -exec cp {} \"\$OUT_DIR/\" \\;"
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_apkbuild\""
      echo "mkdir -p \"\$BUILD_DIR\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/APKBUILD\""
      echo "pkgname=\"${APP_NAME}-meta\""
      echo "pkgver=\"$APP_VERSION\""
      echo "pkgrel=1"
      echo "pkgdesc=\"$APP_NAME deployment metapackage\""
      echo "url=\"$APP_URL\""
      echo "arch=\"noarch\""
      echo "license=\"MIT\""
      echo "depends=\"$meta_depends\""
      echo "build() { return 0; }"
      echo "package() {"
      echo "  mkdir -p \"\$pkgdir/var/lib/libscript\""
      echo "  touch \"\$pkgdir/var/lib/libscript/.${APP_NAME}-meta_installed\""
      echo "}"
      echo "EOF"
      echo "if [ \"\$(id -u)\" = \"0\" ]; then ABUILD_OPTS=\"-F\"; else ABUILD_OPTS=\"\"; fi"
      echo "cd \"\$BUILD_DIR\" && abuild \$ABUILD_OPTS -P \"\$BUILD_DIR/out\" rootpkg"
      echo "find \"\$BUILD_DIR/out\" -name \"*.apk\" -exec cp {} \"\$OUT_DIR/\" \\;"
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
