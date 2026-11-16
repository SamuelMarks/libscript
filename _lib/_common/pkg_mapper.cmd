@echo off
:: # pkg_mapper.cmd
::
:: ## Overview
:: Cross-platform package name translation module on Windows backed by _lib\_common\pkg_map.tsv.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mapper.cmd" :map_package "<generic_name>"

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

if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'. 1>&2
    exit /b 1
)

call %1 "%~2"
set "_PM_RC=!ERRORLEVEL!"
endlocal & (
    set "MAPPED_PKG=%MAPPED_PKG%"
    exit /b %_PM_RC%
)

:: ## map_package
:: Translates a generic package identifier into the native Windows package manager ID via pkg_map.tsv.
:map_package
set "PKG=%~1"
set "MAPPED_PKG="
if "%PKG%"=="" exit /b 1
if "!PKG_MGR!"=="" (
    if "%IS_REACTOS%"=="1" (
        set "PKG_MGR=rapps"
    ) else (
        set "PKG_MGR=winget"
    )
)

set "_TSV=!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_map.tsv"
if not exist "!_TSV!" (
    set "MAPPED_PKG=!PKG!"
    exit /b 0
)

set "_EXACT_PM="
set "_FALLBACK="
for /f "usebackq tokens=1,2,3 delims=	" %%A in ("!_TSV!") do (
    if "%%A"=="!PKG!" (
        if "%%B"=="!PKG_MGR!" set "_EXACT_PM=%%C"
        if "%%B"=="*" set "_FALLBACK=%%C"
    )
)

set "_RES=!PKG!"
if not "!_FALLBACK!"=="" set "_RES=!_FALLBACK!"
if not "!_EXACT_PM!"=="" set "_RES=!_EXACT_PM!"

if "!_RES!"=="__UNSUPPORTED__" (
    set "MAPPED_PKG="
    exit /b 1
)
if "!_RES!"=="__NONE__" (
    set "MAPPED_PKG="
    exit /b 0
)
set "MAPPED_PKG=!_RES!"
exit /b 0
