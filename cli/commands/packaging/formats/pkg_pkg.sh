#!/bin/sh

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

      DEPS_LIST=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          DEPS_LIST="$DEPS_LIST $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        DEPS_LIST=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        DEPS_LIST=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      set -- $DEPS_LIST
      while [ $# -gt 0 ]; do
        PKG=$1; VER=$2; shift 2
        COMP_DIR="$PKG_STAGE/comp_${PKG}"
        mkdir -p "$COMP_DIR/root/opt/libscript"
        mkdir -p "$COMP_DIR/scripts"

        cat << "EOF_SCRIPT" > "$COMP_DIR/scripts/postinstall"
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
USER_NAME=$(stat -f "%Su" /dev/console 2>/dev/null || echo "${SUDO_USER:-}")
if [ -z "${USER_NAME:-}" ] || [ "${USER_NAME:-}" = "root" ]; then
  USER_NAME="$USER"
fi
EOF_SCRIPT

        SCHEMA_FILE=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$PKG/" | head -n 1)
        PARAMS=""
        if [ -f "$SCHEMA_FILE" ]; then
          VARS_JSON=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$SCHEMA_FILE")
          if [ -n "$VARS_JSON" ]; then
            echo "$VARS_JSON" | while read -r item; do
              VARNAME=$(echo "$item" | jq -r '.key')
              DESC=$(echo "$item" | jq -r '.desc' | sed 's/"/\"/g')
              DEFVAL=$(echo "$item" | jq -r '.def' | sed 's/"/\"/g')

              if case "$VARNAME" in *"_PASSWORD"*) true;; *) false;; esac; then
                HIDDEN="with hidden answer"
              else
                HIDDEN=""
              fi

              cat << EOF_PROMPT >> "$COMP_DIR/scripts/postinstall"
VAL_${VARNAME}=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Configuration for ${PKG}

${DESC}:" default answer "${DEFVAL}" ${HIDDEN}' -e 'text returned of result' 2>/dev/null)
export ${VARNAME}="\$VAL_${VARNAME}"
EOF_PROMPT

              if case "$VARNAME" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                cat << EOF_PROMPT >> "$COMP_DIR/scripts/postinstall"
while netstat -an | grep -q "[.:]\$VAL_${VARNAME} .*LISTEN"; do
  VAL_${VARNAME}=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Port '"\$VAL_${VARNAME}"' is already in use. Please enter a different port:" default answer ""' -e 'text returned of result' 2>/dev/null)
  export ${VARNAME}="\$VAL_${VARNAME}"
done
EOF_PROMPT
              fi
            done
            PARAMS=$(echo "$VARS_JSON" | jq -r '.key' | awk -v PKG="$PKG" '{printf " --%s=\"$VAL_%s\"", $1, $1}')
          fi
        fi

        cat << EOF_SCRIPT >> "$COMP_DIR/scripts/postinstall"
if command -v libscript.sh >/dev/null 2>&1; then
  libscript.sh install_service "$PKG" "$VER" $PARAMS
elif [ -f "/opt/libscript/libscript.sh" ]; then
  /opt/libscript/libscript.sh install_service "$PKG" "$VER" $PARAMS
elif [ -f "\$0/../../../libscript.sh" ]; then
  "\$0/../../../libscript.sh" install_service "$PKG" "$VER" $PARAMS
else
  sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display alert "libscript.sh not found. Installation of '"$PKG"' failed."'
  exit 1
fi

cat << "EOF_UNINST" > "/opt/libscript/uninstall_${PKG}.command"
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
USER_NAME=\$(stat -f "%Su" /dev/console 2>/dev/null || echo "\$SUDO_USER")
if [ -z "\$USER_NAME" ] || [ "\$USER_NAME" = "root" ]; then
  USER_NAME="\$USER"
fi

ANS=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Do you want to completely remove the Data Directory and all records for '"$PKG"'?" buttons {"Yes", "No"} default button "No"' -e 'button returned of result' 2>/dev/null)

PURGE=""
if [ "\$ANS" = "Yes" ]; then
  PURGE="--purge-data"
fi

echo "Uninstalling $PKG..."
sudo libscript.sh uninstall "$PKG" \$PURGE
echo "Uninstalled $PKG."
sleep 2
EOF_UNINST
chmod +x "/opt/libscript/uninstall_${PKG}.command"
EOF_SCRIPT

        chmod +x "$COMP_DIR/scripts/postinstall"

        if command -v pkgbuild >/dev/null 2>&1; then
          mkdir -p "$(dirname "$PKG_STAGE/packages/$PKG.pkg")"
        pkgbuild --root "$COMP_DIR/root" --scripts "$COMP_DIR/scripts" --identifier "com.libscript.comp.$PKG" --version "$APP_VERSION" "$PKG_STAGE/packages/$PKG.pkg"
        fi
      done

      if command -v productbuild >/dev/null 2>&1; then
        productbuild --synthesize --package-path "$PKG_STAGE/packages" "$PKG_STAGE/Distribution.xml"

        SED_CMD="sed -i"
        if [ "$(uname)" = "Darwin" ]; then SED_CMD="sed -i ''"; fi

        $SED_CMD -e '/<installer-gui-script/a\
    <title>'"$APP_NAME"'</title>\
    <options customize="always" require-scripts="false"/>' "$PKG_STAGE/Distribution.xml"

        if [ -n "$WELCOME_TEXT" ]; then
          $SED_CMD -e '/<installer-gui-script/a\
    <welcome file="welcome.html"/>' "$PKG_STAGE/Distribution.xml"
        fi

        if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
          $SED_CMD -e '/<installer-gui-script/a\
    <license file="license.html"/>' "$PKG_STAGE/Distribution.xml"
        fi

        set -- $DEPS_LIST
        while [ $# -gt 0 ]; do
          PKG=$1; VER=$2; shift 2
          $SED_CMD "s/choice id=\"com.libscript.comp.$PKG\" title=\"[^\"]*\"/choice id=\"com.libscript.comp.$PKG\" title=\"$PKG installer\"/g" "$PKG_STAGE/Distribution.xml"
        done

        productbuild --distribution "$PKG_STAGE/Distribution.xml" --package-path "$PKG_STAGE/packages" --resources "$PKG_STAGE/resources" "${OUT_FILE}.pkg"

        if false; then
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

