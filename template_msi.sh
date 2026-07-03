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



      wxs_file="${OUT_FILE}.wxs"
      exec 3>&1
      exec 1> "$wxs_file"

      cat << EOF2
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product ID="$PRODUCT_CODE" Name="$APP_NAME" Language="1033" Version="$APP_VERSION" Manufacturer="$APP_PUBLISHER" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" CompresseD="yes" InstallScope="$install_scope" Description="$WELCOME_TEXT" />
    <Media ID="1" Cabinet="media1.cab" EmbedCab="yes" />
EOF2
      if [ -n "$ICON_PATH" ]; then
        printf '%s\n' "    <Icon Id=\"AppIcon.ico\" SourceFile=\"$ICON_PATH\"/>"
        printf '%s\n' "    <Property Id=\"ARPPRODUCTICON\" Value=\"AppIcon.ico\" />"
      fi
      if [ -n "$APP_URL" ]; then
        printf '%s\n' "    <Property Id=\"ARPURLINFOABOUT\" Value=\"$APP_URL\" />"
      fi

      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      fi

      printf '%s\n' "    <Directory Id=\"TARGETDIR\" Name=\"SourceDir\">"
      printf '%s\n' "      <Directory Id=\"ProgramFilesFolder\">"
      printf '%s\n' "        <Directory Id=\"INSTALLFOLDER\" Name=\"$APP_NAME\" />"
      printf '%s\n' "      </Directory>"
      printf '%s\n' "    </Directory>"

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "Function CheckPorts_$pkg()" > "validate_${pkg}.vbs"
        printf '%s\n' "  Session.Property(\"VALID_$pkg\") = \"1\"" >> "validate_${pkg}.vbs"
        printf '%s\n' "  Dim shell, exec, port" >> "validate_${pkg}.vbs"
        printf '%s\n' "  Set shell = CreateObject(\"WScript.Shell\")" >> "validate_${pkg}.vbs"

        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                printf '%s\n' "  port = Session.Property(\"PROP_${pkg}_${varname}\")" >> "validate_${pkg}.vbs"
                printf '%s\n' "  If port <> \"\" Then" >> "validate_${pkg}.vbs"
                printf '%s\n' "    Set exec = shell.Exec(\"cmd.exe /c netstat -an | findstr /R /C:"":\" & port & \" .*LISTENING\"\"\")" >> "validate_${pkg}.vbs"
                printf '%s\n' "    exec.StdOut.ReadAll()" >> "validate_${pkg}.vbs"
                printf '%s\n' "    If exec.ExitCode = 0 Then" >> "validate_${pkg}.vbs"
                printf '%s\n' "      MsgBox \"Port \" & port & \" is already in use.\", 16, \"Validation Error\"" >> "validate_${pkg}.vbs"
                printf '%s\n' "      Session.Property(\"VALID_$pkg\") = \"0\"" >> "validate_${pkg}.vbs"
                printf '%s\n' "    End If" >> "validate_${pkg}.vbs"
                printf '%s\n' "  End If" >> "validate_${pkg}.vbs"
              fi
            done
          fi
        fi
        printf '%s\n' "End Function" >> "validate_${pkg}.vbs"
        printf '%s\n' "    <Binary Id=\"Bin_Val_$pkg\" SourceFile=\"validate_${pkg}.vbs\" />"
        printf '%s\n' "    <CustomAction Id=\"CA_Val_$pkg\" BinaryKey=\"Bin_Val_$pkg\" VBScriptCall=\"CheckPorts_$pkg\" Return=\"check\" />"
      done

      # Features
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "    <Feature Id=\"Feature_$pkg\" Title=\"Install $pkg\" Level=\"1\">"
        printf '%s\n' "      <ComponentGroupRef Id=\"ProductComponents\" />"
        printf '%s\n' "    </Feature>"
      done

      # UI Generation
      printf '%s\n' "    <UI Id=\"CustomUI\">"
      printf '%s\n' "      <Property Id=\"DefaultUIFont\" Value=\"WixUI_Font_Normal\" />"

      printf '%s\n' "      <Dialog Id=\"Dlg_Features\" Width=\"370\" Height=\"270\" Title=\"Select Components\">"
      printf '%s\n' "        <Control Id=\"Lbl_Select\" Type=\"Text\" X=\"20\" Y=\"10\" Width=\"330\" Height=\"15\" Text=\"Select the components you want to install:\" />"
      y=30
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "        <Control Id=\"Chk_$pkg\" Type=\"CheckBox\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Property=\"INSTALL_$pkg\" CheckBoxValue=\"1\" Text=\"Install $pkg\" />"
        y=$((y + 20))
      done
      printf '%s\n' "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      printf '%s\n' "        </Control>"
      printf '%s\n' "      </Dialog>"

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "      <Property Id=\"INSTALL_$pkg\" Value=\"1\" Secure=\"yes\" />"
      done

      set -- $deps_list
      has_custom_ui=0
      dialogs=""
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            has_custom_ui=1
            printf '%s\n' "      <Dialog Id=\"Dlg_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Configuration for ${pkg}\">"
            y=20
            printf '%s\n' "$vars_json" | while read -r item; do
              varname=$(printf '%s\n' "$item" | jq -r '.key')
              desc=$(printf '%s\n' "$item" | jq -r '.desc')
              defval=$(printf '%s\n' "$item" | jq -r '.def')

              if [ $y -gt 220 ]; then break; fi

              printf '%s\n' "        <Control Id=\"Lbl_${varname}\" Type=\"Text\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Text=\"${desc}:\" />"
              y=$((y + 15))
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                printf '%s\n' "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" Password=\"yes\" />"
              else
                printf '%s\n' "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" />"
              fi
              y=$((y + 20))
            done
            printf '%s\n' "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
            printf '%s\n' "          <Publish Event=\"DoAction\" Value=\"CA_Val_$pkg\">1</Publish>"
            printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\"><![CDATA[VALID_$pkg=\"1\"]]></Publish>"
            printf '%s\n' "        </Control>"
            printf '%s\n' "      </Dialog>"

            printf '%s\n' "$vars_json" | while read -r item; do
              varname=$(printf '%s\n' "$item" | jq -r '.key')
              defval=$(printf '%s\n' "$item" | jq -r '.def')
              printf '%s\n' "    <Property Id=\"PROP_${pkg}_${varname}\" Value=\"${defval}\" Secure=\"yes\" />"
            done

            dialogs="$dialogs Dlg_${pkg}"
          fi
        fi
      done

      # MSI Uninstaller Confirmations
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "      <Dialog Id=\"Dlg_Uninst_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Uninstall $pkg\">"
        printf '%s\n' "        <Control Id=\"Msg\" Type=\"Text\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"30\" Text=\"Do you want to completely remove the Data Directory and all records for $pkg?\" />"
        printf '%s\n' "        <Control Id=\"YesBtn\" Type=\"PushButton\" X=\"100\" Y=\"100\" Width=\"56\" Height=\"17\" Text=\"Yes\">"
        printf '%s\n' "          <Publish Property=\"PURGE_$pkg\" Value=\"--purge-data\">1</Publish>"
        printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
        printf '%s\n' "        </Control>"
        printf '%s\n' "        <Control Id=\"NoBtn\" Type=\"PushButton\" X=\"170\" Y=\"100\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"No\">"
        printf '%s\n' "          <Publish Property=\"PURGE_$pkg\" Value=\"\">1</Publish>"
        printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
        printf '%s\n' "        </Control>"
        printf '%s\n' "      </Dialog>"
        printf '%s\n' "      <Property Id=\"PURGE_$pkg\" Value=\"\" Secure=\"yes\" />"
        dialogs="$dialogs Dlg_Uninst_${pkg}"
      done

      printf '%s\n' "      <InstallUISequence>"
      printf '%s\n' "        <Show Dialog=\"Dlg_Features\" After=\"CostFinalize\">NOT Installed</Show>"
      last_dlg="Dlg_Features"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        has_dlg=0
        for d in $dialogs; do
          if [ "$d" = "Dlg_${pkg}" ]; then has_dlg=1; break; fi
        done
        if [ "$has_dlg" = "1" ]; then
          printf '%s\n' "        <Show Dialog=\"Dlg_${pkg}\" After=\"$last_dlg\"><![CDATA[NOT Installed AND INSTALL_$pkg=\"1\"]]></Show>"
          last_dlg="Dlg_${pkg}"
        fi
      done

      # UI sequence for uninstall
      last_uninst_dlg="CostFinalize"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "        <Show Dialog=\"Dlg_Uninst_${pkg}\" After=\"$last_uninst_dlg\">REMOVE=\"ALL\"</Show>"
        last_uninst_dlg="Dlg_Uninst_${pkg}"
      done
      printf '%s\n' "      </InstallUISequence>"
      printf '%s\n' "    </UI>"

      # Install Actions
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        run_params="/c libscript.cmd install_service $pkg $ver"
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(printf '%s\n' "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"[PROP_%s_%s]\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        printf '%s\n' "    <CustomAction Id=\"Install$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe $run_params\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"

        # Uninstall Actions
        printf '%s\n' "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd uninstall $pkg [PURGE_$pkg] --service-name [PROP_${pkg}_$(printf '%s\n' "$pkg" | tr "a-z" "A-Z")_SERVICE_NAME]\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
      done

      printf '%s\n' "    <InstallExecuteSequence>"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "      <Custom Action=\"Install$pkg\" Before=\"InstallFinalize\"><![CDATA[NOT Installed AND INSTALL_$pkg=\"1\"]]></Custom>"
        printf '%s\n' "      <Custom Action=\"Uninstall$pkg\" Before=\"RemoveFiles\">REMOVE=\"ALL\"</Custom>"
      done
      printf '%s\n' "    </InstallExecuteSequence>"

      printf '%s\n' "  </Product>"
      printf '%s\n' "  <Fragment>"
      printf '%s\n' "    <ComponentGroup Id=\"ProductComponents\" Directory=\"INSTALLFOLDER\">"
      printf '%s\n' "    </ComponentGroup>"
      printf '%s\n' "  </Fragment>"
      printf '%s\n' "</Wix>"

      exec 1>&3 3>&-

      if [ "$OS" = "Windows_NT" ] || command -v candle.exe >/dev/null 2>&1 || command -v wix.exe >/dev/null 2>&1; then
        if command -v wix.exe >/dev/null 2>&1; then
          wix.exe build -ext WixToolset.UI.wixext -o "${OUT_FILE}.msi" "$wxs_file"
        else
          candle.exe "$wxs_file"
          light.exe -ext WixUIExtension -out "${OUT_FILE}.msi" "${OUT_FILE}.wixobj"
        fi
      else
        wixl -o "${OUT_FILE}.msi" "$wxs_file"
      fi
      exit 0
