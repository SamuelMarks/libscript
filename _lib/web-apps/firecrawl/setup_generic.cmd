@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Orchestrates the cross-platform Windows setup and dependency installation for the Firecrawl crawler stack.
::
:: ## Usage
:: call _lib\web-apps\firecrawl\setup_generic.cmd

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

set "LOG_CMD=!LIBSCRIPT_ROOT_DIR!\_lib\_common\log.cmd"
call "!SCRIPT_DIR!\env.cmd"

if not defined LIBSCRIPT_DATA_DIR set "LIBSCRIPT_DATA_DIR=!LIBSCRIPT_ROOT_DIR!\data\firecrawl"
if not exist "!LIBSCRIPT_DATA_DIR!" mkdir "!LIBSCRIPT_DATA_DIR!"

if defined FIRECRAWL_DEST (
    set "DEST=!FIRECRAWL_DEST!"
) else if exist "!LIBSCRIPT_DATA_DIR!\.firecrawl_dest" (
    set /p DEST=<"!LIBSCRIPT_DATA_DIR!\.firecrawl_dest"
) else (
    set "DEST=!LIBSCRIPT_DATA_DIR!\app"
    >"!LIBSCRIPT_DATA_DIR!\.firecrawl_dest" echo !DEST!
)

where git >nul 2>&1
if errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install git latest
)

where pnpm >nul 2>&1
if errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install pnpm latest
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\pnpm\env.cmd" (
        set "_FC_STACK=!STACK!"
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\pnpm\env.cmd"
        set "STACK=!_FC_STACK!"
    )
)

if not exist "!DEST!\.git" (
    if exist "!DEST!" rmdir /s /q "!DEST!" >nul 2>&1
    git clone --depth 1 https://github.com/mendableai/firecrawl "!DEST!"
    if errorlevel 1 (
        call "!LOG_CMD!" :log_error "Failed to clone Firecrawl repository into !DEST!"
        exit /b 1
    )
) else (
    pushd "!DEST!"
    git pull --ff-only >nul 2>&1
    popd
)

set "HASH=latest"
for /f "delims=" %%H in ('git -C "!DEST!" rev-list HEAD -1 2^>nul') do set "HASH=%%H"
set "HASH_LOC=!DEST!\apps\api\node_modules\!HASH!"
if not exist "!HASH_LOC!" (
    if exist "!DEST!\apps\api" (
        pushd "!DEST!\apps\api"
        where pnpm >nul 2>&1
        if not errorlevel 1 (
            call pnpm install
            if errorlevel 1 call pnpm install --ignore-scripts
        )
        popd
        if not exist "!DEST!\apps\api\node_modules" mkdir "!DEST!\apps\api\node_modules"
        type nul > "!HASH_LOC!"
    )
)

call "!LOG_CMD!" :log_info "Firecrawl workspace configured at !DEST!"
exit /b 0
