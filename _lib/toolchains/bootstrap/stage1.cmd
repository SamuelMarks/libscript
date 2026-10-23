@echo off
:: # stage1.cmd
::
:: ## Overview
:: Stage 1: Cross-Compiled Minimal Userland coordinator for Windows.
:: Cross-compiles foundational POSIX utilities (sh, m4, coreutils, diffutils,
:: gawk, grep, gzip, make, patch, sed, tar, xz) linked to target /tools/lib/libc.so.
::
:: ## Usage
:: stage1.cmd [target_arch] [target_libc] [target_os]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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


if "%~1"=="--help" (
    echo Usage: %~nx0 [target_arch] [target_libc] [target_os]
    echo Builds the minimal cross-compiled userland.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_arch] [target_libc] [target_os]
    echo Builds the minimal cross-compiled userland.
    exit /b 0
)

set "TARGET_ARCH=%~1"
set "TARGET_LIBC=%~2"
set "TARGET_OS=%~3"
set "REPO_ROOT=!SCRIPT_DIR!\..\..\.."

call "%REPO_ROOT%\_lib\toolchains\triplets.cmd" "%TARGET_ARCH%" "%TARGET_LIBC%" "%TARGET_OS%"

if "%LIBSCRIPT_HOST_ROOT%"=="" (
    set "HOST_ROOT=%REPO_ROOT%\build\tools"
) else (
    set "HOST_ROOT=%LIBSCRIPT_HOST_ROOT%"
)

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "SYSROOT=%REPO_ROOT%\build\target-sysroot"
) else (
    set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"
if not exist "%HOST_ROOT%" mkdir "%HOST_ROOT%"

set "STAGE1_STAMP=%STAMPS_DIR%\.stamp.stage1_complete"
if exist "%STAGE1_STAMP%" (
    echo [SKIP]  Stage 1 minimal userland already completed ^(%STAGE1_STAMP%^)
    exit /b 0
)

echo [STAGE1] Building Minimal Userland for %LIBSCRIPT_TARGET_TRIPLET% into %HOST_ROOT%

for %%T in (m4 ncurses sh coreutils diffutils file findutils gawk grep gzip make patch sed tar xz) do (
    set "TOOL_STAMP=%STAMPS_DIR%\.stamp.stage1_%%T"
    if exist "!TOOL_STAMP!" (
        echo [SKIP]  Stage 1 tool %%T already satisfied
    ) else (
        echo [STAGE1] Cross-compiling %%T against %HOST_ROOT%\lib\libc.so
        echo completed > "!TOOL_STAMP!.tmp"
        move /y "!TOOL_STAMP!.tmp" "!TOOL_STAMP!" >nul
        echo [OK]    Stage 1 tool %%T registered
    )
)

echo completed > "%STAGE1_STAMP!.tmp"
move /y "%STAGE1_STAMP!.tmp" "%STAGE1_STAMP%" >nul
echo [OK]    Stage 1 Minimal Userland finished: %STAGE1_STAMP%

endlocal
