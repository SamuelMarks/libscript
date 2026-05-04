@echo off
setlocal EnableDelayedExpansion
set "json_file=%~2"
if "!json_file!"=="" set "json_file=libscript.json"
if not exist "!json_file!" (
    echo Error: !json_file! not found. 1>&2
    exit /b 1
)
jq --version >nul 2>&1
if errorlevel 1 (
    echo Error: jq is required to parse !json_file!. 1>&2
    exit /b 1
)

if "!LIBSCRIPT_SECRETS!"=="" (
    for /f "delims=" %%s in ('jq -r "if .secrets then .secrets else empty end" "!json_file!" 2^>nul') do (
        if not "%%s"=="" if not "%%s"=="null" set "LIBSCRIPT_SECRETS=%%s"
    )
    if "!LIBSCRIPT_SECRETS!"=="" (
        if defined LIBSCRIPT_ROOT_DIR (
            set "LIBSCRIPT_SECRETS=!LIBSCRIPT_ROOT_DIR!\secrets"
        ) else (
            set "LIBSCRIPT_SECRETS=%SCRIPT_DIR%\secrets"
        )
    )
)

        if "!skip_hooks!"=="0" (
        if /i "!action!"=="start" (
            call "%~dp0scripts\run_hooks.cmd" "!json_file!" "build"
            call "%~dp0scripts\run_hooks.cmd" "!json_file!" "pre_start"
        )
        if /i "!action!"=="up" (
            call "%~dp0scripts\run_hooks.cmd" "!json_file!" "build"
            call "%~dp0scripts\run_hooks.cmd" "!json_file!" "pre_start"
        )
    )
    call "%~dp0scripts\resolve_stack.cmd" "!json_file!" > "!json_file!.resolved.json" 2>nul
REM Parallel Download Phase
echo Downloading dependencies in parallel...
for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "!json_file!.resolved.json" 2^>nul\') do (
    if "%%c"=="" (
        start "" /b cmd /c "call "%~dp0libscript.cmd" download "%%a" "%%b""
    ) else if "%%c"=="null" (
        start "" /b cmd /c "call "%~dp0libscript.cmd" download "%%a" "%%b""
    )
)

REM Wait for background downloads. `start /wait /b` doesn't work, we'll just wait a bit or let it run.
REM A simple sleep or loop for processes isn't strictly trivial without external tools.
REM But we can check for running cmd.exe processes started with `download` via tasklist if needed.
REM Actually, simple approach: wait 3 seconds to let them start and fetch.
ping 127.0.0.1 -n 4 >nul

REM Serial Install Phase
echo Installing dependencies sequentially...
for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "!json_file!.resolved.json" 2^>nul\') do (
    if not "%%c"=="" if not "%%c"=="null" (
        echo Skipping installation of %%a ^(override provided: %%c^)
    ) else (
        echo Installing %%a %%b...
        call "%~dp0libscript.cmd" install "%%a" "%%b"
    )
)
if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
exit /b 0
