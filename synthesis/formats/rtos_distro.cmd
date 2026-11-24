@echo off
:: # rtos_distro.cmd
::
:: ## Overview
:: Unified CLI entrypoint to synthesize and package a Zephyr or FreeRTOS profile on Windows.
::
:: ## Usage
:: synthesis\formats\rtos_distro.cmd [--format <firmware-bin|firmware-elf|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc|direct-kernel>] --profile <path> [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]

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

set "FORMAT=%LIBSCRIPT_RTOS_DEFAULT_FORMAT%"
if "!FORMAT!"=="" set "FORMAT=firmware-bin"
set "PROFILE=%LIBSCRIPT_RTOS_DEFAULT_PROFILE%"
if "!PROFILE!"=="" set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\rtos\zephyr-qemu-x86_64-minimal.json"
set "OUTPUT="
set "BOARD="
set "KEY_TYPE=%MCUBOOT_KEY_TYPE%"
if "!KEY_TYPE!"=="" set "KEY_TYPE=rsa-2048"
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
set "STRICT_BUILD=0"
if "%LIBSCRIPT_STRICT_IMAGE_BUILD%"=="1" set "STRICT_BUILD=1"
goto :parse_args

:: ## parse_args
:: Parses CLI options for rtos_distro.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_ARG=%~1"
if /I "!_ARG!"=="--help" goto :show_help
if /I "!_ARG!"=="-h" goto :show_help
if /I "!_ARG!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,9!"=="--format=" ( set "FORMAT=!_ARG:~9!" & shift & goto :parse_args )
if /I "!_ARG!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,10!"=="--profile=" ( set "PROFILE=!_ARG:~10!" & shift & goto :parse_args )
if /I "!_ARG!"=="--board" ( set "BOARD=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,8!"=="--board=" ( set "BOARD=!_ARG:~8!" & shift & goto :parse_args )
if /I "!_ARG!"=="--key-type" ( set "KEY_TYPE=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,11!"=="--key-type=" ( set "KEY_TYPE=!_ARG:~11!" & shift & goto :parse_args )
if /I "!_ARG!"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="--out" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="-o" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,9!"=="--output=" ( set "OUTPUT=!_ARG:~9!" & shift & goto :parse_args )
if /I "!_ARG:~0,6!"=="--out=" ( set "OUTPUT=!_ARG:~6!" & shift & goto :parse_args )
if /I "!_ARG!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /I "!_ARG!"=="--strict" ( set "STRICT_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_args )
if /I "!_ARG!"=="--allow-stub" ( set "ALLOW_STUB=1" & set "STRICT_BUILD=0" & shift & goto :parse_args )
if /I "!_ARG!"=="--offline" ( set "LIBSCRIPT_OFFLINE=1" & shift & goto :parse_args )
echo [ERROR] Unknown argument: !_ARG! >&2
exit /b 1

:: ## args_done
:: Resolves RTOS profile path, checks idempotency stamp, and dispatches synthesis.
:args_done
set "_P_NORM=!PROFILE:/=\!"
if not exist "!_P_NORM!" (
    if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_P_NORM!.json" set "_P_NORM=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_P_NORM!.json"
)
if not exist "!_P_NORM!" (
    if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\rtos\!_P_NORM!.json" set "_P_NORM=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\rtos\!_P_NORM!.json"
)
set "PROFILE=!_P_NORM!"
if not exist "!PROFILE!" (
    echo [ERROR] RTOS profile not found: !PROFILE! >&2
    exit /b 1
)

for %%F in ("!PROFILE!") do set "PNAME=%%~nF"
set "KERNEL_ARG=rtos-zephyr"
set "DEF_BOARD=qemu_x86_64"
findstr /I /C:"freertos" "!PROFILE!" >nul 2>&1
if not errorlevel 1 (
    set "KERNEL_ARG=rtos-freertos"
    set "DEF_BOARD=win32_sim"
)
findstr /I /C:"ed25519" "!PROFILE!" >nul 2>&1
if not errorlevel 1 if /I "!KEY_TYPE!"=="rsa-2048" set "KEY_TYPE=ed25519"
findstr /I /C:"static_only" "!PROFILE!" >nul 2>&1
if not errorlevel 1 set "FREERTOS_HEAP_IMPL=static_only"
set "MCUBOOT_KEY_TYPE=!KEY_TYPE!"
if "!BOARD!"=="" set "BOARD=!DEF_BOARD!"

if /I "!FORMAT!"=="bin" set "FORMAT=firmware-bin"
if /I "!FORMAT!"=="elf" set "FORMAT=firmware-elf"
if /I "!FORMAT!"=="hex" set "FORMAT=firmware-hex"
if /I "!FORMAT!"=="uf2" set "FORMAT=firmware-uf2"

if /I "!FORMAT!"=="firmware-bin" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!PNAME!-!BOARD!.bin"
    goto :dispatch_rtos
)
if /I "!FORMAT!"=="firmware-elf" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!PNAME!-!BOARD!.elf"
    goto :dispatch_rtos
)
if /I "!FORMAT!"=="firmware-hex" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!PNAME!-!BOARD!.hex"
    goto :dispatch_rtos
)
if /I "!FORMAT!"=="firmware-uf2" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!PNAME!-!BOARD!.uf2"
    goto :dispatch_rtos
)
if /I "!FORMAT!"=="mcuboot-signed" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!PNAME!-!BOARD!.signed.bin"
    goto :dispatch_rtos
)
if /I "!FORMAT!"=="renode-resc" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!PNAME!-!BOARD!.resc"
    goto :dispatch_rtos
)
if /I "!FORMAT!"=="direct-kernel" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\direct-kernel\!PNAME!-!BOARD!"
    goto :dispatch_rtos
)
echo [ERROR] Unsupported RTOS packaging format: !FORMAT! >&2
exit /b 1

:: ## dispatch_rtos
:: Executes dry-run validation or full RTOS firmware synthesis with stamp idempotency.
:dispatch_rtos
if "!DRY_RUN!"=="1" (
    echo [DISTRO]   Validating RTOS ^(!KERNEL_ARG!, board=!BOARD!^) synthesis plan from !PROFILE! ^(format=!FORMAT!^)...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=!KERNEL_ARG!" "--profile=!PROFILE!" "--board=!BOARD!" "--format=!FORMAT!" "--out=!OUTPUT!" --dry-run
    exit /b !ERRORLEVEL!
)

set "STAMP_FILE=!OUTPUT!.distro.stamp"
if exist "!STAMP_FILE!" if exist "!OUTPUT!" (
    findstr /I /C:"format=!FORMAT!" "!STAMP_FILE!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP]     RTOS firmware artifact already synthesized: !OUTPUT!
        exit /b 0
    )
)

for %%D in ("!OUTPUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
echo [DISTRO]   Synthesizing RTOS ^(!KERNEL_ARG!, board=!BOARD!^) artifact from !PROFILE!...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=!KERNEL_ARG!" "--profile=!PROFILE!" "--board=!BOARD!" "--format=!FORMAT!" "--out=!OUTPUT!"
if errorlevel 1 exit /b !ERRORLEVEL!

(
    echo format=!FORMAT!
    echo kernel=!KERNEL_ARG!
    echo board=!BOARD!
    echo profile=!PROFILE!
) > "!STAMP_FILE!"

echo [OK]       RTOS firmware packaged as !FORMAT!: !OUTPUT!
exit /b 0

:: ## show_help
:: Displays usage instructions for rtos_distro.cmd.
:show_help
echo Usage: %~nx0 [--format ^<firmware-bin^|firmware-elf^|firmware-hex^|firmware-uf2^|mcuboot-signed^|renode-resc^|direct-kernel^>] [--profile ^<path^|preset^>] [--board ^<board^>] [--output ^<path^>] [--dry-run] [--allow-stub] [--strict] [--offline]
exit /b 0
