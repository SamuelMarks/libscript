@echo off
:: # cli.cmd
::
:: ## Overview
:: CDN component CLI for website distribution operations on Windows.
::
:: ## Usage
:: libscript cdn [create|delete|list|invalidate] [--cloud aws|gcp|azure] [--bucket name] [--domain custom.tld] [--cert-id id]

set "CMD=%~1"
if not "%CMD%"=="" shift

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~1"=="" goto validate_args
if "%~1"=="--cloud" (
    set "LIBSCRIPT_CLOUD=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--bucket" (
    set "LIBSCRIPT_BUCKET=%~2"
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
if "%~1"=="--cert-id" (
    set "LIBSCRIPT_CERT_ID=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--dist-id" (
    set "LIBSCRIPT_DIST_ID=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--paths" (
    set "LIBSCRIPT_PATHS=%~2"
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
echo %~1 | findstr /b /c:"--bucket=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_BUCKET=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--domain=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DOMAIN=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--cert-id=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_CERT_ID=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--dist-id=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DIST_ID=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--paths=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_PATHS=%%A"
    shift
    goto parse_args
)
echo Error: Unknown argument '%~1' >&2
exit /b 1

:: ## validate_args
:: Executes validate_args functionality.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for cdn (create^|delete^|list^|invalidate^). >&2
    exit /b 1
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute
if "%CMD%"=="invalidate" goto execute

echo Error: Unknown cdn command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes execute functionality.
:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud (or LIBSCRIPT_CLOUD) is required. >&2
    exit /b 1
)

if "%CMD%"=="list" (
    call "%~dp0api.cmd" :libscript_cdn_list "%LIBSCRIPT_CLOUD%"
    exit /b %errorlevel%
)

if "%CMD%"=="create" (
    if "%LIBSCRIPT_BUCKET%"=="" (
        echo Error: --bucket (or LIBSCRIPT_BUCKET) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_cdn_create "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_BUCKET%" "%LIBSCRIPT_DOMAIN%" "%LIBSCRIPT_CERT_ID%"
    exit /b %errorlevel%
)

if "%CMD%"=="delete" (
    if "%LIBSCRIPT_DIST_ID%"=="" (
        echo Error: --dist-id (or LIBSCRIPT_DIST_ID) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_cdn_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DIST_ID%"
    exit /b %errorlevel%
)

if "%CMD%"=="invalidate" (
    if "%LIBSCRIPT_DIST_ID%"=="" (
        echo Error: --dist-id (or LIBSCRIPT_DIST_ID) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_cdn_invalidate "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DIST_ID%" "%LIBSCRIPT_PATHS%"
    exit /b %errorlevel%
)

exit /b 0
