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
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      if [ "$OFFLINE" = "1" ]; then
        echo ""
        echo "[Files]"
        echo "Source: \"$SCRIPT_DIR\\*\"; DestDir: \"{app}\"; Flags: ignoreversion recursesubdirs createallsubdirs"
      fi

      echo ""
      echo "[Types]"
      echo "Name: \"custom\"; Description: \"Custom installation\"; Flags: iscustom"
      echo "Name: \"full\"; Description: \"Full installation\""
      echo ""
      echo "[Components]"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Name: \"$pkg\"; Description: \"$pkg\"; Types: full custom"
      done

      echo ""
      echo "[Code]"
      echo "var"

      set -- $deps_list
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
      echo "  ActionPage := CreateInputOptionPage(wpSelectComponents, 'Action', 'What would you like to produce?', 'Please select an action to perform with the selected components.', True, False);"
      echo "  ActionPage.Add('Install locally now');"
      echo "  ActionPage.Add('Dockerfile');"
      echo "  ActionPage.Add('Dockerfiles + docker-compose');"
      echo "  ActionPage.Add('.msi installer');"
      echo "  ActionPage.Add('.exe (InnoSetup)');"
      echo "  ActionPage.Add('.exe (NSIS)');"
      echo "  ActionPage.Add('.pkg installer');"
      echo "  ActionPage.Add('.dmg installer');"
      echo "  ActionPage.Add('.deb package');"
      echo "  ActionPage.Add('.rpm package');"
      echo "  ActionPage.Values[0] := True;"
      echo "  OfflinePage := CreateInputOptionPage(ActionPage.ID, 'Options & OS Targets', 'Select offline mode and Target OS', '', False, True);"
      echo "  OfflinePage.Add('Enable --offline mode');"
      echo "  OfflinePage.Add('Target: Windows');"
      echo "  OfflinePage.Add('Target: DOS');"
      echo "  OfflinePage.Add('Target: Linux');"
      echo "  OfflinePage.Add('Target: macOS');"
      echo "  OfflinePage.Add('Target: BSD');"
      echo "  OfflinePage.Values[1] := True;"
      echo "  OfflinePage.Values[3] := True;"
      set -- $deps_list
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
      set -- $deps_list
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
      set -- $deps_list
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
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    if MsgBox('Do you want to completely remove the Data Directory and all records for $pkg?', mbConfirmation, MB_YESNO) = idYes then begin"
        if [ "$OFFLINE" = "1" ]; then
          echo "      Exec('cmd.exe', '/c \"\"{app}\\libscript.cmd\"\" uninstall $pkg --purge-data --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        else
          echo "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --purge-data --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        fi
        echo "    end else begin"
        if [ "$OFFLINE" = "1" ]; then
          echo "      Exec('cmd.exe', '/c \"\"{app}\\libscript.cmd\"\" uninstall $pkg --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        else
          echo "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        fi
        echo "    end;"
      done
      echo "  end;"
      echo "end;"
      echo "  ActionPage: TInputOptionWizardPage;"
      echo "  OfflinePage: TInputOptionWizardPage;"

      set -- $deps_list
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
      echo "function GetAction(Param: String): String;"
      echo "begin"
      echo "  if ActionPage.Values[1] then Result := 'docker'"
      echo "  else if ActionPage.Values[2] then Result := 'docker_compose'"
      echo "  else if ActionPage.Values[3] then Result := 'msi'"
      echo "  else if ActionPage.Values[4] then Result := 'innosetup'"
      echo "  else if ActionPage.Values[5] then Result := 'nsis'"
      echo "  else if ActionPage.Values[6] then Result := 'pkg'"
      echo "  else if ActionPage.Values[7] then Result := 'dmg'"
      echo "  else if ActionPage.Values[8] then Result := 'deb'"
      echo "  else if ActionPage.Values[9] then Result := 'rpm'"
      echo "  else Result := 'install';"
      echo "end;"
      echo "function GetExtraArgs(Param: String): String;"
      echo "var S: String;"
      echo "begin"
      echo "  S := '';"
      echo "  if OfflinePage.Values[0] then S := S + ' --offline';"
      echo "  if OfflinePage.Values[1] then S := S + ' --os-windows';"
      echo "  if OfflinePage.Values[2] then S := S + ' --os-dos';"
      echo "  if OfflinePage.Values[3] then S := S + ' --os-linux';"
      echo "  if OfflinePage.Values[4] then S := S + ' --os-macos';"
      echo "  if OfflinePage.Values[5] then S := S + ' --os-bsd';"
      echo "  Result := S;"
      echo "end;"
      echo "function IsInstall: Boolean;"
      echo "begin Result := ActionPage.Values[0]; end;"
      echo "function IsGenerate: Boolean;"
      echo "begin Result := not ActionPage.Values[0]; end;"
      echo "function GetGenerateParams(Param: String): String;"
      echo "var S: String;"
      echo "begin"
      echo "  if '{app}' <> '' then"
      echo "    S := '/c \"\"\"{app}\\libscript.cmd\"\"\" package_as ' + GetAction('') + ' ';";
      echo "  else";
      echo "    S := '/c libscript.cmd package_as ' + GetAction('') + ' ';";
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  if IsComponentSelected('$pkg') then S := S + '$pkg $ver ';";
      done
      echo "  S := S + GetExtraArgs('');"
      echo "  Result := S;"
      echo "end;"
      echo "[Run]"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"\"{app}\\libscript.cmd\"\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"{code:Get_%s_%s}\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "Filename: \"cmd.exe\"; Parameters: \"$run_params\"; Components: $pkg; Flags: runhidden; Check: IsInstall"
      done
      if [ "$OFFLINE" = "1" ]; then
        echo "Filename: \"cmd.exe\"; Parameters: \"{code:GetGenerateParams}\"; WorkingDir: \"{app}\"; Flags: runhidden; Check: IsGenerate"
      else
        echo "Filename: \"cmd.exe\"; Parameters: \"{code:GetGenerateParams}\"; Flags: runhidden; Check: IsGenerate"
      fi
      exit 0
