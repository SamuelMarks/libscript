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
        meta_depends="${meta_depends}${pkg_name} = ${APP_VERSION}"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_rpmbuild\""
        echo "mkdir -p \"\$BUILD_DIR/BUILD\" \"\$BUILD_DIR/RPMS\" \"\$BUILD_DIR/SOURCES\" \"\$BUILD_DIR/SPECS\" \"\$BUILD_DIR/SRPMS\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/SPECS/${pkg_name}.spec\""
        echo "Name: $pkg_name"
        echo "Version: $APP_VERSION"
        echo "Release: 1%{?dist}"
        echo "Summary: $APP_NAME deployment - $pkg"
        echo "License: MIT"
        echo "BuildArch: noarch"
        echo "%description"
        echo "$APP_NAME deployment - $pkg"
        echo "%install"
        echo "mkdir -p %{buildroot}/opt/libscript"; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* %{buildroot}/opt/libscript/ 2>/dev/null || true"; echo "rm -rf %{buildroot}/opt/libscript/.git"; fi
        echo "touch %{buildroot}/var/lib/libscript/.${pkg_name}_installed"
        echo "%post"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        echo "%preun"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        echo "%files"
        echo "/var/lib/libscript/.${pkg_name}_installed"
        echo "EOF"
        echo "rpmbuild --define \"_topdir \$BUILD_DIR\" -bb \"\$BUILD_DIR/SPECS/${pkg_name}.spec\""
        echo "find \"\$BUILD_DIR/RPMS\" -name \"*.rpm\" -exec cp {} \"\$OUT_DIR/\" \\;"
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_rpmbuild\""
      echo "mkdir -p \"\$BUILD_DIR/BUILD\" \"\$BUILD_DIR/RPMS\" \"\$BUILD_DIR/SOURCES\" \"\$BUILD_DIR/SPECS\" \"\$BUILD_DIR/SRPMS\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/SPECS/${APP_NAME}-meta.spec\""
      echo "Name: ${APP_NAME}-meta"
      echo "Version: $APP_VERSION"
      echo "Release: 1%{?dist}"
      echo "Summary: $APP_NAME deployment metapackage"
      echo "License: MIT"
      echo "BuildArch: noarch"
      if [ -n "$meta_depends" ]; then echo "Requires: $meta_depends"; fi
      echo "%description"
      echo "$APP_NAME deployment metapackage"
      echo "%install"
      echo "mkdir -p %{buildroot}/opt/libscript"; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* %{buildroot}/opt/libscript/ 2>/dev/null || true"; echo "rm -rf %{buildroot}/opt/libscript/.git"; fi
      echo "touch %{buildroot}/var/lib/libscript/.${APP_NAME}-meta_installed"
      echo "%files"
      echo "/var/lib/libscript/.${APP_NAME}-meta_installed"
      echo "EOF"
      echo "rpmbuild --define \"_topdir \$BUILD_DIR\" -bb \"\$BUILD_DIR/SPECS/${APP_NAME}-meta.spec\""
      echo "find \"\$BUILD_DIR/RPMS\" -name \"*.rpm\" -exec cp {} \"\$OUT_DIR/\" \\;"
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
