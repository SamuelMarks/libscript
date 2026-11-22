@echo off
:: # deb.cmd
:: ## Overview
:: Implements packaging logic for the Debian (.deb) format on Windows by emitting a reproducible dpkg-deb build script.
:: ## Usage
:: call synthesis\formats\deb.cmd [OPTIONS] [PKG VERSION ...]

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
echo Usage: deb.cmd [--app-name NAME] [--app-version VER] [--out-dir DIR] [--offline] [PKG VERSION ...]
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

call :sanitize_slug "!APP_NAME!"
set "SAFE_APP=!SLUG_OUT!"
set "META_DEPENDS="

echo #^^!/bin/sh
echo set -e
echo OUT_DIR="!OUT_DIR!"
echo mkdir -p "$OUT_DIR"

for /L %%I in (1,1,!DEPS_COUNT!) do (
    set "_P=!DEP_PKG_%%I!"
    set "_V=!DEP_VER_%%I!"
    call :emit_deb_pkg "!_P!" "!_V!"
)

set "META_PKG=!SAFE_APP!-meta"
echo printf '%%s\n' "Building !META_PKG! ..."
echo BUILD_DIR="${TMPDIR:-/tmp}/!META_PKG!_deb_build"
echo mkdir -p "$BUILD_DIR/DEBIAN"
echo cat ^<^< 'EOF' ^> "$BUILD_DIR/DEBIAN/control"
echo Package: !META_PKG!
echo Version: !APP_VERSION!
echo Architecture: all
echo Maintainer: !APP_PUBLISHER!
if defined META_DEPENDS echo Depends: !META_DEPENDS!
echo Description: !APP_NAME! deployment metapackage
echo Homepage: !APP_URL!
echo EOF
echo dpkg-deb --root-owner-group --build "$BUILD_DIR" "$OUT_DIR/!META_PKG!_!APP_VERSION!_all.deb"
echo rm -rf "$BUILD_DIR"
echo printf '%%s\n' "Done^!"
exit /b 0

:: ## emit_deb_pkg
:: Emits dpkg-deb build commands for a single component package.
:emit_deb_pkg
set "PKG=%~1"
set "VER=%~2"
call :sanitize_slug "!PKG!"
set "SAFE_PKG=!SLUG_OUT!"
set "PKG_NAME=!SAFE_APP!-!SAFE_PKG!"
if defined META_DEPENDS (
    set "META_DEPENDS=!META_DEPENDS!, !PKG_NAME! (= !APP_VERSION!)"
) else (
    set "META_DEPENDS=!PKG_NAME! (= !APP_VERSION!)"
)
echo printf '%%s\n' "Building !PKG_NAME! ..."
echo BUILD_DIR="${TMPDIR:-/tmp}/!PKG_NAME!_deb_build"
echo mkdir -p "$BUILD_DIR/DEBIAN"
echo mkdir -p "$BUILD_DIR/opt/libscript"
if "!OFFLINE!"=="1" (
    echo cp -a "!LIBSCRIPT_ROOT_DIR!"/.* "!LIBSCRIPT_ROOT_DIR!"/* "$BUILD_DIR/opt/libscript/" 2^>/dev/null ^|^| true
    echo rm -rf "$BUILD_DIR/opt/libscript/.git"
)
echo cat ^<^< 'EOF' ^> "$BUILD_DIR/DEBIAN/control"
echo Package: !PKG_NAME!
echo Version: !APP_VERSION!
echo Architecture: all
echo Maintainer: !APP_PUBLISHER!
echo Description: !APP_NAME! deployment - !PKG!
echo Homepage: !APP_URL!
echo EOF
echo cat ^<^< 'EOF' ^> "$BUILD_DIR/DEBIAN/postinst"
echo #^^!/bin/sh
echo set -e
echo if [ "$1" = "configure" ]; then
echo   if command -v libscript.sh ^>/dev/null; then libscript.sh install-service !PKG! !VER!; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript ^&^& ./libscript.sh install-service !PKG! !VER!; fi
echo fi
echo EOF
echo chmod 0755 "$BUILD_DIR/DEBIAN/postinst"
echo cat ^<^< 'EOF' ^> "$BUILD_DIR/DEBIAN/prerm"
echo #^^!/bin/sh
echo set -e
echo if [ "$1" = "purge" ] ^|^| [ "$1" = "remove" ]; then
echo   if command -v libscript.sh ^>/dev/null; then libscript.sh uninstall !PKG!; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript ^&^& ./libscript.sh uninstall !PKG!; fi
echo fi
echo EOF
echo chmod 0755 "$BUILD_DIR/DEBIAN/prerm"
echo dpkg-deb --root-owner-group --build "$BUILD_DIR" "$OUT_DIR/!PKG_NAME!_!APP_VERSION!_all.deb"
echo rm -rf "$BUILD_DIR"
exit /b 0
