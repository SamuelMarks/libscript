#!/bin/sh
# ## Overview
# Template file for installer generation.
# 
# ## Usage
# This file is processed during the build phase and not executed directly.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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



      wxs_file="${OUT_FILE}.wxs"
      exec 3>&1
      exec 1> "$wxs_file"

      cat << EOF2
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="$PRODUCT_CODE" Name="$APP_NAME" Language="1033" Version="$APP_VERSION" Manufacturer="$APP_PUBLISHER" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="${install_scope:-perMachine}" Description="${WELCOME_TEXT:-$APP_NAME Installer}" />
    <Media Id="1" Cabinet="media1.cab" EmbedCab="yes" />
EOF2
      if [ -n "${ICON_PATH:-}" ]; then
        printf '%s\n' "    <Icon Id=\"AppIcon.ico\" SourceFile=\"$ICON_PATH\"/>"
        printf '%s\n' "    <Property Id=\"ARPPRODUCTICON\" Value=\"AppIcon.ico\" />"
      fi
      if [ -n "${APP_URL:-}" ]; then
        printf '%s\n' "    <Property Id=\"ARPURLINFOABOUT\" Value=\"$APP_URL\" />"
      fi
      if [ -n "${BANNER_TOP_PATH:-}" ] && [ -f "$BANNER_TOP_PATH" ]; then
        printf '%s\n' "    <WixVariable Id=\"WixUIBannerBmp\" Value=\"$BANNER_TOP_PATH\" />"
      fi
      if [ -n "${BANNER_SIDE_PATH:-}" ] && [ -f "$BANNER_SIDE_PATH" ]; then
        printf '%s\n' "    <WixVariable Id=\"WixUIDialogBmp\" Value=\"$BANNER_SIDE_PATH\" />"
      fi

      rtf_license_file=""
      if [ -n "${LICENSE_PATH:-}" ] && [ -f "$LICENSE_PATH" ]; then
        case "$LICENSE_PATH" in
          *.rtf)
            rtf_license_file="$LICENSE_PATH"
            ;;
          *)
            rtf_license_file="${OUT_FILE}_license.rtf"
            printf '{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}}\\fs20\n' > "$rtf_license_file"
            sed 's/\\/\\\\/g; s/{/\\{/g; s/}/\\}/g; s/$/\\par/' "$LICENSE_PATH" >> "$rtf_license_file"
            printf '}\n' >> "$rtf_license_file"
            ;;
        esac
        printf '%s\n' "    <WixVariable Id=\"WixUILicenseRtf\" Value=\"$rtf_license_file\" />"
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

      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        {
          printf '%s\n' "Function CheckPorts_$pkg()"
          printf '%s\n' "  Session.Property(\"VALID_$pkg\") = \"1\""
          printf '%s\n' "  Dim shell, exec, port"
          printf '%s\n' "  Set shell = CreateObject(\"WScript.Shell\")"
        } > "validate_${pkg}.vbs"

        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"*) true;; *) false;; esac; then
                {
                  printf '%s\n' "  port = Session.Property(\"PROP_${pkg}_${varname}\")"
                  printf '%s\n' "  If port <> \"\" Then"
                  printf '%s\n' "    Set exec = shell.Exec(\"cmd.exe /c netstat -an | findstr /R /C:"":\" & port & \" .*LISTENING\"\"\")"
                  printf '%s\n' "    exec.StdOut.ReadAll()"
                  printf '%s\n' "    If exec.ExitCode = 0 Then"
                  printf '%s\n' "      MsgBox \"Port \" & port & \" is already in use.\", 16, \"Validation Error\""
                  printf '%s\n' "      Session.Property(\"VALID_$pkg\") = \"0\""
                  printf '%s\n' "    End If"
                  printf '%s\n' "  End If"
                } >> "validate_${pkg}.vbs"
              fi
            done
          fi
        fi
        printf '%s\n' "End Function" >> "validate_${pkg}.vbs"
        printf '%s\n' "    <Binary Id=\"Bin_Val_$pkg\" SourceFile=\"validate_${pkg}.vbs\" />"
        printf '%s\n' "    <CustomAction Id=\"CA_Val_$pkg\" BinaryKey=\"Bin_Val_$pkg\" VBScriptCall=\"CheckPorts_$pkg\" Return=\"check\" />"
      done

      # Features
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "    <Feature Id=\"Feature_$pkg\" Title=\"Install $pkg\" Level=\"1\">"
        printf '%s\n' "      <ComponentGroupRef Id=\"ProductComponents\" />"
        printf '%s\n' "    </Feature>"
      done

      # Hide sensitive password and key properties from verbose logs
      hidden_props=""
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          for varname in $vars_json; do
            if case "$varname" in *"_PASSWORD"*|*"_KEY"*|*"_SECRET"*|*"_TOKEN"*) true;; *) false;; esac; then
              hidden_props="${hidden_props};PROP_${pkg}_${varname}"
            fi
          done
        fi
      done
      if [ -n "$hidden_props" ]; then
        hidden_props=$(printf '%s\n' "$hidden_props" | sed 's/^;//')
        printf '%s\n' "    <Property Id=\"MsiHiddenProperties\" Value=\"$hidden_props\" />"
      fi

      # UI Generation
      printf '%s\n' "    <UI Id=\"CustomUI\">"
      printf '%s\n' "      <Property Id=\"DefaultUIFont\" Value=\"WixUI_Font_Normal\" />"

      # License Agreement Dialog if requested
      if [ -n "$rtf_license_file" ]; then
        printf '%s\n' "      <Dialog Id=\"Dlg_License\" Width=\"370\" Height=\"270\" Title=\"License Agreement\">"
        printf '%s\n' "        <Control Id=\"Title\" Type=\"Text\" X=\"15\" Y=\"6\" Width=\"340\" Height=\"15\" Transparent=\"yes\" NoPrefix=\"yes\" Text=\"Please read and accept the license terms:\" />"
        printf '%s\n' "        <Control Id=\"AgreementText\" Type=\"ScrollableText\" X=\"20\" Y=\"25\" Width=\"330\" Height=\"180\" Sunken=\"yes\" TabSkip=\"no\">"
        printf '%s\n' "          <Text SourceFile=\"$rtf_license_file\" />"
        printf '%s\n' "        </Control>"
        printf '%s\n' "        <Control Id=\"LicenseAcceptedCheckBox\" Type=\"CheckBox\" X=\"20\" Y=\"212\" Width=\"330\" Height=\"18\" Property=\"LICENSE_ACCEPTED\" CheckBoxValue=\"1\" Text=\"${AGREEMENT_TEXT:-I accept the terms in the License Agreement}\" />"
        printf '%s\n' "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
        printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\"><![CDATA[LICENSE_ACCEPTED=\"1\"]]></Publish>"
        printf '%s\n' "          <Condition Action=\"disable\"><![CDATA[LICENSE_ACCEPTED<>\"1\"]]></Condition>"
        printf '%s\n' "          <Condition Action=\"enable\"><![CDATA[LICENSE_ACCEPTED=\"1\"]]></Condition>"
        printf '%s\n' "        </Control>"
        printf '%s\n' "      </Dialog>"
        printf '%s\n' "      <Property Id=\"LICENSE_ACCEPTED\" Value=\"0\" Secure=\"yes\" />"
      fi

      # Multi-license agreement dialogs for bundled dependencies
      # shellcheck disable=SC2086
      set -- $deps_list
      license_dialogs=""
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_man=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "manifest.json" | grep "/$pkg/manifest.json" | head -n 1)
        pkg_spdx="MIT"
        pkg_title="$pkg"
        if [ -n "$pkg_man" ] && [ -f "$pkg_man" ]; then
          pkg_spdx=$(jq -r '.license // "MIT"' "$pkg_man" 2>/dev/null || printf 'MIT')
          pkg_title=$(jq -r '.title // .name' "$pkg_man" 2>/dev/null || printf '%s' "$pkg")
        fi

        pkg_rtf="${OUT_FILE}_${pkg}_license.rtf"
        canon_rtf=""
        canon_txt=""
        for _lic_dir in "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/packaging/licenses" \
                        "${LIBSCRIPT_ROOT_DIR}/cc0-assets/libscript/packaging/licenses"; do
          if [ -z "$canon_rtf" ] && [ -f "$_lic_dir/${pkg_spdx}.rtf" ]; then
            canon_rtf="$_lic_dir/${pkg_spdx}.rtf"
          fi
          if [ -z "$canon_txt" ] && [ -f "$_lic_dir/${pkg_spdx}.txt" ]; then
            canon_txt="$_lic_dir/${pkg_spdx}.txt"
          fi
        done

        if [ -n "$canon_rtf" ] && [ -f "$canon_rtf" ]; then
          cp "$canon_rtf" "$pkg_rtf"
        elif [ -n "$canon_txt" ] && [ -f "$canon_txt" ]; then
          printf '{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}}\\fs20\n' > "$pkg_rtf"
          sed 's/\\/\\\\/g; s/{/\\{/g; s/}/\\}/g; s/$/\\par/' "$canon_txt" >> "$pkg_rtf"
          printf '}\n' >> "$pkg_rtf"
        else
          printf '{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}}\\fs20\n' > "$pkg_rtf"
          printf 'License terms for %s (%s).\\par\n' "$pkg_title" "$pkg_spdx" >> "$pkg_rtf"
          printf '}\n' >> "$pkg_rtf"
        fi

        pkg_title_esc=$(printf '%s\n' "$pkg_title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        pkg_spdx_esc=$(printf '%s\n' "$pkg_spdx" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')

        printf '%s\n' "      <Dialog Id=\"Dlg_License_${pkg}\" Width=\"370\" Height=\"270\" Title=\"License Agreement - ${pkg_title_esc}\">"
        printf '%s\n' "        <Control Id=\"Title\" Type=\"Text\" X=\"15\" Y=\"6\" Width=\"340\" Height=\"15\" Transparent=\"yes\" NoPrefix=\"yes\" Text=\"License Terms for ${pkg_title_esc} (${pkg_spdx_esc}):\" />"
        printf '%s\n' "        <Control Id=\"AgreementText_${pkg}\" Type=\"ScrollableText\" X=\"20\" Y=\"25\" Width=\"330\" Height=\"180\" Sunken=\"yes\" TabSkip=\"no\">"
        printf '%s\n' "          <Text SourceFile=\"$pkg_rtf\" />"
        printf '%s\n' "        </Control>"
        printf '%s\n' "        <Control Id=\"Chk_Accept_${pkg}\" Type=\"CheckBox\" X=\"20\" Y=\"212\" Width=\"330\" Height=\"18\" Property=\"LICENSE_ACCEPTED_${pkg}\" CheckBoxValue=\"1\" Text=\"I accept the terms in the ${pkg_title_esc} (${pkg_spdx_esc}) license agreement\" />"
        printf '%s\n' "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
        printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\"><![CDATA[LICENSE_ACCEPTED_${pkg}=\"1\"]]></Publish>"
        printf '%s\n' "          <Condition Action=\"disable\"><![CDATA[LICENSE_ACCEPTED_${pkg}<>\"1\"]]></Condition>"
        printf '%s\n' "          <Condition Action=\"enable\"><![CDATA[LICENSE_ACCEPTED_${pkg}=\"1\"]]></Condition>"
        printf '%s\n' "        </Control>"
        printf '%s\n' "      </Dialog>"
        printf '%s\n' "      <Property Id=\"LICENSE_ACCEPTED_${pkg}\" Value=\"0\" Secure=\"yes\" />"
        license_dialogs="$license_dialogs Dlg_License_${pkg}"
      done
      printf '%s\n' "      <Property Id=\"AGREE_ALL_LICENSES\" Value=\"0\" Secure=\"yes\" />"

      printf '%s\n' "      <Dialog Id=\"Dlg_Features\" Width=\"370\" Height=\"270\" Title=\"Select Components\">"
      printf '%s\n' "        <Control Id=\"Lbl_Select\" Type=\"Text\" X=\"20\" Y=\"10\" Width=\"330\" Height=\"15\" Text=\"Select the components you want to install:\" />"
      y=30
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "        <Control Id=\"Chk_$pkg\" Type=\"CheckBox\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Property=\"INSTALL_$pkg\" CheckBoxValue=\"1\" Text=\"Install $pkg\" />"
        y=$((y + 20))
      done
      printf '%s\n' "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      printf '%s\n' "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      printf '%s\n' "        </Control>"
      printf '%s\n' "      </Dialog>"

      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "      <Property Id=\"INSTALL_$pkg\" Value=\"1\" Secure=\"yes\" />"
      done

      # shellcheck disable=SC2086
      set -- $deps_list
      export has_custom_ui=0
      dialogs=""
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // ""), fmt: (.value.format // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            export has_custom_ui=1
            printf '%s\n' "      <Dialog Id=\"Dlg_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Configuration for ${pkg}\">"
            y=20
            printf '%s\n' "$vars_json" | while read -r item; do
              varname=$(printf '%s\n' "$item" | jq -r '.key')
              desc=$(printf '%s\n' "$item" | jq -r '.desc')
              defval=$(printf '%s\n' "$item" | jq -r '.def')
              fmt=$(printf '%s\n' "$item" | jq -r '.fmt')

              if [ $y -gt 220 ]; then break; fi

              printf '%s\n' "        <Control Id=\"Lbl_${varname}\" Type=\"Text\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Text=\"${desc}:\" />"
              y=$((y + 15))
              if case "$varname" in *"_PASSWORD"*|*"_KEY"*|*"_SECRET"*) true;; *) false;; esac; then
                printf '%s\n' "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" Password=\"yes\" />"
              elif [ "$fmt" = "file-path" ] || [ "$fmt" = "path" ]; then
                printf '%s\n' "        <Control Id=\"Txt_${varname}\" Type=\"PathEdit\" X=\"20\" Y=\"${y}\" Width=\"250\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" />"
                printf '%s\n' "        <Control Id=\"Btn_${varname}\" Type=\"PushButton\" X=\"275\" Y=\"${y}\" Width=\"75\" Height=\"18\" Text=\"Browse...\" />"
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
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
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
      last_dlg="CostFinalize"
      if [ -n "$rtf_license_file" ]; then
        printf '%s\n' "        <Show Dialog=\"Dlg_License\" After=\"$last_dlg\">NOT Installed</Show>"
        last_dlg="Dlg_License"
      fi
      for ld in $license_dialogs; do
        printf '%s\n' "        <Show Dialog=\"$ld\" After=\"$last_dlg\">NOT Installed</Show>"
        last_dlg="$ld"
      done
      printf '%s\n' "        <Show Dialog=\"Dlg_Features\" After=\"$last_dlg\">NOT Installed</Show>"
      last_dlg="Dlg_Features"
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
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
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        printf '%s\n' "        <Show Dialog=\"Dlg_Uninst_${pkg}\" After=\"$last_uninst_dlg\">REMOVE=\"ALL\"</Show>"
        last_uninst_dlg="Dlg_Uninst_${pkg}"
      done
      printf '%s\n' "      </InstallUISequence>"
      printf '%s\n' "    </UI>"

      # Install Actions
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
        pkg=$1; ver=$2; shift 2
        run_params="/c libscript.cmd install-service $pkg $ver"
        schema_file=$(find "$LIBSCRIPT_ROOT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(printf '%s\n' "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=&quot;[PROP_%s_%s]&quot;", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        printf '%s\n' "    <CustomAction Id=\"Install$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe $run_params\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"

        # Uninstall Actions
        printf '%s\n' "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd uninstall $pkg [PURGE_$pkg] --service-name &quot;[PROP_${pkg}_$(printf '%s\n' "$pkg" | tr "[:lower:]" "[:upper:]")_SERVICE_NAME]&quot;\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
      done

      printf '%s\n' "    <InstallExecuteSequence>"
      # shellcheck disable=SC2086
      set -- $deps_list
      while [ $# -gt 1 ]; do
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

      if [ "${OS:-}" = "Windows_NT" ] || command -v candle.exe >/dev/null 2>&1 || command -v candle >/dev/null 2>&1 || command -v wix.exe >/dev/null 2>&1 || command -v wix >/dev/null 2>&1; then
        _candle_cmd="candle"
        _light_cmd="light"
        command -v candle.exe >/dev/null 2>&1 && _candle_cmd="candle.exe"
        command -v light.exe >/dev/null 2>&1 && _light_cmd="light.exe"

        if command -v wix.exe >/dev/null 2>&1 && ! command -v "$_candle_cmd" >/dev/null 2>&1; then
          wix.exe build -ext WixToolset.UI.wixext -o "${OUT_FILE}.msi" "$wxs_file"
        else
          "$_candle_cmd" -out "${OUT_FILE}.wixobj" "$wxs_file"
          "$_light_cmd" -sval -ext WixUIExtension -out "${OUT_FILE}.msi" "${OUT_FILE}.wixobj"
        fi
      elif command -v wixl >/dev/null 2>&1; then
        # wixl is a lightweight cross-compiler supporting core Product/Feature/Component tags but not full Win32 UI/WixVariable extensions.
        # Synthesize a wixl-compatible core manifest to build the valid cross-platform binary MSI:
        wixl_wxs="${OUT_FILE}_wixl.wxs"
        sed '/<Binary Id="Bin_Val_/d; /<CustomAction/d; /<Custom Action=/d; /<InstallExecuteSequence>/,/<\/InstallExecuteSequence>/d; /<WixVariable/d; /<UI Id="CustomUI">/,/<\/UI>/d' "$wxs_file" > "$wixl_wxs"
        wixl -o "${OUT_FILE}.msi" "$wixl_wxs"
        rm -f "$wixl_wxs"
      fi
      exit 0
