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
  . "$SCRIPT_DIR/cli/commands/packaging/formats/_common_installer_args.sh"
      PKG_STAGE="${OUT_FILE}_stage"
      rm -rf "$PKG_STAGE"
      mkdir -p "$PKG_STAGE/packages" "$PKG_STAGE/resources" "$PKG_STAGE/scripts"
      
      if [ -n "$WELCOME_TEXT" ]; then
        echo "<html><body><h1>Welcome</h1><p>$WELCOME_TEXT</p></body></html>" > "$PKG_STAGE/resources/welcome.html"
      fi
      if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
        cp "$LICENSE_PATH" "$PKG_STAGE/resources/license.html"
      fi
      
      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        comp_dir="$PKG_STAGE/comp_${pkg}"
        mkdir -p "$comp_dir/root/opt/libscript"
        mkdir -p "$comp_dir/scripts"
        
        cat << "EOF_SCRIPT" > "$comp_dir/scripts/postinstall"
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
USER_NAME=$(stat -f "%Su" /dev/console 2>/dev/null || echo "${SUDO_USER:-}")
if [ -z "${USER_NAME:-}" ] || [ "${USER_NAME:-}" = "root" ]; then
  USER_NAME="$USER"
fi
EOF_SCRIPT

        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        params=""
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              desc=$(echo "$item" | jq -r '.desc' | sed 's/"/\"/g')
              defval=$(echo "$item" | jq -r '.def' | sed 's/"/\"/g')
              
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                hidden="with hidden answer"
              else
                hidden=""
              fi
              
              cat << EOF_PROMPT >> "$comp_dir/scripts/postinstall"
VAL_${varname}=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Configuration for ${pkg}

${desc}:" default answer "${defval}" ${hidden}' -e 'text returned of result' 2>/dev/null)
export ${varname}="\$VAL_${varname}"
EOF_PROMPT

              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                cat << EOF_PROMPT >> "$comp_dir/scripts/postinstall"
while netstat -an | grep -q "[.:]\$VAL_${varname} .*LISTEN"; do
  VAL_${varname}=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Port '"\$VAL_${varname}"' is already in use. Please enter a different port:" default answer ""' -e 'text returned of result' 2>/dev/null)
  export ${varname}="\$VAL_${varname}"
done
EOF_PROMPT
              fi
            done
            params=$(echo "$vars_json" | jq -r '.key' | awk -v pkg="$pkg" '{printf " --%s=\"$VAL_%s\"", $1, $1}')
          fi
        fi

        cat << EOF_SCRIPT >> "$comp_dir/scripts/postinstall"
if command -v libscript.sh >/dev/null 2>&1; then
  libscript.sh install_service "$pkg" "$ver" $params
elif [ -f "/opt/libscript/libscript.sh" ]; then
  /opt/libscript/libscript.sh install_service "$pkg" "$ver" $params
elif [ -f "\$0/../../../libscript.sh" ]; then
  "\$0/../../../libscript.sh" install_service "$pkg" "$ver" $params
else
  sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display alert "libscript.sh not found. Installation of '"$pkg"' failed."'
  exit 1
fi

cat << "EOF_UNINST" > "/opt/libscript/uninstall_${pkg}.command"
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
USER_NAME=\$(stat -f "%Su" /dev/console 2>/dev/null || echo "\$SUDO_USER")
if [ -z "\$USER_NAME" ] || [ "\$USER_NAME" = "root" ]; then
  USER_NAME="\$USER"
fi

ans=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Do you want to completely remove the Data Directory and all records for '"$pkg"'?" buttons {"Yes", "No"} default button "No"' -e 'button returned of result' 2>/dev/null)

purge=""
if [ "\$ans" = "Yes" ]; then
  purge="--purge-data"
fi

echo "Uninstalling $pkg..."
sudo libscript.sh uninstall "$pkg" \$purge
echo "Uninstalled $pkg."
sleep 2
EOF_UNINST
chmod +x "/opt/libscript/uninstall_${pkg}.command"
EOF_SCRIPT

        chmod +x "$comp_dir/scripts/postinstall"
        
        if command -v pkgbuild >/dev/null 2>&1; then
          mkdir -p "$(dirname "$PKG_STAGE/packages/$pkg.pkg")"
        pkgbuild --root "$comp_dir/root" --scripts "$comp_dir/scripts" --identifier "com.libscript.comp.$pkg" --version "$APP_VERSION" "$PKG_STAGE/packages/$pkg.pkg"
        fi
      done

      if command -v productbuild >/dev/null 2>&1; then
        productbuild --synthesize --package-path "$PKG_STAGE/packages" "$PKG_STAGE/Distribution.xml"

        sed_cmd="sed -i"
        if [ "$(uname)" = "Darwin" ]; then sed_cmd="sed -i ''"; fi
        
        $sed_cmd -e '/<installer-gui-script/a\
    <title>'"$APP_NAME"'</title>\
    <options customize="always" require-scripts="false"/>' "$PKG_STAGE/Distribution.xml"

        if [ -n "$WELCOME_TEXT" ]; then
          $sed_cmd -e '/<installer-gui-script/a\
    <welcome file="welcome.html"/>' "$PKG_STAGE/Distribution.xml"
        fi
        
        if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
          $sed_cmd -e '/<installer-gui-script/a\
    <license file="license.html"/>' "$PKG_STAGE/Distribution.xml"
        fi
        
        set -- $deps_list
        while [ $# -gt 0 ]; do
          pkg=$1; ver=$2; shift 2
          $sed_cmd "s/choice id=\"com.libscript.comp.$pkg\" title=\"[^\"]*\"/choice id=\"com.libscript.comp.$pkg\" title=\"$pkg installer\"/g" "$PKG_STAGE/Distribution.xml"
        done

        productbuild --distribution "$PKG_STAGE/Distribution.xml" --package-path "$PKG_STAGE/packages" --resources "$PKG_STAGE/resources" "${OUT_FILE}.pkg"
        
        if true; then
          hdiutil create -volname "$APP_NAME" -srcfolder "${OUT_FILE}.pkg" -ov -format UDZO "${OUT_FILE}.dmg"
          echo "Created ${OUT_FILE}.dmg"
        else
          echo "Created ${OUT_FILE}.pkg"
        fi
        rm -rf "$PKG_STAGE"
      else
        echo "Created source files in $PKG_STAGE"
        echo "pkgbuild/productbuild not found. Cannot build .pkg natively." >&2
      fi
      exit 0

