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
      wxs_file="${OUT_FILE}.wxs"
      exec 3>&1
      exec 1> "$wxs_file"

      cat << EOF2
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="$PRODUCT_CODE" Name="$APP_NAME" Language="1033" Version="$APP_VERSION" Manufacturer="$APP_PUBLISHER" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="$install_scope" Description="$WELCOME_TEXT" />
    <Media Id="1" Cabinet="media1.cab" EmbedCab="yes" />
EOF2
      if [ -n "$ICON_PATH" ]; then
        echo "    <Icon Id=\"AppIcon.ico\" SourceFile=\"$ICON_PATH\"/>"
        echo "    <Property Id=\"ARPPRODUCTICON\" Value=\"AppIcon.ico\" />"
      fi
      if [ -n "$APP_URL" ]; then
        echo "    <Property Id=\"ARPURLINFOABOUT\" Value=\"$APP_URL\" />"
      fi
      
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

      echo "    <Directory Id=\"TARGETDIR\" Name=\"SourceDir\">"
      echo "      <Directory Id=\"ProgramFilesFolder\">"
      echo "        <Directory Id=\"INSTALLFOLDER\" Name=\"$APP_NAME\" />"
      echo "      </Directory>"
      echo "    </Directory>"
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Function CheckPorts_$pkg()" > "validate_${pkg}.vbs"
        echo "  Session.Property(\"VALID_$pkg\") = \"1\"" >> "validate_${pkg}.vbs"
        echo "  Dim shell, exec, port" >> "validate_${pkg}.vbs"
        echo "  Set shell = CreateObject(\"WScript.Shell\")" >> "validate_${pkg}.vbs"
        
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                echo "  port = Session.Property(\"PROP_${pkg}_${varname}\")" >> "validate_${pkg}.vbs"
                echo "  If port <> \"\" Then" >> "validate_${pkg}.vbs"
                echo "    Set exec = shell.Exec(\"cmd.exe /c netstat -an | findstr /R /C:"":\" & port & \" .*LISTENING\"\"\")" >> "validate_${pkg}.vbs"
                echo "    exec.StdOut.ReadAll()" >> "validate_${pkg}.vbs"
                echo "    If exec.ExitCode = 0 Then" >> "validate_${pkg}.vbs"
                echo "      MsgBox \"Port \" & port & \" is already in use.\", 16, \"Validation Error\"" >> "validate_${pkg}.vbs"
                echo "      Session.Property(\"VALID_$pkg\") = \"0\"" >> "validate_${pkg}.vbs"
                echo "    End If" >> "validate_${pkg}.vbs"
                echo "  End If" >> "validate_${pkg}.vbs"
              fi
            done
          fi
        fi
        echo "End Function" >> "validate_${pkg}.vbs"
        echo "    <Binary Id=\"Bin_Val_$pkg\" SourceFile=\"validate_${pkg}.vbs\" />"
        echo "    <CustomAction Id=\"CA_Val_$pkg\" BinaryKey=\"Bin_Val_$pkg\" VBScriptCall=\"CheckPorts_$pkg\" Return=\"check\" />"
      done

      # Features
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    <Feature Id=\"Feature_$pkg\" Title=\"Install $pkg\" Level=\"1\">"
        echo "      <ComponentGroupRef Id=\"ProductComponents\" />"
        echo "    </Feature>"
      done

      # UI Generation
      echo "    <UI Id=\"CustomUI\">"
      echo "      <Property Id=\"DefaultUIFont\" Value=\"WixUI_Font_Normal\" />"
      
      echo "      <Dialog Id=\"Dlg_Features\" Width=\"370\" Height=\"270\" Title=\"Select Components\">"
      echo "        <Control Id=\"Lbl_Select\" Type=\"Text\" X=\"20\" Y=\"10\" Width=\"330\" Height=\"15\" Text=\"Select the components you want to install:\" />"
      y=30
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "        <Control Id=\"Chk_$pkg\" Type=\"CheckBox\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Property=\"INSTALL_$pkg\" CheckBoxValue=\"1\" Text=\"Install $pkg\" />"
        y=$((y + 20))
      done
      echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      echo "        </Control>"
      echo "      </Dialog>"
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Property Id=\"INSTALL_$pkg\" Value=\"1\" Secure=\"yes\" />"
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
            echo "      <Dialog Id=\"Dlg_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Configuration for ${pkg}\">"
            y=20
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              desc=$(echo "$item" | jq -r '.desc')
              defval=$(echo "$item" | jq -r '.def')
              
              if [ $y -gt 220 ]; then break; fi
              
              echo "        <Control Id=\"Lbl_${varname}\" Type=\"Text\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Text=\"${desc}:\" />"
              y=$((y + 15))
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                echo "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" Password=\"yes\" />"
              else
                echo "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" />"
              fi
              y=$((y + 20))
            done
            echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
            echo "          <Publish Event=\"DoAction\" Value=\"CA_Val_$pkg\">1</Publish>"
            echo "          <Publish Event=\"EndDialog\" Value=\"Return\"><![CDATA[VALID_$pkg=\"1\"]]></Publish>"
            echo "        </Control>"
            echo "      </Dialog>"
            
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              defval=$(echo "$item" | jq -r '.def')
              echo "    <Property Id=\"PROP_${pkg}_${varname}\" Value=\"${defval}\" Secure=\"yes\" />"
            done
            
            dialogs="$dialogs Dlg_${pkg}"
          fi
        fi
      done

      # MSI Uninstaller Confirmations
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Dialog Id=\"Dlg_Uninst_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Uninstall $pkg\">"
        echo "        <Control Id=\"Msg\" Type=\"Text\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"30\" Text=\"Do you want to completely remove the Data Directory and all records for $pkg?\" />"
        echo "        <Control Id=\"YesBtn\" Type=\"PushButton\" X=\"100\" Y=\"100\" Width=\"56\" Height=\"17\" Text=\"Yes\">"
        echo "          <Publish Property=\"PURGE_$pkg\" Value=\"--purge-data\">1</Publish>"
        echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
        echo "        </Control>"
        echo "        <Control Id=\"NoBtn\" Type=\"PushButton\" X=\"170\" Y=\"100\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"No\">"
        echo "          <Publish Property=\"PURGE_$pkg\" Value=\"\">1</Publish>"
        echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
        echo "        </Control>"
        echo "      </Dialog>"
        echo "      <Property Id=\"PURGE_$pkg\" Value=\"\" Secure=\"yes\" />"
        dialogs="$dialogs Dlg_Uninst_${pkg}"
      done
      
      echo "      <Dialog Id=\"Dlg_Action\" Width=\"370\" Height=\"270\" Title=\"Action\">"
      echo "        <Control Id=\"Grp\" Type=\"RadioButtonGroup\" Property=\"ACTION_CHOICE\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"200\">"
      echo "          <RadioButtonGroup Property=\"ACTION_CHOICE\">"
      echo "            <RadioButton Value=\"install\" X=\"0\" Y=\"0\" Width=\"330\" Height=\"15\" Text=\"Install locally now\" />"
      echo "            <RadioButton Value=\"docker\" X=\"0\" Y=\"20\" Width=\"330\" Height=\"15\" Text=\"Dockerfile\" />"
      echo "            <RadioButton Value=\"docker_compose\" X=\"0\" Y=\"40\" Width=\"330\" Height=\"15\" Text=\"Dockerfiles + docker-compose\" />"
      echo "            <RadioButton Value=\"msi\" X=\"0\" Y=\"60\" Width=\"330\" Height=\"15\" Text=\".msi installer\" />"
      echo "            <RadioButton Value=\"innosetup\" X=\"0\" Y=\"80\" Width=\"330\" Height=\"15\" Text=\".exe (InnoSetup)\" />"
      echo "            <RadioButton Value=\"nsis\" X=\"0\" Y=\"100\" Width=\"330\" Height=\"15\" Text=\".exe (NSIS)\" />"
      echo "            <RadioButton Value=\"deb\" X=\"0\" Y=\"120\" Width=\"330\" Height=\"15\" Text=\".deb package\" />"
      echo "            <RadioButton Value=\"rpm\" X=\"0\" Y=\"140\" Width=\"330\" Height=\"15\" Text=\".rpm package\" />"
      echo "          </RadioButtonGroup>"
      echo "        </Control>"
      echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      echo "        </Control>"
      echo "      </Dialog>"
      echo "      <Property Id=\"ACTION_CHOICE\" Value=\"install\" Secure=\"yes\" />"
      echo "      <Dialog Id=\"Dlg_Options\" Width=\"370\" Height=\"270\" Title=\"Options &amp; OS Targets\">"
      echo "        <Control Id=\"Chk_Offline\" Type=\"CheckBox\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"15\" Property=\"OPT_OFFLINE\" CheckBoxValue=\"1\" Text=\"Enable --offline mode\" />"
      echo "        <Control Id=\"Chk_Win\" Type=\"CheckBox\" X=\"20\" Y=\"40\" Width=\"330\" Height=\"15\" Property=\"OPT_WIN\" CheckBoxValue=\"1\" Text=\"Target: Windows\" />"
      echo "        <Control Id=\"Chk_DOS\" Type=\"CheckBox\" X=\"20\" Y=\"60\" Width=\"330\" Height=\"15\" Property=\"OPT_DOS\" CheckBoxValue=\"1\" Text=\"Target: DOS\" />"
      echo "        <Control Id=\"Chk_Linux\" Type=\"CheckBox\" X=\"20\" Y=\"80\" Width=\"330\" Height=\"15\" Property=\"OPT_LINUX\" CheckBoxValue=\"1\" Text=\"Target: Linux\" />"
      echo "        <Control Id=\"Chk_Mac\" Type=\"CheckBox\" X=\"20\" Y=\"100\" Width=\"330\" Height=\"15\" Property=\"OPT_MAC\" CheckBoxValue=\"1\" Text=\"Target: macOS\" />"
      echo "        <Control Id=\"Chk_BSD\" Type=\"CheckBox\" X=\"20\" Y=\"120\" Width=\"330\" Height=\"15\" Property=\"OPT_BSD\" CheckBoxValue=\"1\" Text=\"Target: BSD\" />"
      echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      echo "        </Control>"
      echo "      </Dialog>"
      echo "      <Property Id=\"OPT_OFFLINE\" Value=\"0\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_WIN\" Value=\"1\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_DOS\" Value=\"0\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_LINUX\" Value=\"1\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_MAC\" Value=\"0\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_BSD\" Value=\"0\" Secure=\"yes\" />"
      echo "      <InstallUISequence>"
      echo "        <Show Dialog=\"Dlg_Features\" After=\"CostFinalize\">NOT Installed</Show>"
      last_dlg="Dlg_Features"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        has_dlg=0
        for d in $dialogs; do
          if [ "$d" = "Dlg_${pkg}" ]; then has_dlg=1; break; fi
        done
        if [ "$has_dlg" = "1" ]; then
          echo "        <Show Dialog=\"Dlg_${pkg}\" After=\"$last_dlg\"><![CDATA[NOT Installed AND INSTALL_$pkg=\"1\"]]></Show>"
          last_dlg="Dlg_${pkg}"
        fi
      done
      
      echo "        <Show Dialog=\"Dlg_Action\" After=\"$last_dlg\">NOT Installed</Show>"
      echo "        <Show Dialog=\"Dlg_Options\" After=\"Dlg_Action\">NOT Installed</Show>"
      # UI sequence for uninstall
      last_uninst_dlg="CostFinalize"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "        <Show Dialog=\"Dlg_Uninst_${pkg}\" After=\"$last_uninst_dlg\">REMOVE=\"ALL\"</Show>"
        last_uninst_dlg="Dlg_Uninst_${pkg}"
      done
      echo "      </InstallUISequence>"
      echo "    </UI>"

      # Install Actions
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"[INSTALLFOLDER]libscript.cmd\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"[PROP_%s_%s]\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "    <CustomAction Id=\"Install$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe $run_params\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
        
        # Uninstall Actions
        if [ "$OFFLINE" = "1" ]; then
          echo "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c \"\"\"[INSTALLFOLDER]libscript.cmd\"\"\" uninstall $pkg [PURGE_$pkg] --service-name [PROP_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME]\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
        else
          echo "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd uninstall $pkg [PURGE_$pkg] --service-name [PROP_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME]\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
        fi
      done

      echo "Function GenerateStack()" > "generate_stack.vbs"
      echo "  Dim shell, cmd, args, action" >> "generate_stack.vbs"
      echo "  Set shell = CreateObject(""WScript.Shell"")" >> "generate_stack.vbs"
      echo "  action = Session.Property(""ACTION_CHOICE"")" >> "generate_stack.vbs"
      echo "  If action = ""install"" Then Exit Function" >> "generate_stack.vbs"
      echo "  args = "" """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_OFFLINE"") = ""1"" Then args = args & ""--offline """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_WIN"") = ""1"" Then args = args & ""--os-windows """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_DOS"") = ""1"" Then args = args & ""--os-dos """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_LINUX"") = ""1"" Then args = args & ""--os-linux """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_MAC"") = ""1"" Then args = args & ""--os-macos """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_BSD"") = ""1"" Then args = args & ""--os-bsd """ >> "generate_stack.vbs"
      if [ "$OFFLINE" = "1" ]; then
        echo "  cmd = ""cmd.exe /c """""" & Session.Property(""INSTALLFOLDER"") & ""libscript.cmd"""""" package_as "" & action" >> "generate_stack.vbs"
      else
        echo "  cmd = ""cmd.exe /c libscript.cmd package_as "" & action" >> "generate_stack.vbs"
      fi
      echo "  cmd = cmd & "" """ >> "generate_stack.vbs"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  If Session.Property(""INSTALL_$pkg"") = ""1"" Then cmd = cmd & ""$pkg $ver """ >> "generate_stack.vbs"
      done
      echo "  cmd = cmd & args" >> "generate_stack.vbs"
      echo "  shell.Run cmd, 0, True" >> "generate_stack.vbs"
      echo "End Function" >> "generate_stack.vbs"
      echo "    <Binary Id=\"Bin_GenStack\" SourceFile=\"generate_stack.vbs\" />"
      echo "    <CustomAction Id=\"CA_GenStack\" BinaryKey=\"Bin_GenStack\" VBScriptCall=\"GenerateStack\" Return=\"ignore\" Impersonate=\"no\" Execute=\"deferred\" />"
      echo "    <InstallExecuteSequence>"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Custom Action=\"Install$pkg\" Before=\"InstallFinalize\"><![CDATA[NOT Installed AND ACTION_CHOICE=\"install\" AND INSTALL_$pkg=\"1\"]]></Custom>"
        echo "      <Custom Action=\"Uninstall$pkg\" Before=\"RemoveFiles\">REMOVE=\"ALL\"</Custom>"
      done
      echo "      <Custom Action=\"CA_GenStack\" Before=\"InstallFinalize\"><![CDATA[NOT Installed AND ACTION_CHOICE<>\"install\"]]></Custom>"
      echo "    </InstallExecuteSequence>"
      
      echo "  </Product>"
      echo "  <Fragment>"
      echo "    <ComponentGroup Id=\"ProductComponents\" Directory=\"INSTALLFOLDER\">"
      echo "    </ComponentGroup>"
      echo "  </Fragment>"
      echo "</Wix>"

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
