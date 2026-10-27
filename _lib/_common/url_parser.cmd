@echo off
:: # url_parser.cmd
::
:: ## Overview
:: Provides URL parsing capabilities in Windows Batch (`:libscript_url_parser`,
:: `:parse_url`, `:git_args_from_url`), decomposing a URL into `protocol`, `user`,
:: `pass`, `host`, `port`, and `path`.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\url_parser.cmd" :parse_url "<url>"

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

if "%~1"=="" exit /b 0
if /i "%~1"==":parse_url" (
    call :libscript_url_parser "%~2"
    goto :export_out
)
if /i "%~1"==":libscript_url_parser" (
    call :libscript_url_parser "%~2"
    goto :export_out
)
if /i "%~1"==":git_args_from_url" (
    call :git_args_from_url "%~2" "%~3"
    goto :export_out
)
call :libscript_url_parser "%~1"
goto :export_out

:: ## libscript_url_parser
:: Breaks a URL into protocol, user, pass, host, port, and path.
:libscript_url_parser
set "url=%~1"
set "protocol="
set "user="
set "pass="
set "host="
set "port="
set "path="
if "!url!"=="" exit /b 1

set "_rest=!url!"
for /f "tokens=1* delims=:" %%A in ("!_rest!") do (
    set "_maybe_proto=%%A"
    set "_after_colon=%%B"
)
if not "!_after_colon!"=="" (
    if "!_after_colon:~0,2!"=="//" (
        set "protocol=!_maybe_proto!://"
        set "_rest=!_after_colon:~2!"
    )
)
echo url_no_protocol="!_rest!"

for /f "tokens=1* delims=/" %%A in ("!_rest!") do (
    set "_authority=%%A"
    set "path=%%B"
)

echo "!_authority!" | findstr /C:"@" >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=1* delims=@" %%U in ("!_authority!") do (
        set "_userpass=%%U"
        set "_hostport=%%V"
    )
    echo "!_userpass!" | findstr /C:":" >nul 2>&1
    if not errorlevel 1 (
        for /f "tokens=1* delims=:" %%X in ("!_userpass!") do (
            set "user=%%X"
            set "pass=%%Y"
        )
    ) else (
        set "user=!_userpass!"
    )
) else (
    set "_hostport=!_authority!"
)

echo "!_hostport!" | findstr /C:":" >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=1* delims=:" %%H in ("!_hostport!") do (
        set "host=%%H"
        set "port=%%I"
    )
) else (
    set "host=!_hostport!"
)

echo protocol = "!protocol!"
echo host = "!host!"
if not "!port!"=="" echo port = !port!
echo path = "!path!"
if not "!user!"=="" echo user = "!user!"
exit /b 0

:: ## git_args_from_url
:: Converts a repository URL and optional branch into repo and branch variables.
:git_args_from_url
call :libscript_url_parser "%~1"
set "repo=!protocol!!host!"
set "branch=%~2"
echo !repo!
exit /b 0

:: ## export_out
:: Propagates parsed URL variables to the caller scope.
:export_out
endlocal & (
    set "url=%url%"
    set "protocol=%protocol%"
    set "user=%user%"
    set "pass=%pass%"
    set "host=%host%"
    set "port=%port%"
    set "path=%path%"
    set "repo=%repo%"
    set "branch=%branch%"
)
exit /b 0
