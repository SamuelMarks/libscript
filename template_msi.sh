#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


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
        deps_list=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end)" else empty end' "libscript.json" 2>/dev/null | tr '\n' ' ')
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
        run_params="/c libscript.cmd install_service $pkg $ver"
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
        echo "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd uninstall $pkg [PURGE_$pkg] --service-name [PROP_${pkg}_$(echo "$pkg" | tr "a-z" "A-Z")_SERVICE_NAME]\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
      done

      echo "    <InstallExecuteSequence>"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Custom Action=\"Install$pkg\" Before=\"InstallFinalize\"><![CDATA[NOT Installed AND INSTALL_$pkg=\"1\"]]></Custom>"
        echo "      <Custom Action=\"Uninstall$pkg\" Before=\"RemoveFiles\">REMOVE=\"ALL\"</Custom>"
      done
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
