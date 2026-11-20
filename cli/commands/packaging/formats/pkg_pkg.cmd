@echo off
:: # pkg_pkg.cmd
:: ## Overview
:: Implements packaging staging logic for the macOS Installer (.pkg) format on Windows, generating component postinstall and uninstall trees.
:: ## Usage
:: call cli\commands\packaging\formats\pkg_pkg.cmd [OPTIONS] [PKG VERSION ...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "APP_NAME=LibScriptDeployment"
set "APP_VERSION=1.0.0"
set "APP_PUBLISHER=LibScript"
set "APP_URL=https://github.com/SamuelMarks/libscript"
set "OUT_DIR=."
set "OUT_FILE=installer"
set "WELCOME_TEXT="
set "LICENSE_PATH="
set "OFFLINE=0"
if "%LIBSCRIPT_OFFLINE%"=="1" set "OFFLINE=1"
set "DEPS_COUNT=0"
goto :parse_args

:: ## parse_args
:: Parses packaging flags and component/version pairs.
:parse_args
if "%~1"=="" goto :after_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="--offline" (
    set "OFFLINE=1"
    shift
    goto :parse_args
)
if /I "%~1"=="--online" (
    set "OFFLINE=0"
    shift
    goto :parse_args
)
if /I "%~1"=="--app-name" (
    set "APP_NAME=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--app-version" (
    set "APP_VERSION=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--app-publisher" (
    set "APP_PUBLISHER=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--app-url" (
    set "APP_URL=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--out-dir" (
    set "OUT_DIR=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--out" (
    set "OUT_FILE=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--welcome-text" (
    set "WELCOME_TEXT=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--license" (
    set "LICENSE_PATH=%~2"
    shift & shift
    goto :parse_args
)
set "_ARG1=%~1"
if "!_ARG1:~0,2!"=="--" (
    shift
    goto :parse_args
)
set /a DEPS_COUNT+=1
set "DEP_PKG_!DEPS_COUNT!=%~1"
set "_NEXT=%~2"
if "!_NEXT!"=="" (
    set "DEP_VER_!DEPS_COUNT!=latest"
    shift
    goto :parse_args
)
if "!_NEXT:~0,2!"=="--" (
    set "DEP_VER_!DEPS_COUNT!=latest"
    shift
    goto :parse_args
)
set "DEP_VER_!DEPS_COUNT!=%~2"
shift & shift
goto :parse_args

:: ## show_help
:: Displays command-line usage for this packaging format generator.
:show_help
echo Usage: pkg_pkg.cmd [--app-name NAME] [--app-version VER] [--out-dir DIR] [--offline] [PKG VERSION ...]
exit /b 0

:: ## sanitize_slug
:: Converts an arbitrary identifier into a lowercase package-safe slug in SLUG_OUT.
:sanitize_slug
set "_RAW=%~1"
for %%A in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
        if "%%A"=="!_RAW:~0,0!%%A" rem
    )
)
set "_SLUG=!_RAW!"
set "_SLUG=!_SLUG:A=a!"
set "_SLUG=!_SLUG:B=b!"
set "_SLUG=!_SLUG:C=c!"
set "_SLUG=!_SLUG:D=d!"
set "_SLUG=!_SLUG:E=e!"
set "_SLUG=!_SLUG:F=f!"
set "_SLUG=!_SLUG:G=g!"
set "_SLUG=!_SLUG:H=h!"
set "_SLUG=!_SLUG:I=i!"
set "_SLUG=!_SLUG:J=j!"
set "_SLUG=!_SLUG:K=k!"
set "_SLUG=!_SLUG:L=l!"
set "_SLUG=!_SLUG:M=m!"
set "_SLUG=!_SLUG:N=n!"
set "_SLUG=!_SLUG:O=o!"
set "_SLUG=!_SLUG:P=p!"
set "_SLUG=!_SLUG:Q=q!"
set "_SLUG=!_SLUG:R=r!"
set "_SLUG=!_SLUG:S=s!"
set "_SLUG=!_SLUG:T=t!"
set "_SLUG=!_SLUG:U=u!"
set "_SLUG=!_SLUG:V=v!"
set "_SLUG=!_SLUG:W=w!"
set "_SLUG=!_SLUG:X=x!"
set "_SLUG=!_SLUG:Y=y!"
set "_SLUG=!_SLUG:Z=z!"
set "_SLUG=!_SLUG:_=-!"
set "_SLUG=!_SLUG:/=-!"
set "_SLUG=!_SLUG:\=-!"
set "_SLUG=!_SLUG: =-!"
set "SLUG_OUT=!_SLUG!"
exit /b 0

:: ## after_args
:: Populates default component list if none were supplied on the command line.
:after_args
if "!DEPS_COUNT!" equ "0" (
    for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
        if /I not "%%~nxC"=="_common" (
            for /d %%M in ("%%~fC\*") do (
                if exist "%%~fM\setup.sh" (
                    set /a DEPS_COUNT+=1
                    set "DEP_PKG_!DEPS_COUNT!=%%~nxM"
                    set "DEP_VER_!DEPS_COUNT!=latest"
                )
            )
        )
    )
)

set "PKG_STAGE=!OUT_FILE!_stage"
if exist "!PKG_STAGE!" rmdir /s /q "!PKG_STAGE!" >nul 2>&1
if not exist "!PKG_STAGE!\packages" mkdir "!PKG_STAGE!\packages"
if not exist "!PKG_STAGE!\resources" mkdir "!PKG_STAGE!\resources"
if not exist "!PKG_STAGE!\scripts" mkdir "!PKG_STAGE!\scripts"

if defined WELCOME_TEXT (
    >"!PKG_STAGE!\resources\welcome.html" echo ^<html^>^<body^>^<h1^>Welcome^</h1^>^<p^>!WELCOME_TEXT!^</p^>^</body^>^</html^>
)
if defined LICENSE_PATH (
    if exist "!LICENSE_PATH!" copy /y "!LICENSE_PATH!" "!PKG_STAGE!\resources\license.html" >nul
)

for /L %%I in (1,1,!DEPS_COUNT!) do (
    set "_P=!DEP_PKG_%%I!"
    set "_V=!DEP_VER_%%I!"
    call :stage_mac_comp "!_P!" "!_V!"
)

echo Created source files in !PKG_STAGE!
echo pkgbuild/productbuild not found. Cannot build .pkg natively. 1>&2
exit /b 0

:: ## stage_mac_comp
:: Stages macOS postinstall and uninstall scripts for a single component inside PKG_STAGE.
:stage_mac_comp
set "PKG=%~1"
set "VER=%~2"
set "COMP_DIR=!PKG_STAGE!\comp_!PKG!"
if not exist "!COMP_DIR!\root\opt\libscript" mkdir "!COMP_DIR!\root\opt\libscript"
if not exist "!COMP_DIR!\scripts" mkdir "!COMP_DIR!\scripts"

(
    echo #^^!/bin/sh
    echo set -feu
    echo export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    echo if command -v libscript.sh ^>/dev/null 2^>^&1; then
    echo   libscript.sh install-service "!PKG!" "!VER!"
    echo elif [ -f "/opt/libscript/libscript.sh" ]; then
    echo   /opt/libscript/libscript.sh install-service "!PKG!" "!VER!"
    echo fi
) > "!COMP_DIR!\scripts\postinstall"

(
    echo #^^!/bin/sh
    echo set -feu
    echo sudo libscript.sh uninstall "!PKG!"
) > "!COMP_DIR!\root\opt\libscript\uninstall_!PKG!.command"
exit /b 0
