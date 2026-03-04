      cat << EOF2
!define APP_NAME "$APP_NAME"
!define APP_VERSION "$APP_VERSION"
!define APP_PUBLISHER "$APP_PUBLISHER"
Name "$APP_NAME \$APP_VERSION"
OutFile "${OUT_FILE}.exe"
InstallDir "\$PROGRAMFILES\\$APP_NAME"
RequestExecutionLevel $nsis_admin

VIProductVersion "$APP_VERSION"
VIAddVersionKey "ProductName" "$APP_NAME"
VIAddVersionKey "CompanyName" "$APP_PUBLISHER"
VIAddVersionKey "FileDescription" "$WELCOME_TEXT"
VIAddVersionKey "FileVersion" "$APP_VERSION"
EOF2
      if [ -n "$ICON_PATH" ]; then echo "Icon \"$ICON_PATH\""; fi
      echo ""
      
      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end)" else empty end' "libscript.json" 2>/dev/null | tr '\n' ' ')
      fi

      echo "Include nsDialogs.nsh"
      echo "Page components"
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "Var Dialog_$pkg"
            echo "$vars_json" | jq -r '.key' | while read -r varname; do
              echo "Var HWND_${pkg}_${varname}"
              echo "Var VAL_${pkg}_${varname}"
            done
            
            echo "Page custom pgCustom_$pkg pgLeave_$pkg"
          fi
        fi
      done
      
      if [ -n "$LICENSE_PATH" ]; then echo "Page license \"\" \"$LICENSE_PATH\""; fi
      echo "Page instfiles"
      echo ""
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Section \"$pkg\" SEC_$pkg"
        run_params="/c libscript.cmd install_service $pkg $ver"
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"\$VAL_%s_%s\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "  ExecWait 'cmd.exe $run_params'"
        echo "SectionEnd"
      done

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "Function pgCustom_$pkg"
            echo "  SectionGetFlags \${SEC_$pkg} \$0"
            echo "  IntOp \$0 \$0 & 1"
            echo "  IntCmp \$0 1 +2"
            echo "    Abort"
            echo "  nsDialogs::Create 1018"
            echo "  Pop \$Dialog_$pkg"
            
            y=0
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              desc=$(echo "$item" | jq -r '.desc')
              defval=$(echo "$item" | jq -r '.def')
              if [ $y -gt 130 ]; then break; fi
              
              echo "  \${NSD_CreateLabel} 0 ${y}u 100% 12u \"$desc:\""
              echo "  Pop \$0"
              y=$((y + 12))
              
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                echo "  \${NSD_CreatePassword} 0 ${y}u 100% 12u \"$defval\""
              else
                echo "  \${NSD_CreateText} 0 ${y}u 100% 12u \"$defval\""
              fi
              echo "  Pop \$HWND_${pkg}_${varname}"
              y=$((y + 14))
            done
            echo "  nsDialogs::Show"
            echo "FunctionEnd"
            
            echo "Function pgLeave_$pkg"
            echo "$vars_json" | jq -r '.key' | while read -r varname; do
              echo "  \${NSD_GetText} \$HWND_${pkg}_${varname} \$VAL_${pkg}_${varname}"
              
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                echo "  StrCmp \$VAL_${pkg}_${varname} \"\" +4 0"
                echo "  nsExec::ExecToStack 'cmd.exe /c netstat -an | findstr /R /C:\":\$VAL_${pkg}_${varname} .*LISTENING\"'"
                echo "  Pop \$0"
                echo "  IntCmp \$0 0 0 +3"
                echo "    MessageBox MB_ICONSTOP \"Port \$VAL_${pkg}_${varname} is already in use.\""
                echo "    Abort"
              fi
            done
            echo "FunctionEnd"
          fi
        fi
      done

      # Uninstaller
      echo "Section \"Uninstall\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  MessageBox MB_YESNO \"Do you want to completely remove the Data Directory and all records for $pkg?\" IDYES purge_$pkg IDNO keep_$pkg"
        echo "  purge_$pkg:"
        echo "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(echo $pkg | tr "a-z" "A-Z")_SERVICE_NAME'"
        echo "    Goto end_$pkg"
        echo "  keep_$pkg:"
        echo "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --service-name \$VAL_${pkg}_$(echo $pkg | tr "a-z" "A-Z")_SERVICE_NAME'"
        echo "  end_$pkg:"
      done
      echo "SectionEnd"

      exit 0
