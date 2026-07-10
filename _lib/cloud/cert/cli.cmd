@echo off
:: # cli.cmd
::
:: ## Overview
:: Cert component CLI for SSL certificate operations on Windows.
::
:: ## Usage
:: libscript cert [create|delete|list] [--cloud aws|gcp|azure] [--domain name]

set "CMD=%~1"
if not "%CMD%"=="" shift

:parse_args
if "%~1"=="" goto validate_args
if "%~1"=="--cloud" (
    set "LIBSCRIPT_CLOUD=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--domain" (
    set "LIBSCRIPT_DOMAIN=%~2"
    shift
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--cloud=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_CLOUD=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--domain=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DOMAIN=%%A"
    shift
    goto parse_args
)
echo Error: Unknown argument '%~1' >&2
exit /b 1

:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for cert (create^|delete^|list^). >&2
    exit /b 1
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute

echo Error: Unknown cert command '%CMD%' >&2
exit /b 1

:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud (or LIBSCRIPT_CLOUD) is required. >&2
    exit /b 1
)

if "%CMD%"=="list" (
    call "%~dp0api.cmd" :libscript_cert_list "%LIBSCRIPT_CLOUD%"
    exit /b %errorlevel%
)

if "%LIBSCRIPT_DOMAIN%"=="" (
    echo Error: --domain (or LIBSCRIPT_DOMAIN) is required for %CMD%. >&2
    exit /b 1
)

if "%CMD%"=="create" (
    call "%~dp0api.cmd" :libscript_cert_create "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DOMAIN%"
    exit /b %errorlevel%
)
if "%CMD%"=="delete" (
    call "%~dp0api.cmd" :libscript_cert_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DOMAIN%"
    exit /b %errorlevel%
)

exit /b 0
