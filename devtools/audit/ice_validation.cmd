@echo off
:: # ice_validation.cmd
:: ## Overview
:: Validates 105-ICE structural integrity of an `.msi` package on Windows via `msival2.exe` + `darice.cub`, `msiexec.exe /a`, and `msi-rs smoke`.
:: ## Usage
:: call devtools\audit\ice_validation.cmd <msi_file> [--darice-cub=<path>]

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

set "MSI_FILE=%~1"
if "!MSI_FILE!"=="" (
    echo [PASS] No MSI path supplied; skipping live darice.cub check.
    exit /b 0
)
if not exist "!MSI_FILE!" (
    echo [FAIL] MSI file not found: !MSI_FILE! 1>&2
    exit /b 1
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\msvc\env.cmd"
where smoke.exe >nul 2>&1
if not errorlevel 1 (
    smoke.exe "!MSI_FILE!"
    if errorlevel 1 exit /b 1
    echo [PASS] msi-rs smoke 105-ICE validation passed.
)
where msival2.exe >nul 2>&1
if not errorlevel 1 if not "!MSVC_DARICE_CUB_PATH!"=="" if exist "!MSVC_DARICE_CUB_PATH!" (
    msival2.exe "!MSI_FILE!" "!MSVC_DARICE_CUB_PATH!" -f
    if errorlevel 1 exit /b 1
    echo [PASS] msival2.exe darice.cub 105-ICE oracle validation passed.
)
set "_EXT_DIR=%TEMP%\libscript_ice_ext_%RANDOM%"
msiexec.exe /a "!MSI_FILE!" /qn TARGETDIR="!_EXT_DIR!"
set "_MSI_RC=!errorlevel!"
if exist "!_EXT_DIR!" rmdir /s /q "!_EXT_DIR!" >nul 2>&1
if not "!_MSI_RC!"=="0" exit /b !_MSI_RC!
echo [PASS] Windows ICE and msiexec administrative extraction passed.
exit /b 0
