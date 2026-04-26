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
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      if [ "$OFFLINE" = "1" ]; then
        echo "Section \"Core\""
        echo "  SetOutPath \"\$INSTDIR\""
        echo "  File /r \"$SCRIPT_DIR\\*.*\""
        echo "SectionEnd"
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
      echo "Page custom ActionPageCreate ActionPageLeave"
      echo "Page custom OptionsPageCreate OptionsPageLeave"
      echo "Page instfiles"
      echo ""
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Section \"$pkg\" SEC_$pkg"
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"\$INSTDIR\\libscript.cmd\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"\$VAL_%s_%s\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "  \${If} \$Action_Choice == \"install\""
        echo "  ExecWait 'cmd.exe $run_params'"
        echo "  \${EndIf}"
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

      echo "Var Dialog_Action"
      echo "Var R_Install"
      echo "Var R_Docker"
      echo "Var R_DC"
      echo "Var R_MSI"
      echo "Var R_Inno"
      echo "Var R_NSIS"
      echo "Var R_PKG"
      echo "Var R_DMG"
      echo "Var R_Deb"
      echo "Var R_RPM"
      echo "Var Action_Choice"
      echo "Var Dialog_Options"
      echo "Var C_Offline"
      echo "Var C_Win"
      echo "Var C_DOS"
      echo "Var C_Linux"
      echo "Var C_Mac"
      echo "Var C_BSD"
      echo "Var Opt_Offline"
      echo "Var Opt_Win"
      echo "Var Opt_DOS"
      echo "Var Opt_Linux"
      echo "Var Opt_Mac"
      echo "Var Opt_BSD"
      echo "Function ActionPageCreate"
      echo "  nsDialogs::Create 1018"
      echo "  Pop \$Dialog_Action"
      echo "  \${NSD_CreateLabel} 0 0 100% 12u \"What would you like to produce?\""
      echo "  Pop \$0"
      echo "  \${NSD_CreateRadioButton} 0 15u 100% 12u \"Install locally now\""
      echo "  Pop \$R_Install"
      echo "  \${NSD_Check} \$R_Install"
      echo "  \${NSD_CreateRadioButton} 0 30u 100% 12u \"Dockerfile\""
      echo "  Pop \$R_Docker"
      echo "  \${NSD_CreateRadioButton} 0 45u 100% 12u \"Dockerfiles + docker-compose\""
      echo "  Pop \$R_DC"
      echo "  \${NSD_CreateRadioButton} 0 60u 100% 12u \".msi installer\""
      echo "  Pop \$R_MSI"
      echo "  \${NSD_CreateRadioButton} 0 75u 100% 12u \".exe (InnoSetup)\""
      echo "  Pop \$R_Inno"
      echo "  \${NSD_CreateRadioButton} 0 90u 100% 12u \".exe (NSIS)\""
      echo "  Pop \$R_NSIS"
      echo "  \${NSD_CreateRadioButton} 0 105u 100% 12u \".pkg installer\""
      echo "  Pop \$R_PKG"
      echo "  \${NSD_CreateRadioButton} 0 120u 100% 12u \".dmg installer\""
      echo "  Pop \$R_DMG"
      echo "  \${NSD_CreateRadioButton} 0 135u 100% 12u \".deb package\""
      echo "  Pop \$R_Deb"
      echo "  \${NSD_CreateRadioButton} 0 150u 100% 12u \".rpm package\""
      echo "  Pop \$R_RPM"
      echo "  nsDialogs::Show"
      echo "FunctionEnd"
      echo "Function ActionPageLeave"
      echo "  StrCpy \$Action_Choice \"install\""
      echo "  \${NSD_GetState} \$R_Docker \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"docker\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_DC \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"docker_compose\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_MSI \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"msi\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_Inno \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"innosetup\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_NSIS \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"nsis\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_Deb \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"deb\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_RPM \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"rpm\""
      echo "  \${EndIf}"
      echo "FunctionEnd"
      echo "Function OptionsPageCreate"
      echo "  nsDialogs::Create 1018"
      echo "  Pop \$Dialog_Options"
      echo "  \${NSD_CreateLabel} 0 0 100% 12u \"Options & OS Targets\""
      echo "  Pop \$0"
      echo "  \${NSD_CreateCheckbox} 0 15u 100% 12u \"Enable --offline mode\""
      echo "  Pop \$C_Offline"
      echo "  \${NSD_CreateCheckbox} 0 30u 100% 12u \"Target: Windows\""
      echo "  Pop \$C_Win"
      echo "  \${NSD_Check} \$C_Win"
      echo "  \${NSD_CreateCheckbox} 0 45u 100% 12u \"Target: DOS\""
      echo "  Pop \$C_DOS"
      echo "  \${NSD_CreateCheckbox} 0 60u 100% 12u \"Target: Linux\""
      echo "  Pop \$C_Linux"
      echo "  \${NSD_Check} \$C_Linux"
      echo "  \${NSD_CreateCheckbox} 0 75u 100% 12u \"Target: macOS\""
      echo "  Pop \$C_Mac"
      echo "  \${NSD_CreateCheckbox} 0 90u 100% 12u \"Target: BSD\""
      echo "  Pop \$C_BSD"
      echo "  nsDialogs::Show"
      echo "FunctionEnd"
      echo "Function OptionsPageLeave"
      echo "  \${NSD_GetState} \$C_Offline \$0"
      echo "  StrCpy \$Opt_Offline \$0"
      echo "  \${NSD_GetState} \$C_Win \$0"
      echo "  StrCpy \$Opt_Win \$0"
      echo "  \${NSD_GetState} \$C_DOS \$0"
      echo "  StrCpy \$Opt_DOS \$0"
      echo "  \${NSD_GetState} \$C_Linux \$0"
      echo "  StrCpy \$Opt_Linux \$0"
      echo "  \${NSD_GetState} \$C_Mac \$0"
      echo "  StrCpy \$Opt_Mac \$0"
      echo "  \${NSD_GetState} \$C_BSD \$0"
      echo "  StrCpy \$Opt_BSD \$0"
      echo "FunctionEnd"
      echo "Section \"-Generate\" SEC_GENERATE"
      echo "  \${If} \$Action_Choice != \"install\""
      echo "    Var /GLOBAL GenCmd"
      echo "    StrCpy \$GenCmd \"\""
      echo "    \${If} \$Opt_Offline == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --offline \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_Win == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-windows \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_DOS == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-dos \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_Linux == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-linux \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_Mac == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-macos \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_BSD == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-bsd \""
      echo "    \${EndIf}"
      echo "    Var /GLOBAL PkgArgs"
      echo "    StrCpy \$PkgArgs \"\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    SectionGetFlags \${SEC_$pkg} \$0"
        echo "    IntOp \$0 \$0 & 1"
        echo "    \${If} \$0 == 1"
        echo "      StrCpy \$PkgArgs \"\$PkgArgs $pkg $ver \""
        echo "    \${EndIf}"
      done
      if [ "$OFFLINE" = "1" ]; then
        echo "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" package_as \$Action_Choice \$PkgArgs \$GenCmd'"
      else
        echo "    ExecWait 'cmd.exe /c libscript.cmd package_as \$Action_Choice \$PkgArgs \$GenCmd'"
      fi
      echo "  \${EndIf}"
      echo "SectionEnd"
      # Uninstaller
      echo "Section \"Uninstall\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  MessageBox MB_YESNO \"Do you want to completely remove the Data Directory and all records for $pkg?\" IDYES purge_$pkg IDNO keep_$pkg"
        echo "  purge_$pkg:"
        if [ "$OFFLINE" = "1" ]; then
          echo "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        else
          echo "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        fi
        echo "    Goto end_$pkg"
        echo "  keep_$pkg:"
        if [ "$OFFLINE" = "1" ]; then
          echo "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" uninstall $pkg --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        else
          echo "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        fi
        echo "  end_$pkg:"
      done
      echo "SectionEnd"

      exit 0
