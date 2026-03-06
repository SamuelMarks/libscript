#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


      cat << EOF2
[Setup]
AppName=$APP_NAME
AppVersion=$APP_VERSION
AppPublisher=$APP_PUBLISHER
EOF2
      if [ -n "$APP_URL" ]; then
        echo "AppPublisherURL=$APP_URL"
        echo "AppSupportURL=$APP_URL"
        echo "AppUpdatesURL=$APP_URL"
      fi
      cat << EOF2
DefaultDirName={autopf}\\$APP_NAME
PrivilegesRequired=$inno_priv
OutputDir=.
OutputBaseFilename=$OUT_FILE
EOF2
      if [ "$UPGRADE_CODE" != "PUT-GUID-HERE" ]; then echo "AppId=$UPGRADE_CODE"; fi
      if [ -n "$ICON_PATH" ]; then echo "SetupIconFile=$ICON_PATH"; fi
      if [ -n "$IMAGE_PATH" ]; then echo "WizardImageFile=$IMAGE_PATH"; fi
      if [ -n "$LICENSE_PATH" ]; then echo "LicenseFile=$LICENSE_PATH"; fi

      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      fi

      echo ""
      echo "[Types]"
      echo "Name: \"custom\"; Description: \"Custom installation\"; Flags: iscustom"
      echo "Name: \"full\"; Description: \"Full installation\""
      echo ""
      echo "[Components]"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Name: \"$pkg\"; Description: \"$pkg\"; Types: full custom"
      done

      echo ""
      echo "[Code]"
      echo "var"

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "  Page_$pkg: TInputQueryWizardPage;"
            echo "$vars_json" | jq -r '.key' | while read -r varname; do
              echo "  Var_${pkg}_${varname}: String;"
            done
          fi
        fi
      done

      echo "procedure InitializeWizard;"
      echo "begin"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "  Page_$pkg := CreateInputQueryPage(wpSelectComponents, 'Configuration for $pkg', 'Please specify settings', '');"
            var_idx=0
            echo "$vars_json" | while read -r item; do
              desc=$(echo "$item" | jq -r '.desc')
              defval=$(echo "$item" | jq -r '.def')
              varname=$(echo "$item" | jq -r '.key')
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                echo "  Page_$pkg.Add('$desc:', True);"
              else
                echo "  Page_$pkg.Add('$desc:', False);"
              fi
              echo "  Page_$pkg.Values[$var_idx] := '$defval';"
              var_idx=$((var_idx + 1))
            done
          fi
        fi
      done
      echo "end;"

      echo "function ShouldSkipPage(PageID: Integer): Boolean;"
      echo "begin"
      echo "  Result := False;"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          if [ -n "$(jq -c '.properties' "$schema_file")" ]; then
            echo "  if (PageID = Page_$pkg.ID) and not IsComponentSelected('$pkg') then"
            echo "    Result := True;"
          fi
        fi
      done
      echo "end;"

      echo "function NextButtonClick(PageId: Integer): Boolean;"
      echo "var"
      echo "  ResultCode: Integer;"
      echo "begin"
      echo "  Result := True;"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "  if PageId = Page_$pkg.ID then begin"
            var_idx=0
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                echo "    if (Page_$pkg.Values[$var_idx] <> '') then begin"
                echo "      if Exec('cmd.exe', '/c netstat -an | findstr /R /C:"":'' + Page_$pkg.Values[$var_idx] + '' .*LISTENING""', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then begin"
                echo "        if ResultCode = 0 then begin"
                echo "          MsgBox('Port ' + Page_$pkg.Values[$var_idx] + ' is already in use. Please select a different port.', mbError, MB_OK);"
                echo "          Result := False;"
                echo "          Exit;"
                echo "        end;"
                echo "      end;"
                echo "    end;"
              fi
              var_idx=$((var_idx + 1))
            done
            echo "  end;"
          fi
        fi
      done
      echo "end;"

      # Uninstallation Hooks
      echo "procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);"
      echo "var"
      echo "  ResultCode: Integer;"
      echo "begin"
      echo "  if CurUninstallStep = usUninstall then begin"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    if MsgBox('Do you want to completely remove the Data Directory and all records for $pkg?', mbConfirmation, MB_YESNO) = idYes then begin"
        echo "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --purge-data --service-name ' + Get_${pkg}_$(echo "$pkg" | tr "a-z" "A-Z")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        echo "    end else begin"
        echo "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --service-name ' + Get_${pkg}_$(echo "$pkg" | tr "a-z" "A-Z")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        echo "    end;"
      done
      echo "  end;"
      echo "end;"

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            var_idx=0
            for varname in $vars_json; do
              echo "function Get_${pkg}_${varname}(Param: String): String;"
              echo "begin"
              echo "  Result := Page_$pkg.Values[$var_idx];"
              echo "end;"
              var_idx=$((var_idx + 1))
            done
          fi
        fi
      done

      echo ""
      echo "[Run]"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        run_params="/c libscript.cmd install_service $pkg $ver"
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"{code:Get_%s_%s}\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "Filename: \"cmd.exe\"; Parameters: \"$run_params\"; Components: $pkg; Flags: runhidden"
      done
      exit 0
