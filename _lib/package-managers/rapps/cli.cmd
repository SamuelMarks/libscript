@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface router for ReactOS Applications Manager (rapps) on Windows and ReactOS.
::
:: ## Usage
:: _lib\package-managers\rapps\cli.cmd <install|ls|ls-remote|use|uninstall|parse-ini|search|prefetch> [args]

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

if /i "%~1"=="parse-ini" (
    shift
    call :parse_ini "%~1" "%~2"
    exit /b !errorlevel!
)
if /i "%~1"=="prefetch" (
    shift
    call :prefetch_pkg %*
    exit /b !errorlevel!
)
if /i "%~1"=="search" (
    shift
    call :search_db "%~1"
    exit /b !errorlevel!
)

set "PACKAGE_NAME=rapps"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\component_core.cmd" %*
exit /b !errorlevel!

:: ## parse_ini
:: Parses a RAPPS .txt INI definition and prints normalized key=value metadata.
:parse_ini
set "_INI=%~1"
set "_PARCH=%~2"
if "!_PARCH!"=="" set "_PARCH=%LIBSCRIPT_RAPPS_ARCH%"
if "!_PARCH!"=="" set "_PARCH=i686"
if not exist "!_INI!" (
    echo [ERROR] RAPPS INI file not found: !_INI! >&2
    exit /b 1
)
set "_ASEC=x86"
if /i "!_PARCH!"=="x86_64" set "_ASEC=amd64"
if /i "!_PARCH!"=="amd64" set "_ASEC=amd64"
set "_SEC="
set "_R_NAME="
set "_R_VER="
set "_R_URL="
set "_R_SHA="
set "_R_INST="
set "_R_SILENT="
for /f "usebackq delims=" %%L in ("!_INI!") do (
    set "_LN=%%L"
    if "!_LN:~0,1!"=="[" (
        set "_SEC=!_LN!"
    ) else if not "!_LN:~0,1!"==";" (
        for /f "tokens=1* delims==" %%A in ("!_LN!") do (
            set "_K=%%A"
            set "_V=%%B"
            call :trim_var _K
            call :trim_var _V
            if /i "!_SEC!"=="[Section]" (
                if /i "!_K!"=="Name" set "_R_NAME=!_V!"
                if /i "!_K!"=="Version" set "_R_VER=!_V!"
                if /i "!_K!"=="URLDownload" if "!_R_URL!"=="" set "_R_URL=!_V!"
                if /i "!_K!"=="SHA256" if "!_R_SHA!"=="" set "_R_SHA=!_V!"
                if /i "!_K!"=="Installer" if "!_R_INST!"=="" set "_R_INST=!_V!"
                if /i "!_K!"=="SilentParameters" if "!_R_SILENT!"=="" set "_R_SILENT=!_V!"
            )
            if /i "!_SEC!"=="[Section.!_ASEC!]" (
                if /i "!_K!"=="URLDownload" set "_R_URL=!_V!"
                if /i "!_K!"=="SHA256" set "_R_SHA=!_V!"
                if /i "!_K!"=="Installer" set "_R_INST=!_V!"
                if /i "!_K!"=="SilentParameters" set "_R_SILENT=!_V!"
            )
        )
    )
)
if "!_R_SILENT!"=="" (
    if /i "!_R_INST!"=="msi" (
        set "_R_SILENT=/qn AGREE_ALL_LICENSES=1"
    ) else if /i "!_R_INST!"=="inno" (
        set "_R_SILENT=/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
    ) else (
        set "_R_SILENT=/S"
    )
)
echo NAME=!_R_NAME!
echo VERSION=!_R_VER!
echo URL=!_R_URL!
echo SHA256=!_R_SHA!
echo INSTALLER=!_R_INST!
echo SILENT_ARGS=!_R_SILENT!
exit /b 0

:: ## trim_var
:: Trims leading and trailing spaces from the named variable.
:trim_var
set "_TV_VAL=!%~1!"
goto :trim_l
:: ## trim_l
:: Strips leading whitespace characters iteratively.
:trim_l
if "!_TV_VAL:~0,1!"==" " (
    set "_TV_VAL=!_TV_VAL:~1!"
    goto :trim_l
)
:: wincheck disable=CMD3005
:: ## trim_r
:: Strips trailing whitespace characters iteratively.
:trim_r
if "!_TV_VAL:~-1!"==" " (
    set "_TV_VAL=!_TV_VAL:~0,-1!"
    goto :trim_r
)
set "%~1=!_TV_VAL!"
exit /b 0

:: ## ensure_db
:: Ensures the local rapps-db directory is initialized.
:ensure_db
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "_DB_DIR=%LIBSCRIPT_RAPPS_DB_DIR%"
if "!_DB_DIR!"=="" set "_DB_DIR=%LIBSCRIPT_HOME%\rapps\0.4.16\db"
if not exist "!_DB_DIR!" (
    set "ACTION=install"
    call "!SCRIPT_DIR!\setup_generic.cmd" >nul
)
exit /b 0

:: ## prefetch_pkg
:: Prefetches a RAPPS package installer and writes offline metadata and silent flags.
:prefetch_pkg
set "_PF_ID="
set "_PF_ARCH=%LIBSCRIPT_RAPPS_ARCH%"
if "!_PF_ARCH!"=="" set "_PF_ARCH=i686"
set "_PF_DEST=%LIBSCRIPT_RAPPS_CACHE_DIR%"
if "!_PF_DEST!"=="" set "_PF_DEST=!LIBSCRIPT_ROOT_DIR!\cache\rapps"
set "_PF_INI="
goto :pf_args
:: ## pf_args
:: Parses CLI flags for the prefetch subcommand.
:pf_args
if "%~1"=="" goto :pf_args_done
set "_ARG=%~1"
if "!_ARG:~0,7!"=="--arch=" (
    set "_PF_ARCH=!_ARG:~7!"
) else if "!_ARG:~0,7!"=="--dest=" (
    set "_PF_DEST=!_ARG:~7!"
) else if "!_ARG:~0,6!"=="--ini=" (
    set "_PF_INI=!_ARG:~6!"
) else if "!_PF_ID!"=="" (
    set "_PF_ID=!_ARG!"
)
shift
goto :pf_args
:: ## pf_args_done
:: Validates parsed prefetch arguments and stages package metadata.
:pf_args_done
if "!_PF_ID!"=="" (
    echo [ERROR] Package ID required for rapps prefetch. >&2
    exit /b 1
)
if not exist "!_PF_DEST!" mkdir "!_PF_DEST!"
set "_PF_STAMP=!_PF_DEST!\!_PF_ID!.!_PF_ARCH!.stamp"
if exist "!_PF_STAMP!" (
    echo [SKIP] RAPPS package !_PF_ID! ^(!_PF_ARCH!^) already prefetched.
    exit /b 0
)
call :ensure_db
if "!_PF_INI!"=="" set "_PF_INI=!_DB_DIR!\!_PF_ID!.txt"
if not exist "!_PF_INI!" (
    echo [ERROR] RAPPS definition not found: !_PF_INI! >&2
    exit /b 1
)
call :parse_ini "!_PF_INI!" "!_PF_ARCH!" > "!_PF_DEST!\!_PF_ID!.meta"
echo.!_R_SILENT!> "!_PF_DEST!\!_PF_ID!.flags"
if not "%LIBSCRIPT_OFFLINE%"=="1" if not "!_R_URL!"=="" (
    set "_SHA_CHK=!_R_SHA!"
    if "!_SHA_CHK!"=="" set "_SHA_CHK=SKIP"
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!_R_URL!" "!_PF_DEST!\!_PF_ID!.exe" "!_SHA_CHK!"
)
echo prefetched> "!_PF_STAMP!"
copy /y "!_PF_STAMP!" "!_PF_DEST!\!_PF_ID!.stamp" >nul 2>&1
echo [OK] Prefetched RAPPS metadata for !_PF_ID! ^(!_PF_ARCH!^) -^> !_PF_DEST!
exit /b 0

:: ## search_db
:: Searches local rapps-db entries matching an optional query substring.
:search_db
set "_SQ=%~1"
call :ensure_db
for %%F in ("!_DB_DIR!\*.txt") do (
    if "!_SQ!"=="" (
        echo.%%~nF
    ) else (
        findstr /I /C:"!_SQ!" "%%~fF" >nul 2>&1 && echo.%%~nF
    )
)
exit /b 0
