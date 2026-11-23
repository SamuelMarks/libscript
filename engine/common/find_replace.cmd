@echo off
:: # LibScript Find and Replace Module (Windows Batch)
:: ## Overview
:: Safely replaces literal strings in files without regex corruption on Windows,
:: preferring native LibScript `gawk`/`awk` before falling back to PowerShell.
:: ## Usage
:: call "!LIBSCRIPT_ROOT_DIR!\engine\common\find_replace.cmd" :find_replace "search" "replace" "file.txt"

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

if not "%~1"=="" goto %~1
exit /b 0

:: ## resolve_awk
:: Locates gawk or awk on PATH or from the isolated LibScript gawk environment.
:resolve_awk
set "_FR_AWK="
where gawk >nul 2>&1
if not errorlevel 1 (
    set "_FR_AWK=gawk"
    exit /b 0
)
where awk >nul 2>&1
if not errorlevel 1 (
    set "_FR_AWK=awk"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\gawk\env.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\gawk\env.cmd" >nul 2>&1
    where gawk >nul 2>&1
    if not errorlevel 1 (
        set "_FR_AWK=gawk"
        exit /b 0
    )
)
exit /b 1

:: ## find_replace
:: Replaces all literal occurrences of a search string with a replacement string in a target file.
:find_replace
set "SEARCH=%~1"
set "REPLACE=%~2"
set "FILE=%~3"

if not exist "%FILE%" (
    echo Error: Cannot read file "%FILE%" >&2
    exit /b 1
)

call :resolve_awk
if defined _FR_AWK (
    set "old=!SEARCH!"
    set "new=!REPLACE!"
    set "_FR_PROG=%TEMP%\ls_fr_!RANDOM!_!RANDOM!.awk"
    (
        echo { rec = rec $0 RS }
        echo END {
        echo     old = ENVIRON["old"]
        echo     new = ENVIRON["new"]
        echo     lgth = length^(old^)
        echo     if ^(lgth ^> 0^) {
        echo         while ^( beg = index^(rec, old^) ^) {
        echo             printf "%%s%%s", substr^(rec, 1, beg-1^), new
        echo             rec = substr^(rec, beg+lgth^)
        echo         }
        echo     }
        echo     printf "%%s", rec
        echo }
    ) > "!_FR_PROG!"
    "!_FR_AWK!" -f "!_FR_PROG!" "%FILE%"
    set "_FR_RC=!ERRORLEVEL!"
    del /f /q "!_FR_PROG!" >nul 2>&1
    exit /b !_FR_RC!
)

where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "$content = [System.IO.File]::ReadAllText($env:FILE); $newContent = $content.Replace($env:SEARCH, $env:REPLACE); [Console]::Out.Write($newContent)"
    exit /b !ERRORLEVEL!
)

echo Error: Neither gawk/awk nor PowerShell available for find_replace >&2
exit /b 1
