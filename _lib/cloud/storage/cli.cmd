@echo off
:: # cli.cmd
::
:: ## Overview
:: Storage component CLI for Object Storage (buckets) operations on Windows.
::
:: ## Usage
:: libscript storage [create|delete|list|sync] [--cloud aws|gcp|azure] [--bucket name]

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
if "%~1"=="--bucket" (
    set "LIBSCRIPT_BUCKET=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--local-dir" (
    set "LIBSCRIPT_SYNC_DIR=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--public-web" (
    set "LIBSCRIPT_STORAGE_PUBLIC_WEB=true"
    shift
    goto parse_args
)
:: Handle `--cloud=value` and `--bucket=value` formats
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
echo %~1 | findstr /b /c:"--local-dir=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_SYNC_DIR=%%A"
    shift
    goto parse_args
)
echo Error: Unknown argument '%~1' >&2
exit /b 1

:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for storage (create^|delete^|list^|sync^). >&2
    exit /b 1
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute
if "%CMD%"=="sync" goto execute

echo Error: Unknown storage command '%CMD%' >&2
exit /b 1

:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud (or LIBSCRIPT_CLOUD) is required. >&2
    exit /b 1
)

if "%CMD%"=="list" (
    call "%~dp0api.cmd" :libscript_storage_list "%LIBSCRIPT_CLOUD%"
    exit /b %errorlevel%
)

if "%LIBSCRIPT_BUCKET%"=="" (
    echo Error: --bucket (or LIBSCRIPT_BUCKET) is required for %CMD%. >&2
    exit /b 1
)

if "%CMD%"=="create" (
    call "%~dp0api.cmd" :libscript_storage_create "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_BUCKET%" "%LIBSCRIPT_STORAGE_PUBLIC_WEB%"
    exit /b %errorlevel%
)
if "%CMD%"=="delete" (
    call "%~dp0api.cmd" :libscript_storage_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_BUCKET%"
    exit /b %errorlevel%
)
if "%CMD%"=="sync" (
    if "%LIBSCRIPT_SYNC_DIR%"=="" (
        echo Error: --local-dir (or LIBSCRIPT_SYNC_DIR) is required for sync. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_storage_sync "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_BUCKET%" "%LIBSCRIPT_SYNC_DIR%"
    exit /b %errorlevel%
)

exit /b 0
