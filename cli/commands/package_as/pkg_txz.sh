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
        meta_depends="${meta_depends}\"${pkg_name}\": {\"version\": \"$APP_VERSION\", \"origin\": \"misc/${pkg_name}\"}"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_pkgbuild\""
        echo "mkdir -p \"\$BUILD_DIR/root/opt/libscript\""
        echo "mkdir -p \"\$BUILD_DIR/root/var/lib/libscript\""
        if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* \"\$BUILD_DIR/root/opt/libscript/\" 2>/dev/null || true"; echo "rm -rf \"\$BUILD_DIR/root/opt/libscript/.git\""; fi
        echo "touch \"\$BUILD_DIR/root/var/lib/libscript/.${pkg_name}_installed\""
        echo "mkdir -p \"\$BUILD_DIR/meta\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/meta/+MANIFEST\""
        echo "name: \"$pkg_name\""
        echo "version: \"$APP_VERSION\""
        echo "origin: \"misc/$pkg_name\""
        echo "comment: \"$APP_NAME deployment - $pkg\""
        echo "desc: \"$APP_NAME deployment - $pkg\""
        echo "maintainer: \"$APP_PUBLISHER\""
        echo "www: \"$APP_URL\""
        echo "prefix: \"/\""
        echo "scripts: {"
        echo "  post-install: \"if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi\","
        echo "  pre-deinstall: \"if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi\""
        echo "}"
        echo "EOF"
        echo "cd \"\$BUILD_DIR/root\" && find . -type f -o -type l | sed -e 's|^./||' > \"\$BUILD_DIR/meta/pkg-plist\""
        echo "pkg create -m \"\$BUILD_DIR/meta\" -r \"\$BUILD_DIR/root\" -o \"\$OUT_DIR\""
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_pkgbuild\""
      echo "mkdir -p \"\$BUILD_DIR/root/var/lib/libscript\""
      echo "touch \"\$BUILD_DIR/root/var/lib/libscript/.${APP_NAME}-meta_installed\""
      echo "mkdir -p \"\$BUILD_DIR/meta\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/meta/+MANIFEST\""
      echo "name: \"${APP_NAME}-meta\""
      echo "version: \"$APP_VERSION\""
      echo "origin: \"misc/${APP_NAME}-meta\""
      echo "comment: \"$APP_NAME deployment metapackage\""
      echo "desc: \"$APP_NAME deployment metapackage\""
      echo "maintainer: \"$APP_PUBLISHER\""
      echo "www: \"$APP_URL\""
      echo "prefix: \"/\""
      if [ -n "$meta_depends" ]; then
        echo "deps: {"
        echo "  $meta_depends"
        echo "}"
      fi
      echo "EOF"
      echo "cd \"\$BUILD_DIR/root\" && find . -type f -o -type l | sed -e 's|^./||' > \"\$BUILD_DIR/meta/pkg-plist\""
      echo "pkg create -m \"\$BUILD_DIR/meta\" -r \"\$BUILD_DIR/root\" -o \"\$OUT_DIR\""
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
    fi
