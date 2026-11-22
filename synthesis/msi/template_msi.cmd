@echo off
:: # template_msi.cmd
:: ## Overview
:: Universal WiX XML (.wxs) manifest generator on Windows. Synthesizes WiX manifests driven purely by packaging.json using jq and uuid_gen.cmd without PowerShell.
:: ## Usage
:: call synthesis\msi\template_msi.cmd <path_to_stack_or_packaging.json> --out <file.wxs> [OPTIONS]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "TARGET_SPEC=%~1"
if "%TARGET_SPEC%"=="" (
    echo [ERROR] Target stack directory or packaging.json required >&2
    exit /b 1
)
shift

set "OUT_FILE="
set "VARIANT=online"
set "VERSION_OVERRIDE="
if not defined TARGET_ARCH set "TARGET_ARCH=x64"
set "MSI_DIR=!LIBSCRIPT_ROOT_DIR!\dist\msi"
goto :arg_loop

:: ## arg_loop
:: Parses command-line arguments and populates configuration variables.
:arg_loop
if "%~1"=="" goto :done_args
if /i "%~1"=="--out" ( set "OUT_FILE=%~2" & shift & shift & goto :arg_loop )
if /i "%~1"=="--variant" ( set "VARIANT=%~2" & shift & shift & goto :arg_loop )
if /i "%~1"=="--version" ( set "VERSION_OVERRIDE=%~2" & shift & shift & goto :arg_loop )
if /i "%~1"=="--arch" ( set "TARGET_ARCH=%~2" & shift & shift & goto :arg_loop )
if /i "%~1"=="--msi-dir" ( set "MSI_DIR=%~2" & shift & shift & goto :arg_loop )
shift
goto :arg_loop

:: ## done_args
:: Validates inputs, extracts packaging.json metadata via jq, and emits WiX XML.
:done_args
if "%OUT_FILE%"=="" (
    echo [ERROR] --out parameter is required >&2
    exit /b 1
)

set "PKG_JSON=%TARGET_SPEC%"
if exist "%TARGET_SPEC%\packaging.json" set "PKG_JSON=%TARGET_SPEC%\packaging.json"
if not exist "!PKG_JSON!" (
    echo [ERROR] packaging.json not found at: !PKG_JSON! >&2
    exit /b 1
)

call :resolve_jq
if "!JQ_BIN!"=="" (
    echo [ERROR] jq is required to parse !PKG_JSON! ^(run: libscript.cmd depends jq^) >&2
    exit /b 1
)

set "TMP_JQ=%TEMP%\ls_tpl_msi_%RANDOM%.jq"
(
    echo ^(.name // "app"^) as $name ^|
    echo ^(.title // $name^) as $title ^|
    echo ^(if $ver_ovr ^^!= "" then $ver_ovr else ^(.version // "1.0.0"^) end^) as $version ^|
    echo ^(.publisher // "LibScript Open Source Project"^) as $publisher ^|
    echo ^(.upgrade_code // "A0B1C2D3-E4F5-6A7B-8C9D-0E1F2A3B4C5D"^) as $upgrade_code ^|
    echo ^(.topology // "standalone"^) as $topology ^|
    echo ^(.database_contract // null^) as $dbc ^|
    echo ^(if $dbc ^^!= null then "true" else "false" end^) as $has_db ^|
    echo ^(if $dbc ^^!= null then ^($dbc.engine // "mysql"^) else "" end^) as $db_engine ^|
    echo ^(if $dbc ^^!= null then ^(^($dbc.default_port // 3306^) ^| tostring^) else "3306" end^) as $db_port ^|
    echo ^(if $dbc ^^!= null then ^($dbc.default_schema_name // $name^) else $name end^) as $db_schema ^|
    echo ^(if $dbc ^^!= null then ^($dbc.default_user_name // $name^) else $name end^) as $db_user ^|
    echo ^(^(.chained_packages // []^) ^| length^) as $chained_len ^|
    echo ^(if ^($chained_len ^> 0 or $topology == "suite_orchestrator"^) then "true" else "false" end^) as $has_chainer ^|
    echo ^([ $version ^| split^("."^)[] ^| tonumber? // 0 ] + [0,0,0,0] ^| .[0:4] ^| map^(tostring^) ^| join^("."^)^) as $wix_ver ^|
    echo "APP_NAME=\($name)",
    echo "APP_TITLE=\($title)",
    echo "APP_VERSION=\($version)",
    echo "WIX_VER=\($wix_ver)",
    echo "APP_PUBLISHER=\($publisher)",
    echo "UPGRADE_CODE=\($upgrade_code)",
    echo "TOPOLOGY=\($topology)",
    echo "HAS_DB=\($has_db)",
    echo "DB_ENGINE=\($db_engine)",
    echo "DB_PORT=\($db_port)",
    echo "DB_SCHEMA=\($db_schema)",
    echo "DB_USER=\($db_user)",
    echo "HAS_CHAINER=\($has_chainer)"
) > "!TMP_JQ!"

set "APP_NAME=app"
set "APP_TITLE=app"
set "APP_VERSION=1.0.0"
set "WIX_VER=1.0.0.0"
set "APP_PUBLISHER=LibScript Open Source Project"
set "UPGRADE_CODE=A0B1C2D3-E4F5-6A7B-8C9D-0E1F2A3B4C5D"
set "TOPOLOGY=standalone"
set "HAS_DB=false"
set "DB_ENGINE=mysql"
set "DB_PORT=3306"
set "DB_SCHEMA=app"
set "DB_USER=app"
set "HAS_CHAINER=false"

set "TMP_OUT=%TEMP%\ls_tpl_msi_%RANDOM%_%RANDOM%.out"
"!JQ_BIN!" -r --arg ver_ovr "!VERSION_OVERRIDE!" -f "!TMP_JQ!" "!PKG_JSON!" > "!TMP_OUT!"
if errorlevel 1 (
    del /f /q "!TMP_JQ!" "!TMP_OUT!" >nul 2>&1
    echo [ERROR] Failed to parse !PKG_JSON! with jq >&2
    exit /b 1
)
for /f "usebackq tokens=1,* delims==" %%K in ("!TMP_OUT!") do (
    set "%%K=%%L"
)
del /f /q "!TMP_JQ!" "!TMP_OUT!" >nul 2>&1

set "PRODUCT_CODE="
for /f "usebackq delims=" %%U in (`call "!LIBSCRIPT_ROOT_DIR!\engine\common\uuid_gen.cmd" "6ba7b810-9dad-11d1-80b4-00c04fd430c8" "!APP_NAME!.!VARIANT!.!APP_VERSION!"`) do set "PRODUCT_CODE=%%U"
if "!PRODUCT_CODE!"=="" set "PRODUCT_CODE=*"

for %%D in ("!OUT_FILE!") do if not exist "%%~dpD" mkdir "%%~dpD" 2>nul

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
    echo   ^<Product Id="!PRODUCT_CODE!"
    echo            Name="!APP_TITLE!"
    echo            Language="1033"
    echo            Version="!WIX_VER!"
    echo            Manufacturer="!APP_PUBLISHER!"
    echo            UpgradeCode="!UPGRADE_CODE!"^>
    echo.
    echo     ^<Package Id="*" Platform="!TARGET_ARCH!"
    echo              InstallerVersion="500"
    echo              SummaryCodepage="1252"
    echo              Compressed="yes"
    echo              InstallScope="perMachine"
    echo              Description="!APP_TITLE! Installer" /^>
    echo.
    echo     ^<MajorUpgrade DowngradeErrorMessage="A newer version of !APP_TITLE! is already installed." Schedule="afterInstallInitialize" /^>
    echo     ^<Media Id="1" Cabinet="payload.cab" EmbedCab="yes" /^>
    echo.
    echo     ^<Property Id="PROP_VARIANT" Value="!VARIANT!" Secure="yes" /^>
    echo     ^<Property Id="PROP_APP_IDENTIFIER" Value="!APP_NAME!" Secure="yes" /^>
    echo     ^<Property Id="PROP_TOPOLOGY" Value="!TOPOLOGY!" Secure="yes" /^>
) > "!OUT_FILE!"

if /i "!HAS_DB!"=="true" (
    (
        echo     ^<^^!-- Universal Database Contract Properties --^>
        echo     ^<Property Id="PROP_DB_TYPE" Value="!DB_ENGINE!" Secure="yes" /^>
        echo     ^<Property Id="USER_DB_HOST" Value="127.0.0.1" Secure="yes" /^>
        echo     ^<Property Id="USER_DB_PORT" Value="!DB_PORT!" Secure="yes" /^>
        echo     ^<Property Id="USER_DB_NAME" Value="!DB_SCHEMA!" Secure="yes" /^>
        echo     ^<Property Id="PROP_PROVISION_USER" Value="!DB_USER!" Secure="yes" /^>
        echo     ^<Property Id="PROP_PROVISION_PASSWORD" Value="!APP_NAME!123" Secure="yes" /^>
        echo     ^<Property Id="PROP_MYSQL_ROOT_PASSWORD" Secure="yes" Hidden="yes" /^>
        echo     ^<Property Id="PROP_MONGODB_ROOT_PASSWORD" Secure="yes" Hidden="yes" /^>
        echo     ^<Property Id="PROP_PROVISION_CHARSET" Value="utf8mb4" Secure="yes" /^>
        echo     ^<Property Id="PROP_PROVISION_COLLATION" Value="utf8mb4_unicode_ci" Secure="yes" /^>
        echo     ^<Property Id="PURGE_DATA" Value="0" Secure="yes" /^>
        echo     ^<Property Id="USER_DB_STRATEGY" Value="local" Secure="yes" /^>
        echo     ^<Property Id="INSTALL_MYSQL" Value="1" Secure="yes" /^>
        echo.
        echo     ^<UI Id="DatabaseConfigUI"^>
        echo       ^<Dialog Id="Dlg_DatabaseConfig" Width="370" Height="270" Title="Database Configuration"^>
        echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Database Configuration" /^>
        echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select your database deployment strategy." /^>
        echo         ^<Control Id="RadioGroup" Type="RadioButtonGroup" X="20" Y="60" Width="330" Height="50" Property="USER_DB_STRATEGY"^>
        echo           ^<RadioButtonGroup Property="USER_DB_STRATEGY"^>
        echo             ^<RadioButton Value="local" X="0" Y="0" Width="320" Height="20" Text="Install Local Database Component" /^>
        echo             ^<RadioButton Value="remote" X="0" Y="25" Width="320" Height="20" Text="Connect to Existing/Remote Database" /^>
        echo           ^</RadioButtonGroup^>
        echo         ^</Control^>
        echo         ^<Control Id="Lbl_DbHost" Type="Text" X="20" Y="120" Width="100" Height="15" Text="Database Host:" /^>
        echo         ^<Control Id="Txt_DbHost" Type="Edit" X="120" Y="118" Width="200" Height="18" Property="USER_DB_HOST" /^>
        echo         ^<Control Id="Lbl_DbName" Type="Text" X="20" Y="145" Width="100" Height="15" Text="Database Name:" /^>
        echo         ^<Control Id="Txt_DbName" Type="Edit" X="120" Y="143" Width="200" Height="18" Property="USER_DB_NAME" /^>
        echo       ^</Dialog^>
        echo     ^</UI^>
        echo.
        echo     ^<CustomAction Id="SetInstallMySQL" Property="INSTALL_MYSQL" Value="0" /^>
        echo     ^<CustomAction Id="ProvisionLogicalDB" Execute="deferred" Impersonate="no" Return="check" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]bundle\engine\hooks\databases\provision_logical_db.cmd&quot; --host &quot;[USER_DB_HOST]&quot; --port &quot;[USER_DB_PORT]&quot; --db-name &quot;[USER_DB_NAME]&quot;" Directory="INSTALLFOLDER" /^>
        echo     ^<CustomAction Id="RollbackLogicalDB" Execute="rollback" Impersonate="no" Return="ignore" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]bundle\engine\hooks\databases\provision_logical_db.cmd&quot; --rollback" Directory="INSTALLFOLDER" /^>
        echo.
        echo     ^<InstallExecuteSequence^>
        echo       ^<Custom Action="SetInstallMySQL" Before="ProvisionLogicalDB"^>USER_DB_STRATEGY="remote"^</Custom^>
        echo       ^<Custom Action="ProvisionLogicalDB" Before="InstallFinalize"^>1^</Custom^>
        echo       ^<Custom Action="RollbackLogicalDB" Before="ProvisionLogicalDB"^>1^</Custom^>
        echo     ^</InstallExecuteSequence^>
    ) >> "!OUT_FILE!"
)

(
    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFiles64Folder"^>
    echo         ^<Directory Id="INSTALLFOLDER" Name="!APP_NAME!"^>
    echo           ^<Directory Id="BUNDLE_DIR" Name="bundle" /^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo     ^</Directory^>
    echo.
    echo     ^<Feature Id="DefaultFeature" Title="!APP_TITLE! Core" Level="1"^>
    echo       ^<ComponentRef Id="AppIdentityComponent" /^>
    echo       ^<ComponentGroupRef Id="HarvestedPayloadGroup" /^>
    echo     ^</Feature^>
    echo.
    echo     ^<DirectoryRef Id="INSTALLFOLDER"^>
    echo       ^<Component Id="AppIdentityComponent" Guid="*"^>
    echo         ^<RegistryKey Root="HKLM" Key="Software\LibScript\!APP_NAME!"^>
    echo           ^<RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" /^>
    echo           ^<RegistryValue Name="Version" Type="string" Value="!APP_VERSION!" /^>
    echo           ^<RegistryValue Name="Variant" Type="string" Value="!VARIANT!" /^>
    echo           ^<RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" /^>
    echo         ^</RegistryKey^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
) >> "!OUT_FILE!"

if /i "!HAS_CHAINER!"=="true" (
    (
        echo     ^<UI^>
        echo       ^<EmbeddedChainer Id="LibScriptChainer" SourceFile="binary\libscript_chainer.dll" /^>
        echo     ^</UI^>
    ) >> "!OUT_FILE!"
)

(
    echo   ^</Product^>
    echo ^</Wix^>
) >> "!OUT_FILE!"

echo [SUCCESS] Generated universal WiX XML manifest: !OUT_FILE!
exit /b 0

:: ## resolve_jq
:: Locates or bootstraps jq.exe via LibScript component isolation.
:resolve_jq
set "JQ_BIN="
for %%J in (jq.exe jq) do (
    if "!JQ_BIN!"=="" (
        for /f "delims=" %%P in ('where %%J 2^>nul') do if "!JQ_BIN!"=="" set "JQ_BIN=%%P"
    )
)
if not "!JQ_BIN!"=="" exit /b 0
set "_LS_H=%LIBSCRIPT_HOME%"
if "!_LS_H!"=="" set "_LS_H=%USERPROFILE%\.libscript"
if exist "!_LS_H!\jq\default\bin\jq.exe" (
    set "JQ_BIN=!_LS_H!\jq\default\bin\jq.exe"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq >nul 2>&1
    if exist "!_LS_H!\jq\default\bin\jq.exe" set "JQ_BIN=!_LS_H!\jq\default\bin\jq.exe"
)
exit /b 0
