@echo off
:: # build_msi.cmd
::
:: ## Overview
:: Generic library engine for generating WiX Windows Installer (.msi) packages on Windows.
:: Synthesizes WiX manifests from packaging.json and vars.schema.json, supporting
:: Simple and Advanced setup modes, DBaaS offloading, custom directories,
:: runtime auto-detection, and repository fork selection.
::
:: ## Usage
:: call packaging\build_msi.cmd [TARGET_DIR] [OPTIONS]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:: ## find_root_loop
:: Iterates upward through the directory tree looking for libscript.cmd.
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:: ## found_root
:: Target label reached once the libscript root directory is located.
:found_root

where sh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sh "%SCRIPT_DIR%\build_msi.sh" %*
    exit /b %ERRORLEVEL%
)

set "TARGET_DIR="
set "OUT_FILE="
set "APP_NAME=Open edX Platform"
set "APP_VERSION=1.0.0.0"
set "APP_PUBLISHER=LibScript Open Source Project"
set "PRODUCT_CODE=*"
set "UPGRADE_CODE=B8C8E64E-9B5A-4B7C-A5D8-0F18B9918239"
set "install_scope=perMachine"
set "APP_URL=https://openedx.org"
set "INSTALL_DIR=[ProgramFiles64Folder]OpenEdX"
set "DATA_DIR=C:\ProgramData\OpenEdX\data"
set "LOGS_DIR=C:\ProgramData\OpenEdX\logs"
set "REPO_URL=https://github.com/openedx/edx-platform.git"
set "REPO_BRANCH=open-release/quince.master"
set "REPO_AUTH_TOKEN="
set "ICON_PATH="
set "BANNER_TOP_PATH="
set "BANNER_SIDE_PATH="
set "LICENSE_PATH="
set "SETUP_MODE=Simple"
set "VARIANT=online"
if "%LIBSCRIPT_OFFLINE%"=="1" set "VARIANT=offline"
set "CACHE_DIR=%LIBSCRIPT_CACHE_DIR%"
if "%CACHE_DIR%"=="" set "CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache"

:: ## parse_args
:: Parses command-line arguments and flags.
:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="--help" goto show_help
if /I "%~1"=="-h" goto show_help
if /I "%~1"=="/?" goto show_help
if /I "%~1"=="--variant" (
    set "VARIANT=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--offline" (
    set "VARIANT=offline"
    shift
    goto parse_args
)
if /I "%~1"=="--online" (
    set "VARIANT=online"
    shift
    goto parse_args
)
if /I "%~1"=="--cache-dir" (
    set "CACHE_DIR=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--out" (
    set "OUT_FILE=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--version" (
    set "APP_VERSION=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--upgrade-code" (
    set "UPGRADE_CODE=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--icon" (
    set "ICON_PATH=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--banner-top" (
    set "BANNER_TOP_PATH=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--banner-side" (
    set "BANNER_SIDE_PATH=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--license" (
    set "LICENSE_PATH=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--install-dir" (
    set "INSTALL_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--data-dir" (
    set "DATA_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--log-dir" (
    set "LOGS_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--repo" (
    set "REPO_URL=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--branch" (
    set "REPO_BRANCH=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--auth-token" (
    set "REPO_AUTH_TOKEN=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--mode" (
    set "SETUP_MODE=%~2"
    shift
    shift
    goto parse_args
)
if "%TARGET_DIR%"=="" (
    set "TARGET_DIR=%~1"
    shift
    goto parse_args
)
shift
goto parse_args

:: ## show_help
:: Displays command-line usage and options.
:show_help
echo Usage: %~nx0 [TARGET_DIR] [OPTIONS]
echo Generates a generic WiX Windows Installer (.msi) package.
echo.
echo Options:
echo   --out ^<name^>          Output base file name
echo   --version ^<ver^>       Package version
echo   --upgrade-code ^<guid^> Upgrade code GUID
echo   --icon ^<path^>         Path to .ico icon file
echo   --banner-top ^<path^>   Path to 493x58 top banner BMP
echo   --banner-side ^<path^>  Path to 164x312 side splash BMP
echo   --license ^<path^>      Path to EULA (RTF or TXT)
echo   --install-dir ^<dir^>   Default application installation folder
echo   --data-dir ^<dir^>      Default mutable datastore folder
echo   --log-dir ^<dir^>       Default logs folder
echo   --repo ^<url^>          Source Git repository URL
echo   --branch ^<branch^>     Target Git release branch or tag
echo   --auth-token ^<token^>  Private repository authentication token
echo   --mode ^<mode^>         Default setup mode (Simple or Advanced)
echo   --help, -h            Show this help text
exit /b 0

:: ## after_args
:: Resolves paths and fallback assets after argument processing.
:after_args

if "%TARGET_DIR%"=="" set "TARGET_DIR=stacks\cms\openedx"
set "CC0_ASSETS=%LIBSCRIPT_ROOT_DIR%\..\cc0-assets\libscript\openedx\assets"
if not exist "%CC0_ASSETS%" if exist "%LIBSCRIPT_ROOT_DIR%\cc0-assets\libscript\openedx\assets" set "CC0_ASSETS=%LIBSCRIPT_ROOT_DIR%\cc0-assets\libscript\openedx\assets"
if "%ICON_PATH%"=="" (
    if exist "%CC0_ASSETS%\openedx.ico" (
        set "ICON_PATH=%CC0_ASSETS%\openedx.ico"
    ) else if exist "%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx.ico" (
        set "ICON_PATH=%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx.ico"
    )
)
if "%BANNER_TOP_PATH%"=="" (
    if exist "%CC0_ASSETS%\openedx_banner_top.bmp" (
        set "BANNER_TOP_PATH=%CC0_ASSETS%\openedx_banner_top.bmp"
    ) else if exist "%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx_banner_top.bmp" (
        set "BANNER_TOP_PATH=%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx_banner_top.bmp"
    )
)
if "%BANNER_SIDE_PATH%"=="" (
    if exist "%CC0_ASSETS%\openedx_banner_side.bmp" (
        set "BANNER_SIDE_PATH=%CC0_ASSETS%\openedx_banner_side.bmp"
    ) else if exist "%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx_banner_side.bmp" (
        set "BANNER_SIDE_PATH=%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx_banner_side.bmp"
    )
)
if "%LICENSE_PATH%"=="" (
    if exist "%CC0_ASSETS%\openedx_eula.rtf" (
        set "LICENSE_PATH=%CC0_ASSETS%\openedx_eula.rtf"
    ) else if exist "%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx_eula.rtf" (
        set "LICENSE_PATH=%LIBSCRIPT_ROOT_DIR%\packaging\assets\openedx_eula.rtf"
    )
)

:: Generate dynamically on the fly if needed
set "TMP_BRANDING_DIR=%TEMP%\openedx_branding_%RANDOM%"
if "%ICON_PATH%"=="" (
    if not exist "%TMP_BRANDING_DIR%" mkdir "%TMP_BRANDING_DIR%" 2>nul
    call "%LIBSCRIPT_ROOT_DIR%\packaging\generate_openedx_branding.cmd" --output-dir "%TMP_BRANDING_DIR%" >nul 2>nul
    if exist "%TMP_BRANDING_DIR%\openedx.ico" set "ICON_PATH=%TMP_BRANDING_DIR%\openedx.ico"
    if exist "%TMP_BRANDING_DIR%\openedx_banner_top.bmp" if "%BANNER_TOP_PATH%"=="" set "BANNER_TOP_PATH=%TMP_BRANDING_DIR%\openedx_banner_top.bmp"
    if exist "%TMP_BRANDING_DIR%\openedx_banner_side.bmp" if "%BANNER_SIDE_PATH%"=="" set "BANNER_SIDE_PATH=%TMP_BRANDING_DIR%\openedx_banner_side.bmp"
    if exist "%TMP_BRANDING_DIR%\openedx_eula.rtf" if "%LICENSE_PATH%"=="" set "LICENSE_PATH=%TMP_BRANDING_DIR%\openedx_eula.rtf"
)
if not exist "%ICON_PATH%" (
    if exist "%TMP_BRANDING_DIR%\openedx.ico" (
        set "ICON_PATH=%TMP_BRANDING_DIR%\openedx.ico"
    ) else (
        set "ICON_PATH="
    )
)
if not exist "%BANNER_TOP_PATH%" set "BANNER_TOP_PATH="
if not exist "%BANNER_SIDE_PATH%" set "BANNER_SIDE_PATH="
if not exist "%LICENSE_PATH%" set "LICENSE_PATH="

if /I "%VARIANT%"=="offline" (
    set "PROP_OPENEDX_OFFLINE=1"
    if "%APP_NAME%"=="Open edX Platform" set "APP_NAME=Open edX Platform (Offline Air-Gapped)"
    if "%OUT_FILE%"=="" set "OUT_FILE=openedx-offline-%APP_VERSION%"
    set "WELCOME_DESC=The Setup Wizard will deploy Open edX LMS, Studio CMS, and pre-bundled air-gapped runtimes on your computer."
    set "COMP_TAG= [Pre-bundled / Offline]"
) else (
    set "PROP_OPENEDX_OFFLINE=0"
    if "%APP_NAME%"=="Open edX Platform" set "APP_NAME=Open edX Platform (Online)"
    if "%OUT_FILE%"=="" set "OUT_FILE=openedx-%APP_VERSION%"
    set "WELCOME_DESC=The Setup Wizard will download and install Open edX LMS, Studio CMS, and required runtimes on your computer."
    set "COMP_TAG="
)

set "WXS_FILE=%OUT_FILE%.wxs"

:: ## write_wxs
:: Emits the complete WiX XML manifest.
setlocal DisableDelayedExpansion
(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
    echo   ^<Product Id="%PRODUCT_CODE%" Name="%APP_NAME%" Language="1033" Version="%APP_VERSION%" Manufacturer="%APP_PUBLISHER%" UpgradeCode="%UPGRADE_CODE%"^>
    echo     ^<Package InstallerVersion="200" Compressed="yes" InstallScope="%install_scope%" Description="%APP_NAME% Windows Installer" /^>
    if /I "%VARIANT%"=="offline" (
        echo     ^<Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="high" /^>
        echo     ^<Media Id="2" Cabinet="runtimes.cab" EmbedCab="yes" CompressionLevel="medium" /^>
        echo     ^<Media Id="3" Cabinet="databases.cab" EmbedCab="yes" CompressionLevel="medium" /^>
        echo     ^<Media Id="4" Cabinet="codebase.cab" EmbedCab="yes" CompressionLevel="medium" /^>
    ) else (
        echo     ^<Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="high" /^>
    )
    echo     ^<MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed. Setup will now exit." Schedule="afterInstallInitialize" AllowSameVersionUpgrades="no" IgnoreRemoveFailure="no" /^>
    if not "%ICON_PATH%"=="" (
        echo     ^<Icon Id="AppIcon.ico" SourceFile="%ICON_PATH%" /^>
        echo     ^<Property Id="ARPPRODUCTICON" Value="AppIcon.ico" /^>
    )
    echo     ^<Property Id="ARPURLINFOABOUT" Value="%APP_URL%" /^>
    echo     ^<Property Id="PROP_OPENEDX_OFFLINE" Value="%PROP_OPENEDX_OFFLINE%" Secure="yes" /^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo     ^<Binary Id="WixUIBannerBmp" SourceFile="%BANNER_TOP_PATH%" /^>
        echo     ^<WixVariable Id="WixUIBannerBmp" Value="%BANNER_TOP_PATH%" /^>
    )
    if not "%BANNER_SIDE_PATH%"=="" (
        echo     ^<Binary Id="WixUIDialogBmp" SourceFile="%BANNER_SIDE_PATH%" /^>
        echo     ^<WixVariable Id="WixUIDialogBmp" Value="%BANNER_SIDE_PATH%" /^>
    )
    if not "%LICENSE_PATH%"=="" echo     ^<WixVariable Id="WixUILicenseRtf" Value="%LICENSE_PATH%" /^>

    echo     ^<Property Id="SETUP_MODE" Value="%SETUP_MODE%" Secure="yes" /^>
    echo     ^<Property Id="LICENSE_ACCEPTED" Value="1" Secure="yes" /^>
    echo     ^<Property Id="LAUNCH_BROWSER" Value="1" Secure="yes" /^>
    echo     ^<Property Id="LAUNCH_STUDIO" Value="1" Secure="yes" /^>

    echo     ^<Property Id="WIXUI_INSTALLDIR" Value="INSTALLFOLDER" /^>
    echo     ^<Property Id="DATAFOLDER" Value="%DATA_DIR%" Secure="yes" /^>
    echo     ^<Property Id="LOGSFOLDER" Value="%LOGS_DIR%" Secure="yes" /^>

    echo     ^<Property Id="FOUND_PYTHON_EXE"^>
    echo       ^<RegistrySearch Id="SearchPython64" Root="HKLM" Key="SOFTWARE\Python\PythonCore\3.12\InstallPath" Type="raw" Win64="yes"^>
    echo         ^<FileSearch Id="SearchPythonExe64" Name="python.exe" /^>
    echo       ^</RegistrySearch^>
    echo       ^<RegistrySearch Id="SearchPython311" Root="HKLM" Key="SOFTWARE\Python\PythonCore\3.11\InstallPath" Type="raw" Win64="yes"^>
    echo         ^<FileSearch Id="SearchPythonExe311" Name="python.exe" /^>
    echo       ^</RegistrySearch^>
    echo     ^</Property^>

    echo     ^<Property Id="FOUND_NODE_EXE"^>
    echo       ^<RegistrySearch Id="SearchNodeReg" Root="HKLM" Key="SOFTWARE\Node.js" Name="InstallPath" Type="raw"^>
    echo         ^<FileSearch Id="SearchNodeExe" Name="node.exe" /^>
    echo       ^</RegistrySearch^>
    echo     ^</Property^>

    echo     ^<Property Id="FOUND_MYSQL_EXE"^>
    echo       ^<RegistrySearch Id="SearchMySQL8" Root="HKLM" Key="SOFTWARE\MySQL AB\MySQL Server 8.0" Name="Location" Type="raw"^>
    echo         ^<FileSearch Id="SearchMySQLDaemon" Name="mysqld.exe" /^>
    echo       ^</RegistrySearch^>
    echo     ^</Property^>

    echo     ^<Property Id="USE_EXISTING_PYTHON" Value="1" Secure="yes" /^>
    echo     ^<Property Id="USE_EXISTING_NODE" Value="1" Secure="yes" /^>
    echo     ^<Property Id="USE_EXISTING_MYSQL" Value="0" Secure="yes" /^>

    echo     ^<Property Id="PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Value="%REPO_URL%" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_VERSION" Value="%REPO_BRANCH%" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_REPO_TYPE" Value="Upstream" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_BRANCH_TYPE" Value="NamedRelease" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_REPO_AUTH_TOKEN" Hidden="yes" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_GIT_DEPTH" Value="1" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_BRANCH_PRESET" Value="Quince" Secure="yes" /^>

    echo     ^<Property Id="PROP_LMS_HOST" Value="localhost" Secure="yes" /^>
    echo     ^<Property Id="PROP_LMS_PORT" Value="8000" Secure="yes" /^>
    echo     ^<Property Id="PROP_CMS_HOST" Value="localhost" Secure="yes" /^>
    echo     ^<Property Id="PROP_CMS_PORT" Value="8001" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_ADMIN_EMAIL" Value="admin@openedx.local" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_ADMIN_USERNAME" Value="admin" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_ADMIN_PASSWORD" Value="admin" Hidden="yes" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_SECRET_KEY" Value="insecure-secret-key-replace-in-production" Hidden="yes" Secure="yes" /^>

    echo     ^<Property Id="PROP_MYSQL_PORT" Value="3306" Secure="yes" /^>
    echo     ^<Property Id="PROP_MYSQL_REMOTE_URL" Hidden="yes" Secure="yes" /^>
    echo     ^<Property Id="PROP_MYSQL_ROOT_PASSWORD" Hidden="yes" Secure="yes" /^>

    echo     ^<Property Id="PROP_REDIS_PORT" Value="6379" Secure="yes" /^>
    echo     ^<Property Id="PROP_REDIS_HOST" Value="127.0.0.1" Secure="yes" /^>
    echo     ^<Property Id="PROP_REDIS_URL" Hidden="yes" Secure="yes" /^>
    echo     ^<Property Id="PROP_REDIS_PASSWORD" Hidden="yes" Secure="yes" /^>

    echo     ^<Property Id="PROP_MONGODB_PORT" Value="27017" Secure="yes" /^>
    echo     ^<Property Id="PROP_MONGODB_URI" Hidden="yes" Secure="yes" /^>

    echo     ^<Property Id="PROP_MEILISEARCH_PORT" Value="7700" Secure="yes" /^>
    echo     ^<Property Id="PROP_MEILISEARCH_CUSTOM_URL" Secure="yes" /^>
    echo     ^<Property Id="PROP_MEILISEARCH_MASTER_KEY" Hidden="yes" Secure="yes" /^>

    echo     ^<Property Id="INSTALL_MYSQL" Value="1" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_REDIS" Value="1" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_MONGODB" Value="1" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_MEILISEARCH" Value="1" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_LMS" Value="1" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_CMS" Value="1" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_WORKERS" Value="1" Secure="yes" /^>
    echo     ^<Property Id="IMPORT_DEMO_CONTENT" Value="0" Secure="yes" /^>
    echo     ^<Property Id="INSTALL_MFES" Value="0" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_THEME" Value="none" Secure="yes" /^>
    echo     ^<Property Id="PROP_OPENEDX_THEME_REPO_URL" Secure="yes" /^>
    echo     ^<Property Id="BACKUPFOLDER" Value="C:\ProgramData\OpenEdX\backups" Secure="yes" /^>

    echo     ^<Property Id="MsiHiddenProperties" Value="PROP_OPENEDX_ADMIN_PASSWORD;PROP_OPENEDX_SECRET_KEY;PROP_MYSQL_ROOT_PASSWORD;PROP_MYSQL_REMOTE_URL;PROP_REDIS_PASSWORD;PROP_REDIS_URL;PROP_MONGODB_URI;PROP_MEILISEARCH_MASTER_KEY;PROP_OPENEDX_REPO_AUTH_TOKEN" /^>

    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFiles64Folder"^>
    echo         ^<Directory Id="INSTALLFOLDER" Name="OpenEdX"^>
    echo           ^<Directory Id="LIBSCRIPT_FOLDER" Name="libscript" /^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo       ^<Directory Id="ProgramMenuFolder"^>
    echo         ^<Directory Id="OpenEdXProgramMenuFolder" Name="Open edX" /^>
    echo       ^</Directory^>
    echo       ^<Directory Id="DesktopFolder" Name="Desktop" /^>
    echo       ^<Directory Id="CommonAppDataFolder"^>
    echo         ^<Directory Id="COMPANYDATAFOLDER" Name="OpenEdX"^>
    echo           ^<Directory Id="DATAFOLDER" Name="data" /^>
    echo           ^<Directory Id="LOGSFOLDER" Name="logs" /^>
    echo           ^<Directory Id="BACKUPFOLDER" Name="backups" /^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo     ^</Directory^>

    echo     ^<CustomAction Id="CA_CheckNetworkConnection" Directory="INSTALLFOLDER" ExeCommand="powershell.exe -NoProfile -Command &quot;try { (New-Object System.Net.Sockets.TcpClient('github.com', 443)).Close(); (New-Object System.Net.Sockets.TcpClient('pypi.org', 443)).Close(); } catch { exit 1 }&quot;" Execute="immediate" Return="ignore" /^>
    echo     ^<CustomAction Id="CA_LaunchBrowser" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\packaging\launch_browser.cmd&quot; http://[PROP_LMS_HOST]:[PROP_LMS_PORT] &quot;Open edX LMS&quot;" Return="asyncNoWait" /^>
    echo     ^<CustomAction Id="CA_LaunchStudio" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\packaging\launch_browser.cmd&quot; http://[PROP_CMS_HOST]:[PROP_CMS_PORT] &quot;Open edX Studio&quot;" Return="asyncNoWait" /^>
    echo     ^<CustomAction Id="InstallOpenEdXService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install stacks/cms/openedx --offline=[PROP_OPENEDX_OFFLINE] --lms-port=[PROP_LMS_PORT] --cms-port=[PROP_CMS_PORT] --mysql-url=&quot;[PROP_MYSQL_REMOTE_URL]&quot; --redis-port=[PROP_REDIS_PORT] --redis-url=&quot;[PROP_REDIS_URL]&quot; --mongodb-uri=&quot;[PROP_MONGODB_URI]&quot; --repo=&quot;[PROP_OPENEDX_EDX_PLATFORM_REPOSITORY]&quot; --version=&quot;[PROP_OPENEDX_VERSION]&quot; --admin-user=&quot;[PROP_OPENEDX_ADMIN_USERNAME]&quot; --admin-password=&quot;[PROP_OPENEDX_ADMIN_PASSWORD]&quot; --admin-email=&quot;[PROP_OPENEDX_ADMIN_EMAIL]&quot; --backup-dir=&quot;[BACKUPFOLDER]&quot; --theme=&quot;[PROP_OPENEDX_THEME]&quot;" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="InstallWorkersService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\workers.cmd&quot; start" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="StopWorkersService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\workers.cmd&quot; stop" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="ImportDemoContentAction" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\import_demo.cmd&quot; course &amp;&amp; &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\import_demo.cmd&quot; libraries" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="BuildMFEsAction" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\mfe.cmd&quot; build all &amp;&amp; &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\mfe.cmd&quot; deploy all" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="PostInstallHealthcheck" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\healthcheck.cmd&quot;" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="InstallMySQLService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install databases/mysql --port=[PROP_MYSQL_PORT]" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="InstallRedisService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install caches/redis --port=[PROP_REDIS_PORT]" Execute="deferred" Return="ignore" Impersonate="no" /^>
    echo     ^<CustomAction Id="UninstallOpenEdXService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; uninstall stacks/cms/openedx [PURGE_openedx]" Execute="deferred" Return="ignore" Impersonate="no" /^>

    echo     ^<UI Id="CustomUI"^>
    echo       ^<Property Id="DefaultUIFont" Value="WixUI_Font_Normal" /^>

    echo       ^<Dialog Id="Dlg_Welcome" Width="370" Height="270" Title="Welcome to [ProductName] Setup"^>
    if not "%BANNER_SIDE_PATH%"=="" echo         ^<Control Id="Bitmap" Type="Bitmap" X="0" Y="0" Width="123" Height="234" Text="WixUIDialogBmp" /^>
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="135" Y="20" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="Welcome to the [ProductName] Setup Wizard" /^>
    echo         ^<Control Id="Description" Type="Text" X="135" Y="70" Width="220" Height="70" Transparent="yes" NoPrefix="yes" Text="%WELCOME_DESC%" /^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Disabled="yes" Text="Back" /^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_License"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_License" Width="370" Height="270" Title="[ProductName] Setup"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="End-User License Agreement" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Please read the following license agreement carefully." /^>
    if not "%LICENSE_PATH%"=="" (
        echo         ^<Control Id="AgreementText" Type="ScrollableText" X="20" Y="48" Width="330" Height="178" Sunken="yes" TabSkip="no"^>
        echo           ^<Text SourceFile="%LICENSE_PATH%" /^>
        echo         ^</Control^>
    )
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_Welcome"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="I Agree"^>
    echo           ^<Publish Property="LICENSE_ACCEPTED" Value="1"^>1^</Publish^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_SetupType"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_SetupType" Width="370" Height="270" Title="Choose Installation Mode"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Choose Setup Type" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select your preferred deployment method." /^>
    echo         ^<Control Id="RadioGroup" Type="RadioButtonGroup" X="20" Y="60" Width="330" Height="120" Property="SETUP_MODE"^>
    echo           ^<RadioButtonGroup Property="SETUP_MODE"^>
    echo             ^<RadioButton Value="Simple" X="0" Y="0" Width="320" Height="30" Text="Simple Mode (Express Install) - Installs all components with recommended defaults" /^>
    echo             ^<RadioButton Value="Advanced" X="0" Y="45" Width="320" Height="30" Text="Advanced Mode (Custom Configuration) - Customize component selection, DBaaS URLs, and ports" /^>
    echo           ^</RadioButtonGroup^>
    echo         ^</Control^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_License"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_Features"^>^<![CDATA[SETUP_MODE="Advanced"]]^>^</Publish^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_VerifyReady"^>^<![CDATA[SETUP_MODE="Simple"]]^>^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_Features" Width="370" Height="270" Title="Custom Component Selection"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Component Selection &amp; Architecture" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Review required runtimes and configure optional services." /^>
    echo         ^<Control Id="Lbl_NonOptHeader" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Non-Optional Components (always installed):" /^>
    echo         ^<Control Id="Lbl_NonOptList" Type="Text" X="28" Y="63" Width="320" Height="50" NoPrefix="yes" Text="- Python (Python 3.11+ runtime &amp; virtual environment)&#13;&#10;- Node.js (Node.js &amp; npm asset pipeline)&#13;&#10;- Meilisearch (Course search and catalog discovery engine)&#13;&#10;- MySQL (Relational database) &amp; Redis (Cache &amp; Celery broker)&#13;&#10;- MongoDB (Course document datastore)" /^>
    echo         ^<Control Id="Lbl_OptHeader" Type="Text" X="20" Y="114" Width="330" Height="14" NoPrefix="yes" Text="Optional / Configurable Services:" /^>
    echo         ^<Control Id="Chk_LMS" Type="CheckBox" X="28" Y="128" Width="320" Height="14" Property="INSTALL_LMS" CheckBoxValue="1" Text="Open edX LMS Core Service (Port 8000)" /^>
    echo         ^<Control Id="Chk_CMS" Type="CheckBox" X="28" Y="142" Width="320" Height="14" Property="INSTALL_CMS" CheckBoxValue="1" Text="Open edX Studio / CMS Course Authoring (Port 8001)" /^>
    echo         ^<Control Id="Chk_MySQL" Type="CheckBox" X="28" Y="156" Width="320" Height="14" Property="INSTALL_MYSQL" CheckBoxValue="1" Text="Install Local MySQL Service (uncheck if using DBaaS)" /^>
    echo         ^<Control Id="Chk_Redis" Type="CheckBox" X="28" Y="170" Width="320" Height="14" Property="INSTALL_REDIS" CheckBoxValue="1" Text="Install Local Redis Service (uncheck if using Cloud Redis)" /^>
    echo         ^<Control Id="Chk_Workers" Type="CheckBox" X="28" Y="184" Width="320" Height="14" Property="INSTALL_WORKERS" CheckBoxValue="1" Text="Launch Celery Background Workers &amp; Scheduler" /^>
    echo         ^<Control Id="Chk_Demo" Type="CheckBox" X="28" Y="198" Width="320" Height="14" Property="IMPORT_DEMO_CONTENT" CheckBoxValue="1" Text="Import edX Demo Course &amp; Content Libraries" /^>
    echo         ^<Control Id="Chk_MFEs" Type="CheckBox" X="28" Y="212" Width="320" Height="14" Property="INSTALL_MFES" CheckBoxValue="1" Text="Build and Deploy Micro-Frontends (Learning, Authn, Account)" /^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_SetupType"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_InstallLocation"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_InstallLocation" Width="370" Height="270" Title="Destination Folders"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Destination Folders" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select target locations for binaries, databases, logs, and backups." /^>
    echo         ^<Control Id="Lbl_AppFolder" Type="Text" X="20" Y="48" Width="330" Height="13" NoPrefix="yes" Text="Application Installation Folder:" /^>
    echo         ^<Control Id="Txt_AppFolder" Type="PathEdit" X="20" Y="61" Width="260" Height="17" Property="INSTALLFOLDER" /^>
    echo         ^<Control Id="Btn_BrowseApp" Type="PushButton" X="285" Y="61" Width="65" Height="17" Text="Browse..."^>
    echo           ^<Publish Property="_BrowseProperty" Value="INSTALLFOLDER"^>1^</Publish^>
    echo           ^<Publish Event="SpawnDialog" Value="BrowseDlg"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Lbl_DataFolder" Type="Text" X="20" Y="80" Width="330" Height="13" NoPrefix="yes" Text="Databases and Media Storage Folder:" /^>
    echo         ^<Control Id="Txt_DataFolder" Type="PathEdit" X="20" Y="93" Width="260" Height="17" Property="DATAFOLDER" /^>
    echo         ^<Control Id="Btn_BrowseData" Type="PushButton" X="285" Y="93" Width="65" Height="17" Text="Browse..."^>
    echo           ^<Publish Property="_BrowseProperty" Value="DATAFOLDER"^>1^</Publish^>
    echo           ^<Publish Event="SpawnDialog" Value="BrowseDlg"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Lbl_LogsFolder" Type="Text" X="20" Y="112" Width="330" Height="13" NoPrefix="yes" Text="Log Files Folder:" /^>
    echo         ^<Control Id="Txt_LogsFolder" Type="PathEdit" X="20" Y="125" Width="260" Height="17" Property="LOGSFOLDER" /^>
    echo         ^<Control Id="Btn_BrowseLogs" Type="PushButton" X="285" Y="125" Width="65" Height="17" Text="Browse..."^>
    echo           ^<Publish Property="_BrowseProperty" Value="LOGSFOLDER"^>1^</Publish^>
    echo           ^<Publish Event="SpawnDialog" Value="BrowseDlg"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Lbl_BackupFolder" Type="Text" X="20" Y="144" Width="330" Height="13" NoPrefix="yes" Text="Automated Snapshots &amp; Backups Folder:" /^>
    echo         ^<Control Id="Txt_BackupFolder" Type="PathEdit" X="20" Y="157" Width="260" Height="17" Property="BACKUPFOLDER" /^>
    echo         ^<Control Id="Btn_BrowseBackup" Type="PushButton" X="285" Y="157" Width="65" Height="17" Text="Browse..."^>
    echo           ^<Publish Property="_BrowseProperty" Value="BACKUPFOLDER"^>1^</Publish^>
    echo           ^<Publish Event="SpawnDialog" Value="BrowseDlg"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_Features"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_RuntimeSelection"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_RuntimeSelection" Width="370" Height="270" Title="Runtime Environment Selection"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Runtime Environments" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure Python and Node.js execution runtime providers." /^>
    echo         ^<Control Id="Grp_Python" Type="GroupBox" X="20" Y="50" Width="330" Height="70" Text="Python 3.11+ Execution Runtime" /^>
    echo         ^<Control Id="Rad_PythonExisting" Type="RadioButtonGroup" X="28" Y="65" Width="310" Height="45" Property="USE_EXISTING_PYTHON"^>
    echo           ^<RadioButtonGroup Property="USE_EXISTING_PYTHON"^>
    echo             ^<RadioButton Value="1" X="0" Y="0" Width="310" Height="20" Text="Reuse existing system Python: [FOUND_PYTHON_EXE]" /^>
    echo             ^<RadioButton Value="0" X="0" Y="22" Width="310" Height="20" Text="Install isolated private Python runtime via LibScript" /^>
    echo           ^</RadioButtonGroup^>
    echo         ^</Control^>
    echo         ^<Control Id="Grp_Node" Type="GroupBox" X="20" Y="125" Width="330" Height="70" Text="Node.js 18/20+ Asset Pipeline Runtime" /^>
    echo         ^<Control Id="Rad_NodeExisting" Type="RadioButtonGroup" X="28" Y="140" Width="310" Height="45" Property="USE_EXISTING_NODE"^>
    echo           ^<RadioButtonGroup Property="USE_EXISTING_NODE"^>
    echo             ^<RadioButton Value="1" X="0" Y="0" Width="310" Height="20" Text="Reuse existing system Node.js: [FOUND_NODE_EXE]" /^>
    echo             ^<RadioButton Value="0" X="0" Y="22" Width="310" Height="20" Text="Install isolated private Node.js runtime via LibScript" /^>
    echo           ^</RadioButtonGroup^>
    echo         ^</Control^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_InstallLocation"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_SourceRepo"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_OpenEdX_SourceRepo" Width="370" Height="270" Title="Source Repository &amp; Release Selection"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Source Repository &amp; Release" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Review the repository source and branch configured for this installer." /^>
    echo         ^<Control Id="Lbl_Repo" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Configured edx-platform Repository Source (Read-Only):" /^>
    echo         ^<Control Id="Txt_Repo" Type="Edit" X="20" Y="63" Width="330" Height="18" Property="PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Disabled="yes" /^>
    echo         ^<Control Id="Hint_Repo" Type="Text" X="20" Y="83" Width="330" Height="22" Transparent="yes" NoPrefix="yes" Text="Source repository, local path, or fork configured during installer build." /^>
    echo         ^<Control Id="Lbl_Branch" Type="Text" X="20" Y="110" Width="330" Height="14" NoPrefix="yes" Text="Configured Target Release, Branch, or Tag (Read-Only):" /^>
    echo         ^<Control Id="Txt_Branch" Type="Edit" X="20" Y="125" Width="330" Height="18" Property="PROP_OPENEDX_VERSION" Disabled="yes" /^>
    echo         ^<Control Id="Hint_Branch" Type="Text" X="20" Y="145" Width="330" Height="22" Transparent="yes" NoPrefix="yes" Text="Target branch, release tag, or commit SHA configured during installer build." /^>
    echo         ^<Control Id="Lbl_Token" Type="Text" X="20" Y="175" Width="330" Height="14" NoPrefix="yes" Text="Private Repository Access Token (optional if private fork):" /^>
    echo         ^<Control Id="Txt_Token" Type="Edit" X="20" Y="190" Width="330" Height="18" Property="PROP_OPENEDX_REPO_AUTH_TOKEN" Password="yes" /^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_RuntimeSelection"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_Config"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_OpenEdX_Config" Width="370" Height="270" Title="Network and Credentials Configuration"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Network &amp; Credentials" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Set service ports and administrator credentials." /^>
    echo         ^<Control Id="Lbl_LmsPort" Type="Text" X="20" Y="50" Width="150" Height="15" Text="LMS Web Port:" /^>
    echo         ^<Control Id="Txt_LmsPort" Type="Edit" X="20" Y="65" Width="140" Height="18" Property="PROP_LMS_PORT" /^>
    echo         ^<Control Id="Lbl_CmsPort" Type="Text" X="180" Y="50" Width="150" Height="15" Text="Studio Web Port:" /^>
    echo         ^<Control Id="Txt_CmsPort" Type="Edit" X="180" Y="65" Width="140" Height="18" Property="PROP_CMS_PORT" /^>

    echo         ^<Control Id="Lbl_AdminUser" Type="Text" X="20" Y="90" Width="150" Height="15" Text="Superuser Username:" /^>
    echo         ^<Control Id="Txt_AdminUser" Type="Edit" X="20" Y="105" Width="140" Height="18" Property="PROP_OPENEDX_ADMIN_USERNAME" /^>
    echo         ^<Control Id="Lbl_AdminPass" Type="Text" X="180" Y="90" Width="150" Height="15" Text="Superuser Password:" /^>
    echo         ^<Control Id="Txt_AdminPass" Type="Edit" X="180" Y="105" Width="140" Height="18" Property="PROP_OPENEDX_ADMIN_PASSWORD" Password="yes" /^>

    echo         ^<Control Id="Lbl_AdminEmail" Type="Text" X="20" Y="130" Width="300" Height="15" Text="Superuser Email Address:" /^>
    echo         ^<Control Id="Txt_AdminEmail" Type="Edit" X="20" Y="145" Width="300" Height="18" Property="PROP_OPENEDX_ADMIN_EMAIL" /^>
    echo         ^<Control Id="Lbl_Theme" Type="Text" X="20" Y="170" Width="150" Height="15" Text="Theme Name (or 'none'):" /^>
    echo         ^<Control Id="Txt_Theme" Type="Edit" X="20" Y="185" Width="140" Height="18" Property="PROP_OPENEDX_THEME" /^>
    echo         ^<Control Id="Lbl_ThemeUrl" Type="Text" X="180" Y="170" Width="150" Height="15" Text="Custom Theme Git URL:" /^>
    echo         ^<Control Id="Txt_ThemeUrl" Type="Edit" X="180" Y="185" Width="170" Height="18" Property="PROP_OPENEDX_THEME_REPO_URL" /^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_SourceRepo"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_DB"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_OpenEdX_DB" Width="370" Height="270" Title="Relational Database / DBaaS Configuration"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Database &amp; DBaaS Configuration" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure MySQL or an External DBaaS Provider." /^>
    echo         ^<Control Id="Lbl_LocalPort" Type="Text" X="20" Y="50" Width="300" Height="15" Text="Local MySQL Port (if self-hosted):" /^>
    echo         ^<Control Id="Txt_LocalPort" Type="Edit" X="20" Y="65" Width="120" Height="18" Property="PROP_MYSQL_PORT" /^>

    echo         ^<Control Id="Lbl_RemoteUrl" Type="Text" X="20" Y="90" Width="330" Height="15" Text="External DBaaS URL (e.g. AWS RDS / PlanetScale / Azure):" /^>
    echo         ^<Control Id="Txt_RemoteUrl" Type="Edit" X="20" Y="105" Width="330" Height="18" Property="PROP_MYSQL_REMOTE_URL" Password="yes" /^>
    echo         ^<Control Id="Hint_Remote" Type="Text" X="20" Y="125" Width="330" Height="25" Transparent="yes" Text="Format: mysql://user:password@host:port/database. Providing a remote DBaaS URL automatically bypasses local MySQL setup." /^>

    echo         ^<Control Id="Lbl_RootPass" Type="Text" X="20" Y="155" Width="300" Height="15" Text="Local MySQL Root Password (ignored if DBaaS is used):" /^>
    echo         ^<Control Id="Txt_RootPass" Type="Edit" X="20" Y="170" Width="200" Height="18" Property="PROP_MYSQL_ROOT_PASSWORD" Password="yes" /^>

    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_Config"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_CacheSearch"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_OpenEdX_CacheSearch" Width="370" Height="270" Title="Cache, Document Store &amp; Search Configuration"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Cache, Document Store &amp; Search" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure Redis, MongoDB Atlas, and Meilisearch." /^>

    echo         ^<Control Id="Lbl_RedisPort" Type="Text" X="20" Y="50" Width="150" Height="15" Text="Redis Port (e.g. 6379, 6380):" /^>
    echo         ^<Control Id="Txt_RedisPort" Type="Edit" X="20" Y="65" Width="120" Height="18" Property="PROP_REDIS_PORT" /^>
    echo         ^<Control Id="Lbl_RedisUrl" Type="Text" X="160" Y="50" Width="190" Height="15" Text="Remote Redis DBaaS / URI:" /^>
    echo         ^<Control Id="Txt_RedisUrl" Type="Edit" X="160" Y="65" Width="190" Height="18" Property="PROP_REDIS_URL" Password="yes" /^>

    echo         ^<Control Id="Lbl_MongoUri" Type="Text" X="20" Y="95" Width="330" Height="15" Text="MongoDB Atlas URI / Connection String:" /^>
    echo         ^<Control Id="Txt_MongoUri" Type="Edit" X="20" Y="110" Width="330" Height="18" Property="PROP_MONGODB_URI" Password="yes" /^>

    echo         ^<Control Id="Lbl_MeiliUrl" Type="Text" X="20" Y="135" Width="330" Height="15" Text="Remote Meilisearch Cloud URL:" /^>
    echo         ^<Control Id="Txt_MeiliUrl" Type="Edit" X="20" Y="150" Width="330" Height="18" Property="PROP_MEILISEARCH_CUSTOM_URL" /^>

    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_DB"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_VerifyReady"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_VerifyReady" Width="370" Height="270" Title="Ready to Install [ProductName]"^>
    if not "%BANNER_TOP_PATH%"=="" (
        echo         ^<Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" /^>
        echo         ^<Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" /^>
    )
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Ready to Install [ProductName]" /^>
    echo         ^<Control Id="Description" Type="Text" X="25" Y="22" Width="280" Height="20" Transparent="yes" NoPrefix="yes" Text="Review the components being installed on your computer." /^>
    echo         ^<Control Id="Summary" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Non-optional components to be installed:" /^>
    echo         ^<Control Id="CompPython" Type="Text" X="28" Y="64" Width="320" Height="13" NoPrefix="yes" Text="- python (Python 3.11+ runtime &amp; virtual environment)%COMP_TAG%" /^>
    echo         ^<Control Id="CompNode" Type="Text" X="28" Y="78" Width="320" Height="13" NoPrefix="yes" Text="- nodejs (Node.js &amp; npm asset compilation pipeline)%COMP_TAG%" /^>
    echo         ^<Control Id="CompMeili" Type="Text" X="28" Y="92" Width="320" Height="13" NoPrefix="yes" Text="- meilisearch (Course search and catalog discovery engine)%COMP_TAG%" /^>
    echo         ^<Control Id="CompMySQL" Type="Text" X="28" Y="106" Width="320" Height="13" NoPrefix="yes" Text="- mysql (Relational database for users and course metadata)%COMP_TAG%" /^>
    echo         ^<Control Id="CompRedis" Type="Text" X="28" Y="120" Width="320" Height="13" NoPrefix="yes" Text="- redis (In-memory caching and Celery asynchronous task broker)%COMP_TAG%" /^>
    echo         ^<Control Id="CompMongo" Type="Text" X="28" Y="134" Width="320" Height="13" NoPrefix="yes" Text="- mongodb (Document datastore for courseware modules)%COMP_TAG%" /^>
    echo         ^<Control Id="CompLMS" Type="Text" X="28" Y="148" Width="320" Height="13" NoPrefix="yes" Text="- openedx (Open edX LMS on port [PROP_LMS_PORT], Studio on port [PROP_CMS_PORT])%COMP_TAG%" /^>
    echo         ^<Control Id="CompWorkers" Type="Text" X="28" Y="162" Width="320" Height="13" NoPrefix="yes" Text="- workers (Celery asynchronous task workers &amp; beat scheduler)%COMP_TAG%" /^>
    echo         ^<Control Id="CompDemo" Type="Text" X="28" Y="176" Width="320" Height="13" NoPrefix="yes" Text="- content (Demo courseware and content libraries catalog)%COMP_TAG%" /^>
    echo         ^<Control Id="CompMFEs" Type="Text" X="28" Y="190" Width="320" Height="13" NoPrefix="yes" Text="- mfes (Micro-Frontends: Learning, Authn, Account)%COMP_TAG%" /^>
    echo         ^<Control Id="Instructions" Type="Text" X="20" Y="208" Width="330" Height="24" Text="Click Install to begin installation. If you want to review or change any settings, click Back." /^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back"^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_SetupType"^>^<![CDATA[SETUP_MODE="Simple"]]^>^</Publish^>
    echo           ^<Publish Event="NewDialog" Value="Dlg_OpenEdX_CacheSearch"^>^<![CDATA[SETUP_MODE="Advanced"]]^>^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Install" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Install"^>
    echo           ^<Publish Event="EndDialog" Value="Return"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel"^>
    echo           ^<Publish Event="EndDialog" Value="Exit"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<Dialog Id="Dlg_Exit" Width="370" Height="270" Title="[ProductName] Setup Complete"^>
    if not "%BANNER_SIDE_PATH%"=="" echo         ^<Control Id="Bitmap" Type="Bitmap" X="0" Y="0" Width="123" Height="234" Text="WixUIDialogBmp" /^>
    echo         ^<Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" /^>
    echo         ^<Control Id="Title" Type="Text" X="135" Y="20" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="Completed [ProductName] Setup" /^>
    echo         ^<Control Id="Desc" Type="Text" X="135" Y="70" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="Open edX services have been successfully installed and started." /^>
    echo         ^<Control Id="LaunchBrowserCheckBox" Type="CheckBox" X="135" Y="150" Width="220" Height="18" Property="LAUNCH_BROWSER" CheckBoxValue="1" Text="Launch Open edX LMS in Web Browser" /^>
    echo         ^<Control Id="LaunchStudioCheckBox" Type="CheckBox" X="135" Y="172" Width="220" Height="18" Property="LAUNCH_STUDIO" CheckBoxValue="1" Text="Launch Open edX Studio in Web Browser" /^>
    echo         ^<Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Disabled="yes" Text="Back" /^>
    echo         ^<Control Id="Finish" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Finish"^>
    echo           ^<Publish Event="DoAction" Value="CA_LaunchBrowser"^>^<![CDATA[LAUNCH_BROWSER="1" AND NOT Installed]]^>^</Publish^>
    echo           ^<Publish Event="DoAction" Value="CA_LaunchStudio"^>^<![CDATA[LAUNCH_STUDIO="1" AND NOT Installed]]^>^</Publish^>
    echo           ^<Publish Event="EndDialog" Value="Return"^>1^</Publish^>
    echo         ^</Control^>
    echo         ^<Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Disabled="yes" Text="Cancel" /^>
    echo       ^</Dialog^>

    echo       ^<InstallUISequence^>
    echo         ^<Custom Action="CA_CheckNetworkConnection" After="CostFinalize"^>^<![CDATA[NOT Installed AND PROP_OPENEDX_OFFLINE="0"]]^>^</Custom^>
    echo         ^<Show Dialog="Dlg_Welcome" After="CostFinalize"^>NOT Installed^</Show^>
    echo         ^<Show Dialog="Dlg_License" After="Dlg_Welcome"^>NOT Installed^</Show^>
    echo         ^<Show Dialog="Dlg_SetupType" After="Dlg_License"^>NOT Installed^</Show^>
    echo         ^<Show Dialog="Dlg_Features" After="Dlg_SetupType"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_InstallLocation" After="Dlg_Features"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_RuntimeSelection" After="Dlg_InstallLocation"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_OpenEdX_SourceRepo" After="Dlg_RuntimeSelection"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_OpenEdX_Config" After="Dlg_OpenEdX_SourceRepo"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_OpenEdX_DB" After="Dlg_OpenEdX_Config"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_OpenEdX_CacheSearch" After="Dlg_OpenEdX_DB"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_VerifyReady" After="Dlg_OpenEdX_CacheSearch"^>^<![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_VerifyReady" After="Dlg_SetupType"^>^<![CDATA[NOT Installed AND SETUP_MODE="Simple"]]^>^</Show^>
    echo         ^<Show Dialog="Dlg_Exit" OnExit="success"^>NOT Installed^</Show^>
    echo       ^</InstallUISequence^>
    echo     ^</UI^>

    echo     ^<InstallExecuteSequence^>
    echo       ^<CostInitialize Sequence="800" /^>
    echo       ^<FileCost Sequence="900" /^>
    echo       ^<CostFinalize Sequence="1000" /^>
    echo       ^<Custom Action="InstallMySQLService" Before="InstallOpenEdXService"^>^<![CDATA[NOT Installed AND INSTALL_MYSQL="1" AND NOT PROP_MYSQL_REMOTE_URL AND NOT PROP_OPENEDX_OFFLINE="1"]]^>^</Custom^>
    echo       ^<Custom Action="InstallRedisService" Before="InstallOpenEdXService"^>^<![CDATA[NOT Installed AND INSTALL_REDIS="1" AND NOT PROP_REDIS_URL AND NOT PROP_OPENEDX_OFFLINE="1"]]^>^</Custom^>
    echo       ^<Custom Action="InstallOpenEdXService" Before="InstallFinalize"^>^<![CDATA[NOT Installed AND INSTALL_LMS="1"]]^>^</Custom^>
    echo       ^<Custom Action="InstallWorkersService" After="InstallOpenEdXService"^>^<![CDATA[NOT Installed AND INSTALL_WORKERS="1"]]^>^</Custom^>
    echo       ^<Custom Action="ImportDemoContentAction" After="InstallOpenEdXService"^>^<![CDATA[NOT Installed AND IMPORT_DEMO_CONTENT="1"]]^>^</Custom^>
    echo       ^<Custom Action="BuildMFEsAction" After="InstallOpenEdXService"^>^<![CDATA[NOT Installed AND INSTALL_MFES="1"]]^>^</Custom^>
    echo       ^<Custom Action="PostInstallHealthcheck" After="InstallOpenEdXService"^>^<![CDATA[NOT Installed]]^>^</Custom^>
    echo       ^<Custom Action="StopWorkersService" Before="UninstallOpenEdXService"^>^<![CDATA[REMOVE="ALL"]]^>^</Custom^>
    echo       ^<Custom Action="UninstallOpenEdXService" Before="RemoveFiles"^>REMOVE="ALL"^</Custom^>
    echo     ^</InstallExecuteSequence^>

    echo     ^<Feature Id="ProductFeature" Title="%APP_NAME%" Level="1"^>
    echo       ^<ComponentGroupRef Id="ProductComponents" /^>
    echo       ^<ComponentGroupRef Id="LibscriptHarvestedComponents" /^>
    if /I "%VARIANT%"=="offline" echo       ^<ComponentGroupRef Id="LibscriptOfflineCacheComponents" /^>
    echo       ^<ComponentRef Id="CoursewareDataStore" /^>
    echo       ^<ComponentRef Id="CoursewareLogStore" /^>
    echo       ^<ComponentRef Id="CoursewareBackupStore" /^>
    echo       ^<ComponentRef Id="ApplicationShortcuts" /^>
    echo       ^<ComponentRef Id="EnvironmentSettings" /^>
    echo     ^</Feature^>
    echo   ^</Product^>

    echo   ^<Fragment^>
    echo     ^<ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER"^>
    echo       ^<Component Id="AppManifestComponent" Guid="E2A89C15-99BD-4720-A0E8-A97A2E504F63"^>
    echo         ^<File Id="ManifestFile" Source="stacks\cms\openedx\manifest.json" KeyPath="yes" /^>
    echo       ^</Component^>
    echo       ^<Component Id="VarsSchemaComponent" Guid="D1A72951-86E3-4E61-A79B-7D8C430931B5"^>
    echo         ^<File Id="VarsSchemaFile" Source="stacks\cms\openedx\vars.schema.json" KeyPath="yes" /^>
    echo       ^</Component^>
    echo       ^<Component Id="PackagingJsonComponent" Guid="C4A82110-5321-4FA6-9B3B-8D7E6512A098"^>
    echo         ^<File Id="PackagingJsonFile" Source="stacks\cms\openedx\packaging.json" KeyPath="yes" /^>
    echo       ^</Component^>
    echo       ^<Component Id="CliScriptComponent" Guid="B35F9271-2B4A-48DC-8812-3D7C51094E1A"^>
    echo         ^<File Id="CliCmdFile" Source="stacks\cms\openedx\cli.cmd" KeyPath="yes" /^>
    echo         ^<File Id="CliShFile" Source="stacks\cms\openedx\cli.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="UserScriptComponent" Guid="A91283F1-15D2-46A9-81FE-2B45CD98103F"^>
    echo         ^<File Id="UserCmdFile" Source="stacks\cms\openedx\user.cmd" KeyPath="yes" /^>
    echo         ^<File Id="UserShFile" Source="stacks\cms\openedx\user.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="ImportDemoScriptComponent" Guid="87123A0B-4321-48C1-871B-9430CD7812E5"^>
    echo         ^<File Id="ImportDemoCmdFile" Source="stacks\cms\openedx\import_demo.cmd" KeyPath="yes" /^>
    echo         ^<File Id="ImportDemoShFile" Source="stacks\cms\openedx\import_demo.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="DbShellScriptComponent" Guid="521A79B2-9F12-4C18-91AA-56193BF43109"^>
    echo         ^<File Id="DbShellCmdFile" Source="stacks\cms\openedx\dbshell.cmd" KeyPath="yes" /^>
    echo         ^<File Id="DbShellShFile" Source="stacks\cms\openedx\dbshell.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="HealthcheckScriptComponent" Guid="3190BCA1-71E5-4890-85A2-671239EF1045"^>
    echo         ^<File Id="HealthcheckCmdFile" Source="stacks\cms\openedx\healthcheck.cmd" KeyPath="yes" /^>
    echo         ^<File Id="HealthcheckShFile" Source="stacks\cms\openedx\healthcheck.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="ConfigScriptComponent" Guid="781A3290-E5A1-4F29-B109-873429185CA2"^>
    echo         ^<File Id="ConfigCmdFile" Source="stacks\cms\openedx\config.cmd" KeyPath="yes" /^>
    echo         ^<File Id="ConfigShFile" Source="stacks\cms\openedx\config.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="BackupScriptComponent" Guid="91823CA5-B410-4821-A951-871295A642B1"^>
    echo         ^<File Id="BackupCmdFile" Source="stacks\cms\openedx\backup.cmd" KeyPath="yes" /^>
    echo         ^<File Id="BackupShFile" Source="stacks\cms\openedx\backup.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="RestoreScriptComponent" Guid="65109AB3-7182-4C91-A281-541982736AE4"^>
    echo         ^<File Id="RestoreCmdFile" Source="stacks\cms\openedx\restore.cmd" KeyPath="yes" /^>
    echo         ^<File Id="RestoreShFile" Source="stacks\cms\openedx\restore.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="WorkersScriptComponent" Guid="418293B7-A619-4F52-8719-741982365BAC"^>
    echo         ^<File Id="WorkersCmdFile" Source="stacks\cms\openedx\workers.cmd" KeyPath="yes" /^>
    echo         ^<File Id="WorkersShFile" Source="stacks\cms\openedx\workers.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="ThemeScriptComponent" Guid="27189A45-C918-42A9-9812-651928473ACB"^>
    echo         ^<File Id="ThemeCmdFile" Source="stacks\cms\openedx\theme.cmd" KeyPath="yes" /^>
    echo         ^<File Id="ThemeShFile" Source="stacks\cms\openedx\theme.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="XBlockScriptComponent" Guid="19283746-5A6B-4C8D-9E0F-123456789ABC"^>
    echo         ^<File Id="XBlockCmdFile" Source="stacks\cms\openedx\xblock.cmd" KeyPath="yes" /^>
    echo         ^<File Id="XBlockShFile" Source="stacks\cms\openedx\xblock.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="UpgradeScriptComponent" Guid="38472910-B1C2-4D3E-8F4A-5678901234EF"^>
    echo         ^<File Id="UpgradeCmdFile" Source="stacks\cms\openedx\upgrade.cmd" KeyPath="yes" /^>
    echo         ^<File Id="UpgradeShFile" Source="stacks\cms\openedx\upgrade.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="MfeScriptComponent" Guid="59102837-A2B3-4C4D-8E5F-6789012345FA"^>
    echo         ^<File Id="MfeCmdFile" Source="stacks\cms\openedx\mfe.cmd" KeyPath="yes" /^>
    echo         ^<File Id="MfeShFile" Source="stacks\cms\openedx\mfe.sh" /^>
    echo       ^</Component^>
    echo       ^<Component Id="MockServerComponent" Guid="6A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D"^>
    echo         ^<File Id="MockServerPs1File" Source="stacks\cms\openedx\mock_server.ps1" KeyPath="yes" /^>
    echo       ^</Component^>
    echo     ^</ComponentGroup^>
    echo     ^<DirectoryRef Id="INSTALLFOLDER"^>
    echo       ^<Component Id="EnvironmentSettings" Guid="7291A843-159A-46D8-92EF-891029384756"^>
    echo         ^<Environment Id="EnvLibscriptRoot" Name="LIBSCRIPT_ROOT_DIR" Value="[INSTALLFOLDER]libscript" Permanent="no" Action="set" System="yes" /^>
    echo         ^<Environment Id="EnvPathLibscript" Name="PATH" Value="[INSTALLFOLDER]libscript" Permanent="no" Action="set" Part="last" System="yes" /^>
    echo         ^<Environment Id="EnvPathStack" Name="PATH" Value="[INSTALLFOLDER]libscript\stacks\cms\openedx" Permanent="no" Action="set" Part="last" System="yes" /^>
    echo         ^<RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX" Name="env_configured" Type="integer" Value="1" KeyPath="yes" /^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo     ^<Component Id="CoursewareDataStore" Directory="DATAFOLDER" Guid="7F28A541-11C3-4E80-990A-46D91A883C12" Permanent="yes" NeverOverwrite="yes"^>
    echo       ^<CreateFolder /^>
    echo     ^</Component^>
    echo     ^<Component Id="CoursewareLogStore" Directory="LOGSFOLDER" Guid="3E4A1521-884A-49A3-A65B-64771C5091E2" Permanent="yes" NeverOverwrite="yes"^>
    echo       ^<CreateFolder /^>
    echo     ^</Component^>
    echo     ^<Component Id="CoursewareBackupStore" Directory="BACKUPFOLDER" Guid="98127364-5A4B-4C3D-8E2F-1029384756BA" Permanent="yes" NeverOverwrite="yes"^>
    echo       ^<CreateFolder /^>
    echo     ^</Component^>
    echo     ^<Component Id="ApplicationShortcuts" Directory="OpenEdXProgramMenuFolder" Guid="718293A4-B5C6-4D7E-8F90-123456789ABC"^>
    if not "%ICON_PATH%"=="" (
        echo       ^<Shortcut Id="ShortcutCli" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" WorkingDirectory="INSTALLFOLDER" Icon="AppIcon.ico" /^>
        echo       ^<Shortcut Id="ShortcutHealth" Name="Open edX Healthcheck" Description="Open edX Diagnostics Probe" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\healthcheck.cmd" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="ShortcutDbShell" Name="Open edX Database Console" Description="Open edX MySQL Database Shell" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\dbshell.cmd" Arguments="mysql" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="ShortcutBackup" Name="Open edX Backup and Restore" Description="Open edX Backup Tool" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\backup.cmd" WorkingDirectory="INSTALLFOLDER" Icon="AppIcon.ico" /^>
        echo       ^<Shortcut Id="DesktopShortcutCli" Directory="DesktopFolder" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" WorkingDirectory="INSTALLFOLDER" Icon="AppIcon.ico" /^>
        echo       ^<Shortcut Id="DesktopShortcutLms" Directory="DesktopFolder" Name="Open edX LMS" Description="Open edX Learning Management System" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" Arguments="lms" WorkingDirectory="INSTALLFOLDER" Icon="AppIcon.ico" /^>
        echo       ^<Shortcut Id="DesktopShortcutStudio" Directory="DesktopFolder" Name="Open edX Studio" Description="Open edX Studio Course Authoring" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" Arguments="studio" WorkingDirectory="INSTALLFOLDER" Icon="AppIcon.ico" /^>
    ) else (
        echo       ^<Shortcut Id="ShortcutCli" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="ShortcutHealth" Name="Open edX Healthcheck" Description="Open edX Diagnostics Probe" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\healthcheck.cmd" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="ShortcutDbShell" Name="Open edX Database Console" Description="Open edX MySQL Database Shell" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\dbshell.cmd" Arguments="mysql" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="ShortcutBackup" Name="Open edX Backup and Restore" Description="Open edX Backup Tool" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\backup.cmd" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="DesktopShortcutCli" Directory="DesktopFolder" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="DesktopShortcutLms" Directory="DesktopFolder" Name="Open edX LMS" Description="Open edX Learning Management System" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" Arguments="lms" WorkingDirectory="INSTALLFOLDER" /^>
        echo       ^<Shortcut Id="DesktopShortcutStudio" Directory="DesktopFolder" Name="Open edX Studio" Description="Open edX Studio Course Authoring" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" Arguments="studio" WorkingDirectory="INSTALLFOLDER" /^>
    )
    echo       ^<RemoveFolder Id="CleanUpShortCutDir" Directory="OpenEdXProgramMenuFolder" On="uninstall" /^>
    echo       ^<RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX" Name="installed" Type="integer" Value="1" KeyPath="yes" /^>
    echo     ^</Component^>
    echo   ^</Fragment^>
    echo ^</Wix^>
) > "%WXS_FILE%"
endlocal

echo [PASS] Successfully generated WiX manifest: %WXS_FILE%

:: ## harvest_payload
set "PAYLOAD_WXS=%OUT_FILE%_payload.wxs"
if /I "%VARIANT%"=="offline" (
    call "%SCRIPT_DIR%\harvest_payload.cmd" --wix-fragment "%PAYLOAD_WXS%" --directory-id "LIBSCRIPT_FOLDER" --component-group "LibscriptHarvestedComponents" --include-cache "%CACHE_DIR%"
) else (
    call "%SCRIPT_DIR%\harvest_payload.cmd" --wix-fragment "%PAYLOAD_WXS%" --directory-id "LIBSCRIPT_FOLDER" --component-group "LibscriptHarvestedComponents"
)
if errorlevel 1 (
    echo [ERROR] harvest_payload.cmd failed >&2
    exit /b 1
)

:: ## compile_msi
:: Compiles the WiX manifest into an MSI binary if msi-rs or WiX toolset is present.
where msi-rs.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    msi-rs.exe pack -o "%OUT_FILE%.msi" "%WXS_FILE%"
    if errorlevel 1 (
        echo [WARN] msi-rs compilation failed; trying WiX fallback >&2
    ) else (
        echo [PASS] Successfully built %OUT_FILE%.msi via msi-rs
        goto compile_done
    )
)
where msi.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    msi.exe pack -o "%OUT_FILE%.msi" "%WXS_FILE%" >nul 2>&1
    if not errorlevel 1 (
        echo [PASS] Successfully built %OUT_FILE%.msi via msi
        goto compile_done
    )
)
set "_CANDLE_WXS=%WXS_FILE%.candle.wxs"
where candle.exe >nul 2>&1
if not %ERRORLEVEL%==0 (
    if exist "C:\Program Files (x86)\WiX Toolset v3.14\bin\candle.exe" (
        set "PATH=%PATH%;C:\Program Files (x86)\WiX Toolset v3.14\bin"
    ) else if exist "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe" (
        set "PATH=%PATH%;C:\Program Files (x86)\WiX Toolset v3.11\bin"
    )
)
where candle.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    powershell -NoProfile -Command "$w = Get-Content -LiteralPath '%WXS_FILE%' -Raw; $w = $w -replace '<Property Id=\"MsiHiddenProperties\".*?/>', ''; $w = [regex]::Replace($w, '(?s)<InstallUISequence>.*?</InstallUISequence>', '      <InstallUISequence><Show Dialog=\"Dlg_Welcome\" After=\"CostFinalize\" /><Show Dialog=\"Dlg_Exit\" OnExit=\"success\" /></InstallUISequence>'); Set-Content -LiteralPath '%WXS_FILE%.candle.wxs' -Value $w"
    candle.exe -nologo -out "%OUT_FILE%.wixobj" "%WXS_FILE%.candle.wxs"
    if errorlevel 1 (
        del /f /q "%WXS_FILE%.candle.wxs" >nul 2>&1
        echo [ERROR] WiX candle compiler failed on %WXS_FILE% >&2
        exit /b 1
    )
    candle.exe -nologo -out "%OUT_FILE%_payload.wixobj" "%PAYLOAD_WXS%"
    if errorlevel 1 (
        del /f /q "%WXS_FILE%.candle.wxs" >nul 2>&1
        echo [ERROR] WiX candle compiler failed on %PAYLOAD_WXS% >&2
        exit /b 1
    )
    light.exe -nologo -sval -ext WixUIExtension -out "%OUT_FILE%.msi" "%OUT_FILE%.wixobj" "%OUT_FILE%_payload.wixobj"
    if errorlevel 1 (
        del /f /q "%WXS_FILE%.candle.wxs" >nul 2>&1
        echo [ERROR] WiX light linker failed >&2
        exit /b 1
    )
    del /f /q "%WXS_FILE%.candle.wxs" >nul 2>&1
    echo [PASS] Successfully built %OUT_FILE%.msi
) else (
    where wix.exe >nul 2>&1
    if %ERRORLEVEL%==0 (
        wix.exe build -ext WixToolset.UI.wixext -o "%OUT_FILE%.msi" "%WXS_FILE%" "%PAYLOAD_WXS%"
        if errorlevel 1 (
            echo [ERROR] WiX build failed >&2
            exit /b 1
        )
        echo [PASS] Successfully built %OUT_FILE%.msi
    ) else (
        echo [INFO] WiX toolset compiler not found in PATH. XML manifest ready for compilation.
    )
)

exit /b 0
