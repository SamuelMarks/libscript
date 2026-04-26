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
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends}, "; fi
        meta_depends="${meta_depends}${pkg_name} (= ${APP_VERSION})"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_build\""
        echo "rm -rf \"\$BUILD_DIR\" && mkdir -p \"\$BUILD_DIR/DEBIAN\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/control\""
        echo "Package: $pkg_name"
        echo "Version: $APP_VERSION"
        echo "Architecture: all"
        echo "Maintainer: $APP_PUBLISHER"
        echo "Description: $APP_NAME deployment - $pkg"
        echo "EOF"
        echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/postinst\""
        echo "#!/bin/sh"
        echo "set -e"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        echo "EOF"
        echo "chmod 0755 \"\$BUILD_DIR/DEBIAN/postinst\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/prerm\""
        echo "#!/bin/sh"
        echo "set -e"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        echo "EOF"
        echo "chmod 0755 \"\$BUILD_DIR/DEBIAN/prerm\""
        echo "mkdir -p \"\$BUILD_DIR/opt/libscript\""; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* \"\$BUILD_DIR/opt/libscript/\" 2>/dev/null || true"; echo "rm -rf \"\$BUILD_DIR/opt/libscript/.git\""; fi
        echo "dpkg-deb --build \"\$BUILD_DIR\" \"\$OUT_DIR/${pkg_name}_${APP_VERSION}_all.deb\""
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_build\""
      echo "rm -rf \"\$BUILD_DIR\" && mkdir -p \"\$BUILD_DIR/DEBIAN\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/control\""
      echo "Package: ${APP_NAME}-meta"
      echo "Version: $APP_VERSION"
      echo "Architecture: all"
      echo "Maintainer: $APP_PUBLISHER"
      if [ -n "$meta_depends" ]; then echo "Depends: $meta_depends"; fi
      echo "Description: $APP_NAME deployment metapackage"
      echo "EOF"
      echo "mkdir -p \"\$BUILD_DIR/opt/libscript\""; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* \"\$BUILD_DIR/opt/libscript/\" 2>/dev/null || true"; echo "rm -rf \"\$BUILD_DIR/opt/libscript/.git\""; fi
      echo "dpkg-deb --build \"\$BUILD_DIR\" \"\$OUT_DIR/${APP_NAME}-meta_${APP_VERSION}_all.deb\""
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
