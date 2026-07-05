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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $0 [OPTIONS]"
  printf '%s\n' "See script source or documentation for more details."
  exit 0
fi



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
      if [ -n "$ICON_PATH" ]; then printf '%s\n' "Icon \"$ICON_PATH\""; fi
      printf '%s\n' ""

      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      fi

      printf '%s\n' "Include nsDialogs.nsh"
      printf '%s\n' "Page components"

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            printf '%s\n' "Var Dialog_$pkg"
            printf '%s\n' "$vars_json" | jq -r '.key' | while read -r varname; do
              printf '%s\n' "Var HWND_${pkg}_${varname}"
              printf '%s\n' "Var VAL_${pkg}_${varname}"
            done

            printf '%s\n' "Page custom pgCustom_$pkg pgLeave_$pkg"
          fi
        fi
      done

      if [ -n "$LICENSE_PATH" ]; then printf '%s\n' "Page license \"\" \"$LICENSE_PATH\""; fi
      printf '%s\n' "Page instfiles"
      printf '%s\n' ""

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "Section \"$pkg\" SEC_$pkg"
        run_params="/c libscript.cmd install-service $pkg $ver"
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(printf '%s\n' "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"\$VAL_%s_%s\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        printf '%s\n' "  ExecWait 'cmd.exe $run_params'"
        printf '%s\n' "SectionEnd"
      done

      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            printf '%s\n' "Function pgCustom_$pkg"
            printf '%s\n' "  SectionGetFlags \${SEC_$pkg} \$0"
            printf '%s\n' "  IntOp \$0 \$0 & 1"
            printf '%s\n' "  IntCmp \$0 1 +2"
            printf '%s\n' "    Abort"
            printf '%s\n' "  nsDialogs::Create 1018"
            printf '%s\n' "  Pop \$Dialog_$pkg"

            y=0
            printf '%s\n' "$vars_json" | while read -r item; do
              varname=$(printf '%s\n' "$item" | jq -r '.key')
              desc=$(printf '%s\n' "$item" | jq -r '.desc')
              defval=$(printf '%s\n' "$item" | jq -r '.def')
              if [ $y -gt 130 ]; then break; fi

              printf '%s\n' "  \${NSD_CreateLabel} 0 ${y}u 100% 12u \"$desc:\""
              printf '%s\n' "  Pop \$0"
              y=$((y + 12))

              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                printf '%s\n' "  \${NSD_CreatePassword} 0 ${y}u 100% 12u \"$defval\""
              else
                printf '%s\n' "  \${NSD_CreateText} 0 ${y}u 100% 12u \"$defval\""
              fi
              printf '%s\n' "  Pop \$HWND_${pkg}_${varname}"
              y=$((y + 14))
            done
            printf '%s\n' "  nsDialogs::Show"
            printf '%s\n' "FunctionEnd"

            printf '%s\n' "Function pgLeave_$pkg"
            printf '%s\n' "$vars_json" | jq -r '.key' | while read -r varname; do
              printf '%s\n' "  \${NSD_GetText} \$HWND_${pkg}_${varname} \$VAL_${pkg}_${varname}"

              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                printf '%s\n' "  StrCmp \$VAL_${pkg}_${varname} \"\" +4 0"
                printf '%s\n' "  nsExec::ExecToStack 'cmd.exe /c netstat -an | findstr /R /C:\":\$VAL_${pkg}_${varname} .*LISTENING\"'"
                printf '%s\n' "  Pop \$0"
                printf '%s\n' "  IntCmp \$0 0 0 +3"
                printf '%s\n' "    MessageBox MB_ICONSTOP \"Port \$VAL_${pkg}_${varname} is already in use.\""
                printf '%s\n' "    Abort"
              fi
            done
            printf '%s\n' "FunctionEnd"
          fi
        fi
      done

      # Uninstaller
      printf '%s\n' "Section \"Uninstall\""
      set -- "$deps_list"
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "  MessageBox MB_YESNO \"Do you want to completely remove the Data Directory and all records for $pkg?\" IDYES purge_$pkg IDNO keep_$pkg"
        printf '%s\n' "  purge_$pkg:"
        printf '%s\n' "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(printf '%s\n' "$pkg" | tr "a-z" "A-Z")_SERVICE_NAME'"
        printf '%s\n' "    Goto end_$pkg"
        printf '%s\n' "  keep_$pkg:"
        printf '%s\n' "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --service-name \$VAL_${pkg}_$(printf '%s\n' "$pkg" | tr "a-z" "A-Z")_SERVICE_NAME'"
        printf '%s\n' "  end_$pkg:"
      done
      printf '%s\n' "SectionEnd"

      exit 0
