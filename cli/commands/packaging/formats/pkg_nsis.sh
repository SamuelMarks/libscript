#!/bin/sh
# ## Overview
# Implements packaging logic for the 'nsis' format.
# 
# ## Usage
# This script is called by the packaging system and should not be executed manually.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
  . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/_common_installer_args.sh"
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
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      if [ "$OFFLINE" = "1" ]; then
        printf '%s\n' "Section \"Core\""
        printf '%s\n' "  SetOutPath \"\$INSTDIR\""
        printf '%s\n' "  File /r \"$LIBSCRIPT_ROOT_DIR\\*.*\""
        printf '%s\n' "SectionEnd"
      fi
      printf '%s\n' "Include nsDialogs.nsh"
      printf '%s\n' "Page components"

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
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
      printf '%s\n' "Page custom ActionPageCreate ActionPageLeave"
      printf '%s\n' "Page custom OptionsPageCreate OptionsPageLeave"
      printf '%s\n' "Page instfiles"
      printf '%s\n' ""

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "Section \"$pkg\" SEC_$pkg"
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"\$INSTDIR\\libscript.cmd\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(printf '%s\n' "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"\$VAL_%s_%s\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        printf '%s\n' "  \${If} \$Action_Choice == \"install\""
        printf '%s\n' "  ExecWait 'cmd.exe $run_params'"
        printf '%s\n' "  \${EndIf}"
        printf '%s\n' "SectionEnd"
      done

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
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

      printf '%s\n' "Var Dialog_Action"
      printf '%s\n' "Var R_Install"
      printf '%s\n' "Var R_Docker"
      printf '%s\n' "Var R_DC"
      printf '%s\n' "Var R_MSI"
      printf '%s\n' "Var R_Inno"
      printf '%s\n' "Var R_NSIS"
      printf '%s\n' "Var R_PKG"
      printf '%s\n' "Var R_DMG"
      printf '%s\n' "Var R_Deb"
      printf '%s\n' "Var R_RPM"
      printf '%s\n' "Var Action_Choice"
      printf '%s\n' "Var Dialog_Options"
      printf '%s\n' "Var C_Offline"
      printf '%s\n' "Var C_Win"
      printf '%s\n' "Var C_DOS"
      printf '%s\n' "Var C_Linux"
      printf '%s\n' "Var C_Mac"
      printf '%s\n' "Var C_BSD"
      printf '%s\n' "Var Opt_Offline"
      printf '%s\n' "Var Opt_Win"
      printf '%s\n' "Var Opt_DOS"
      printf '%s\n' "Var Opt_Linux"
      printf '%s\n' "Var Opt_Mac"
      printf '%s\n' "Var Opt_BSD"
      printf '%s\n' "Function ActionPageCreate"
      printf '%s\n' "  nsDialogs::Create 1018"
      printf '%s\n' "  Pop \$Dialog_Action"
      printf '%s\n' "  \${NSD_CreateLabel} 0 0 100% 12u \"What would you like to produce?\""
      printf '%s\n' "  Pop \$0"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 15u 100% 12u \"Install locally now\""
      printf '%s\n' "  Pop \$R_Install"
      printf '%s\n' "  \${NSD_Check} \$R_Install"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 30u 100% 12u \"Dockerfile\""
      printf '%s\n' "  Pop \$R_Docker"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 45u 100% 12u \"Dockerfiles + docker-compose\""
      printf '%s\n' "  Pop \$R_DC"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 60u 100% 12u \".msi installer\""
      printf '%s\n' "  Pop \$R_MSI"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 75u 100% 12u \".exe (InnoSetup)\""
      printf '%s\n' "  Pop \$R_Inno"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 90u 100% 12u \".exe (NSIS)\""
      printf '%s\n' "  Pop \$R_NSIS"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 105u 100% 12u \".pkg installer\""
      printf '%s\n' "  Pop \$R_PKG"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 120u 100% 12u \".dmg installer\""
      printf '%s\n' "  Pop \$R_DMG"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 135u 100% 12u \".deb package\""
      printf '%s\n' "  Pop \$R_Deb"
      printf '%s\n' "  \${NSD_CreateRadioButton} 0 150u 100% 12u \".rpm package\""
      printf '%s\n' "  Pop \$R_RPM"
      printf '%s\n' "  nsDialogs::Show"
      printf '%s\n' "FunctionEnd"
      printf '%s\n' "Function ActionPageLeave"
      printf '%s\n' "  StrCpy \$Action_Choice \"install\""
      printf '%s\n' "  \${NSD_GetState} \$R_Docker \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"docker\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "  \${NSD_GetState} \$R_DC \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"docker_compose\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "  \${NSD_GetState} \$R_MSI \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"msi\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "  \${NSD_GetState} \$R_Inno \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"innosetup\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "  \${NSD_GetState} \$R_NSIS \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"nsis\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "  \${NSD_GetState} \$R_Deb \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"deb\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "  \${NSD_GetState} \$R_RPM \$0"
      printf '%s\n' "  \${If} \$0 == \${BST_CHECKED}"
      printf '%s\n' "    StrCpy \$Action_Choice \"rpm\""
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "FunctionEnd"
      printf '%s\n' "Function OptionsPageCreate"
      printf '%s\n' "  nsDialogs::Create 1018"
      printf '%s\n' "  Pop \$Dialog_Options"
      printf '%s\n' "  \${NSD_CreateLabel} 0 0 100% 12u \"Options & OS Targets\""
      printf '%s\n' "  Pop \$0"
      printf '%s\n' "  \${NSD_CreateCheckbox} 0 15u 100% 12u \"Enable --offline mode\""
      printf '%s\n' "  Pop \$C_Offline"
      printf '%s\n' "  \${NSD_CreateCheckbox} 0 30u 100% 12u \"Target: Windows\""
      printf '%s\n' "  Pop \$C_Win"
      printf '%s\n' "  \${NSD_Check} \$C_Win"
      printf '%s\n' "  \${NSD_CreateCheckbox} 0 45u 100% 12u \"Target: DOS\""
      printf '%s\n' "  Pop \$C_DOS"
      printf '%s\n' "  \${NSD_CreateCheckbox} 0 60u 100% 12u \"Target: Linux\""
      printf '%s\n' "  Pop \$C_Linux"
      printf '%s\n' "  \${NSD_Check} \$C_Linux"
      printf '%s\n' "  \${NSD_CreateCheckbox} 0 75u 100% 12u \"Target: macOS\""
      printf '%s\n' "  Pop \$C_Mac"
      printf '%s\n' "  \${NSD_CreateCheckbox} 0 90u 100% 12u \"Target: BSD\""
      printf '%s\n' "  Pop \$C_BSD"
      printf '%s\n' "  nsDialogs::Show"
      printf '%s\n' "FunctionEnd"
      printf '%s\n' "Function OptionsPageLeave"
      printf '%s\n' "  \${NSD_GetState} \$C_Offline \$0"
      printf '%s\n' "  StrCpy \$Opt_Offline \$0"
      printf '%s\n' "  \${NSD_GetState} \$C_Win \$0"
      printf '%s\n' "  StrCpy \$Opt_Win \$0"
      printf '%s\n' "  \${NSD_GetState} \$C_DOS \$0"
      printf '%s\n' "  StrCpy \$Opt_DOS \$0"
      printf '%s\n' "  \${NSD_GetState} \$C_Linux \$0"
      printf '%s\n' "  StrCpy \$Opt_Linux \$0"
      printf '%s\n' "  \${NSD_GetState} \$C_Mac \$0"
      printf '%s\n' "  StrCpy \$Opt_Mac \$0"
      printf '%s\n' "  \${NSD_GetState} \$C_BSD \$0"
      printf '%s\n' "  StrCpy \$Opt_BSD \$0"
      printf '%s\n' "FunctionEnd"
      printf '%s\n' "Section \"-Generate\" SEC_GENERATE"
      printf '%s\n' "  \${If} \$Action_Choice != \"install\""
      printf '%s\n' "    Var /GLOBAL GenCmd"
      printf '%s\n' "    StrCpy \$GenCmd \"\""
      printf '%s\n' "    \${If} \$Opt_Offline == \${BST_CHECKED}"
      printf '%s\n' "      StrCpy \$GenCmd \"\$GenCmd --offline \""
      printf '%s\n' "    \${EndIf}"
      printf '%s\n' "    \${If} \$Opt_Win == \${BST_CHECKED}"
      printf '%s\n' "      StrCpy \$GenCmd \"\$GenCmd --os-windows \""
      printf '%s\n' "    \${EndIf}"
      printf '%s\n' "    \${If} \$Opt_DOS == \${BST_CHECKED}"
      printf '%s\n' "      StrCpy \$GenCmd \"\$GenCmd --os-dos \""
      printf '%s\n' "    \${EndIf}"
      printf '%s\n' "    \${If} \$Opt_Linux == \${BST_CHECKED}"
      printf '%s\n' "      StrCpy \$GenCmd \"\$GenCmd --os-linux \""
      printf '%s\n' "    \${EndIf}"
      printf '%s\n' "    \${If} \$Opt_Mac == \${BST_CHECKED}"
      printf '%s\n' "      StrCpy \$GenCmd \"\$GenCmd --os-macos \""
      printf '%s\n' "    \${EndIf}"
      printf '%s\n' "    \${If} \$Opt_BSD == \${BST_CHECKED}"
      printf '%s\n' "      StrCpy \$GenCmd \"\$GenCmd --os-bsd \""
      printf '%s\n' "    \${EndIf}"
      printf '%s\n' "    Var /GLOBAL PkgArgs"
      printf '%s\n' "    StrCpy \$PkgArgs \"\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "    SectionGetFlags \${SEC_$pkg} \$0"
        printf '%s\n' "    IntOp \$0 \$0 & 1"
        printf '%s\n' "    \${If} \$0 == 1"
        printf '%s\n' "      StrCpy \$PkgArgs \"\$PkgArgs $pkg $ver \""
        printf '%s\n' "    \${EndIf}"
      done
      if [ "$OFFLINE" = "1" ]; then
        printf '%s\n' "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" package_as \$Action_Choice \$PkgArgs \$GenCmd'"
      else
        printf '%s\n' "    ExecWait 'cmd.exe /c libscript.cmd package_as \$Action_Choice \$PkgArgs \$GenCmd'"
      fi
      printf '%s\n' "  \${EndIf}"
      printf '%s\n' "SectionEnd"
      # Uninstaller
      printf '%s\n' "Section \"Uninstall\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "  MessageBox MB_YESNO \"Do you want to completely remove the Data Directory and all records for $pkg?\" IDYES purge_$pkg IDNO keep_$pkg"
        printf '%s\n' "  purge_$pkg:"
        if [ "$OFFLINE" = "1" ]; then
          printf '%s\n' "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(printf '%s\n' "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        else
          printf '%s\n' "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(printf '%s\n' "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        fi
        printf '%s\n' "    Goto end_$pkg"
        printf '%s\n' "  keep_$pkg:"
        if [ "$OFFLINE" = "1" ]; then
          printf '%s\n' "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" uninstall $pkg --service-name \$VAL_${pkg}_$(printf '%s\n' "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        else
          printf '%s\n' "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --service-name \$VAL_${pkg}_$(printf '%s\n' "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        fi
        printf '%s\n' "  end_$pkg:"
      done
      printf '%s\n' "SectionEnd"

      exit 0
