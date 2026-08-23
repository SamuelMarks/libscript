#!/bin/sh
# ## Overview
# Template file for installer generation.
# 
# ## Usage
# This file is processed during the build phase and not executed directly.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $0 [OPTIONS]"
  printf '%s\n' "See script source or documentation for more details."
  exit 0
fi



      cat << EOF2
[Setup]
AppName=$APP_NAME
AppVersion=$APP_VERSION
AppPublisher=$APP_PUBLISHER
EOF2
      if [ -n "$APP_URL" ]; then
        printf '%s\n' "AppPublisherURL=$APP_URL"
        printf '%s\n' "AppSupportURL=$APP_URL"
        printf '%s\n' "AppUpdatesURL=$APP_URL"
      fi
      cat << EOF2
DefaultDirName={autopf}\\$APP_NAME
PrivilegesRequired=${inno_priv:-admin}
OutputDir=.
OutputBaseFilename=$OUT_FILE
EOF2
      if [ "$UPGRADE_CODE" != "PUT-GUID-HERE" ]; then printf '%s\n' "AppId=$UPGRADE_CODE"; fi
      if [ -n "$ICON_PATH" ]; then printf '%s\n' "SetupIconFile=$ICON_PATH"; fi
      if [ -n "$IMAGE_PATH" ]; then printf '%s\n' "WizardImageFile=$IMAGE_PATH"; fi
      if [ -n "$LICENSE_PATH" ]; then printf '%s\n' "LicenseFile=$LICENSE_PATH"; fi

      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      fi

      printf '%s\n' ""
      printf '%s\n' "[Types]"
      printf '%s\n' "Name: \"custom\"; Description: \"Custom installation\"; Flags: iscustom"
      printf '%s\n' "Name: \"full\"; Description: \"Full installation\""
      printf '%s\n' ""
      printf '%s\n' "[Components]"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "Name: \"$pkg\"; Description: \"$pkg\"; Types: full custom"
      done

      printf '%s\n' ""
      printf '%s\n' "[Code]"
      printf '%s\n' "var"

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            printf '%s\n' "  Page_$pkg: TInputQueryWizardPage;"
            printf '%s\n' "$vars_json" | jq -r '.key' | while read -r varname; do
              printf '%s\n' "  Var_${pkg}_${varname}: String;"
            done
          fi
        fi
      done

      printf '%s\n' "procedure InitializeWizard;"
      printf '%s\n' "begin"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            printf '%s\n' "  Page_$pkg := CreateInputQueryPage(wpSelectComponents, 'Configuration for $pkg', 'Please specify settings', '');"
            var_idx=0
            printf '%s\n' "$vars_json" | while read -r item; do
              desc=$(printf '%s\n' "$item" | jq -r '.desc')
              defval=$(printf '%s\n' "$item" | jq -r '.def')
              varname=$(printf '%s\n' "$item" | jq -r '.key')
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                printf '%s\n' "  Page_$pkg.Add('$desc:', True);"
              else
                printf '%s\n' "  Page_$pkg.Add('$desc:', False);"
              fi
              printf '%s\n' "  Page_$pkg.Values[$var_idx] := '$defval';"
              var_idx=$((var_idx + 1))
            done
          fi
        fi
      done
      printf '%s\n' "end;"

      printf '%s\n' "function ShouldSkipPage(PageID: Integer): Boolean;"
      printf '%s\n' "begin"
      printf '%s\n' "  Result := False;"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          if [ -n "$(jq -c '.properties' "$schema_file")" ]; then
            printf '%s\n' "  if (PageID = Page_$pkg.ID) and not IsComponentSelected('$pkg') then"
            printf '%s\n' "    Result := True;"
          fi
        fi
      done
      printf '%s\n' "end;"

      printf '%s\n' "function NextButtonClick(PageId: Integer): Boolean;"
      printf '%s\n' "var"
      printf '%s\n' "  ResultCode: Integer;"
      printf '%s\n' "begin"
      printf '%s\n' "  Result := True;"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            printf '%s\n' "  if PageId = Page_$pkg.ID then begin"
            var_idx=0
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"*) true;; *) false;; esac; then
                printf '%s\n' "    if (Page_$pkg.Values[$var_idx] <> '') then begin"
                printf '%s\n' "      if Exec('cmd.exe', '/c netstat -an | findstr /R /C:"":'' + Page_$pkg.Values[$var_idx] + '' .*LISTENING""', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then begin"
                printf '%s\n' "        if ResultCode = 0 then begin"
                printf '%s\n' "          MsgBox('Port ' + Page_$pkg.Values[$var_idx] + ' is already in use. Please select a different port.', mbError, MB_OK);"
                printf '%s\n' "          Result := False;"
                printf '%s\n' "          Exit;"
                printf '%s\n' "        end;"
                printf '%s\n' "      end;"
                printf '%s\n' "    end;"
              fi
              var_idx=$((var_idx + 1))
            done
            printf '%s\n' "  end;"
          fi
        fi
      done
      printf '%s\n' "end;"

      # Uninstallation Hooks
      printf '%s\n' "procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);"
      printf '%s\n' "var"
      printf '%s\n' "  ResultCode: Integer;"
      printf '%s\n' "begin"
      printf '%s\n' "  if CurUninstallStep = usUninstall then begin"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "    if MsgBox('Do you want to completely remove the Data Directory and all records for $pkg?', mbConfirmation, MB_YESNO) = idYes then begin"
        printf '%s\n' "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --purge-data --service-name ' + Get_${pkg}_$(printf '%s\n' "$pkg" | tr "[:lower:]" "[:upper:]")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        printf '%s\n' "    end else begin"
        printf '%s\n' "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --service-name ' + Get_${pkg}_$(printf '%s\n' "$pkg" | tr "[:lower:]" "[:upper:]")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        printf '%s\n' "    end;"
      done
      printf '%s\n' "  end;"
      printf '%s\n' "end;"

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            var_idx=0
            for varname in $vars_json; do
              printf '%s\n' "function Get_${pkg}_${varname}(Param: String): String;"
              printf '%s\n' "begin"
              printf '%s\n' "  Result := Page_$pkg.Values[$var_idx];"
              printf '%s\n' "end;"
              var_idx=$((var_idx + 1))
            done
          fi
        fi
      done

      printf '%s\n' ""
      printf '%s\n' "[Run]"
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        run_params="/c libscript.cmd install-service $pkg $ver"
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(printf '%s\n' "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"{code:Get_%s_%s}\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        printf '%s\n' "Filename: \"cmd.exe\"; Parameters: \"$run_params\"; Components: $pkg; Flags: runhidden"
      done
      exit 0
