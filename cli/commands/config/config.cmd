@echo off
:: # config.cmd
:: ## Overview
:: Declarative OS configuration driver supporting profiles, schema validation, and JSON export on Windows.
:: ## Usage
:: config.cmd os [--profile=<name>] [--export=<out.json>] [--validate=<file.json>]

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

set "SCHEMA_FILE=!LIBSCRIPT_ROOT_DIR!\synthesis/schemas/os-config.schema.json"
set "TARGET_PROFILE="
set "EXPORT_FILE="
set "VALIDATE_FILE="
set "OVERRIDE_KERNEL="
set "OVERRIDE_BOARD="
set "OVERRIDE_LIBC="
set "OVERRIDE_HEAP="
set "OVERRIDE_MCUBOOT=0"
set "_ORIG_ARGS=%*"

if /i "%~1"=="os" shift
goto :parse_cfg_args

:: ## parse_cfg_args
:: Parses CLI flags for the Windows OS configuration driver.
:parse_cfg_args
if "%~1"=="" goto :cfg_args_done
set "_ca=%~1"
if /i "!_ca!"=="--help" goto :show_config_help
if /i "!_ca!"=="-h" goto :show_config_help
if /i "!_ca!"=="/?" goto :show_config_help
if /i "!_ca!"=="-?" goto :show_config_help
if /i "!_ca:~0,10!"=="--profile=" ( set "TARGET_PROFILE=!_ca:~10!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--profile" ( set "TARGET_PROFILE=%~2" & shift & shift & goto :parse_cfg_args )
if /i "!_ca:~0,9!"=="--kernel=" ( set "OVERRIDE_KERNEL=!_ca:~9!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--kernel" ( set "OVERRIDE_KERNEL=%~2" & shift & shift & goto :parse_cfg_args )
if /i "!_ca:~0,8!"=="--board=" ( set "OVERRIDE_BOARD=!_ca:~8!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--board" ( set "OVERRIDE_BOARD=%~2" & shift & shift & goto :parse_cfg_args )
if /i "!_ca:~0,7!"=="--libc=" ( set "OVERRIDE_LIBC=!_ca:~7!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--libc" ( set "OVERRIDE_LIBC=%~2" & shift & shift & goto :parse_cfg_args )
if /i "!_ca:~0,7!"=="--heap=" ( set "OVERRIDE_HEAP=!_ca:~7!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--heap" ( set "OVERRIDE_HEAP=%~2" & shift & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--mcuboot" ( set "OVERRIDE_MCUBOOT=1" & shift & goto :parse_cfg_args )
if /i "!_ca:~0,9!"=="--export=" ( set "EXPORT_FILE=!_ca:~9!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--export" ( set "EXPORT_FILE=%~2" & shift & shift & goto :parse_cfg_args )
if /i "!_ca:~0,11!"=="--validate=" ( set "VALIDATE_FILE=!_ca:~11!" & shift & goto :parse_cfg_args )
if /i "!_ca!"=="--validate" ( set "VALIDATE_FILE=%~2" & shift & shift & goto :parse_cfg_args )
shift
goto :parse_cfg_args

:: ## cfg_args_done
:: Ensures jq availability and dispatches validation, profile selection, override application, and export.
:cfg_args_done
call :ensure_config_jq
if errorlevel 1 (
    where powershell >nul 2>&1
    if not errorlevel 1 (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\config.ps1" !_ORIG_ARGS!
        exit /b !errorlevel!
    )
    echo [ERROR] jq.exe ^(or PowerShell fallback^) is required to execute config on Windows. 1>&2
    exit /b 1
)

if not "!VALIDATE_FILE!"=="" goto :validate_mode

if "!TARGET_PROFILE!"=="" call :select_profile_menu
set "PROFILE_PATH=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!TARGET_PROFILE!.json"
if not exist "!PROFILE_PATH!" set "PROFILE_PATH=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!TARGET_PROFILE!"
if not exist "!PROFILE_PATH!" (
    for %%S in (linux freebsd illumos reactos rtos hypervisor unikernel containers cloud lfs) do (
        if not exist "!PROFILE_PATH!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\%%S\!TARGET_PROFILE!.json" set "PROFILE_PATH=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\%%S\!TARGET_PROFILE!.json"
        if not exist "!PROFILE_PATH!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\%%S\!TARGET_PROFILE!" set "PROFILE_PATH=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\%%S\!TARGET_PROFILE!"
    )
)
if not exist "!PROFILE_PATH!" (
    echo [ERROR] Profile not found: !TARGET_PROFILE! 1>&2
    exit /b 1
)

set "_TMP_CFG=%TEMP%\libscript_cfg_!RANDOM!.json"
set "_HAS_OVR=0"
if not "!OVERRIDE_KERNEL!"=="" set "_HAS_OVR=1"
if not "!OVERRIDE_BOARD!"=="" set "_HAS_OVR=1"
if not "!OVERRIDE_LIBC!"=="" set "_HAS_OVR=1"
if not "!OVERRIDE_HEAP!"=="" set "_HAS_OVR=1"
if "!OVERRIDE_MCUBOOT!"=="1" set "_HAS_OVR=1"

if "!_HAS_OVR!"=="1" (
    jq --arg krn "!OVERRIDE_KERNEL!" --arg brd "!OVERRIDE_BOARD!" --arg lbc "!OVERRIDE_LIBC!" --arg hp "!OVERRIDE_HEAP!" --arg mcb "!OVERRIDE_MCUBOOT!" "(if $krn != \"\" then .target.os_family = $krn else . end) | (if $lbc != \"\" then .target.libc = $lbc else . end) | (if $brd != \"\" then .rtos = ((.rtos // {}) | .board = $brd) else . end) | (if $hp != \"\" then .rtos = ((.rtos // {}) | .heap_implementation = $hp) else . end) | (if $mcb == \"1\" then .rtos = ((.rtos // {}) | .mcuboot = ((.mcuboot // {}) | .enabled = true)) else . end)" "!PROFILE_PATH!" > "!_TMP_CFG!"
    if errorlevel 1 (
        del /f /q "!_TMP_CFG!" 2>nul
        exit /b 1
    )
) else (
    copy /y "!PROFILE_PATH!" "!_TMP_CFG!" >nul
)

if not "!EXPORT_FILE!"=="" (
    for %%D in ("!EXPORT_FILE!") do (
        set "_EXP_DIR=%%~dpD"
        if not "!_EXP_DIR!"=="" (
            if not exist "!_EXP_DIR!" mkdir "!_EXP_DIR!"
        )
    )
    copy /y "!_TMP_CFG!" "!EXPORT_FILE!" >nul
    del /f /q "!_TMP_CFG!" 2>nul
    echo [INFO] Exported configuration ^(!TARGET_PROFILE!^) to: !EXPORT_FILE!
    exit /b 0
)

type "!_TMP_CFG!"
del /f /q "!_TMP_CFG!" 2>nul
exit /b 0

:: ## ensure_config_jq
:: Resolves jq.exe from PATH, _lib\utilities\jq\env.cmd, or pkg_mgr.cmd :depends.
:ensure_config_jq
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :depends jq >nul 2>&1
)
where jq >nul 2>&1
exit /b !errorlevel!

:: ## validate_mode
:: Validates a JSON configuration or execution plan against its OS-specific JSON schema using jq.
:validate_mode
if not exist "!VALIDATE_FILE!" (
    echo [ERROR] File to validate not found: !VALIDATE_FILE! 1>&2
    exit /b 1
)
jq empty "!VALIDATE_FILE!" >nul 2>&1
if errorlevel 1 (
    echo [VALIDATION ERROR] !VALIDATE_FILE! is not valid JSON. 1>&2
    exit /b 1
)
set "ACTIVE_SCHEMA=!SCHEMA_FILE!"
jq -e ".plan_version != null and (.target.os == \"zephyr\" or .target.os == \"freertos\")" "!VALIDATE_FILE!" >nul 2>&1
if not errorlevel 1 set "ACTIVE_SCHEMA=!LIBSCRIPT_ROOT_DIR!\synthesis/schemas/execution-plan.rtos.schema.json"
jq -e ".freebsd_version != null or (.target.os_family == \"freebsd\" and .init_system != null and .kernel == null)" "!VALIDATE_FILE!" >nul 2>&1
if not errorlevel 1 set "ACTIVE_SCHEMA=!LIBSCRIPT_ROOT_DIR!\synthesis/schemas/execution-plan.freebsd.schema.json"
jq -e ".illumos_version != null or ((.target.os_family == \"illumos\" or .target.os_family == \"sunos\") and .kernel == null)" "!VALIDATE_FILE!" >nul 2>&1
if not errorlevel 1 set "ACTIVE_SCHEMA=!LIBSCRIPT_ROOT_DIR!\synthesis/schemas/execution-plan.illumos.schema.json"
jq -e ".reactos_version != null or (.target.os_family == \"reactos\" and .kernel == null)" "!VALIDATE_FILE!" >nul 2>&1
if not errorlevel 1 set "ACTIVE_SCHEMA=!LIBSCRIPT_ROOT_DIR!\synthesis/schemas/execution-plan.reactos.schema.json"

set "_MISSING_FIELDS="
for /f "usebackq delims=" %%M in (`jq -r --slurpfile schema "!ACTIVE_SCHEMA!" "$schema[0].required - keys | .[]" "!VALIDATE_FILE!" 2^>nul`) do (
    if "!_MISSING_FIELDS!"=="" (
        set "_MISSING_FIELDS=%%M"
    ) else (
        set "_MISSING_FIELDS=!_MISSING_FIELDS! %%M"
    )
)
if not "!_MISSING_FIELDS!"=="" (
    echo [VALIDATION ERROR] !VALIDATE_FILE! is missing required fields: !_MISSING_FIELDS! 1>&2
    exit /b 1
)
echo [INFO] Schema validation successful: !VALIDATE_FILE! conforms to schema
exit /b 0

:: ## select_profile_menu
:: Displays an interactive Windows console TUI menu matching the 17 OS profiles in config.sh.
:select_profile_menu
echo.
echo +------------------------------------------------------------+
echo ^|          LibScript OS Synthesis - Select Profile           ^|
echo +------------------------------------------------------------+
echo   1^) linux-minimal-headless-musl
echo   2^) linux-standard-server-glibc
echo   3^) freebsd-server-standard
echo   4^) firecracker-microvm-appliance
echo   5^) unikraft-nginx-redis
echo   6^) osv-cloud-runtime
echo   7^) linux-desktop-sway-wayland
echo   8^) linux-desktop-hyprland
echo   9^) linux-desktop-kde-plasma
echo  10^) linux-desktop-xfce-x11
echo  11^) freebsd-desktop-xfce
echo  12^) zephyr-qemu-x86_64-minimal
echo  13^) zephyr-cortex-m3-mcuboot-signed
echo  14^) freertos-cortex-m3-mps2-minimal
echo  15^) freertos-riscv64-static-safety
echo  16^) reactos-desktop-classic-i686
echo  17^) reactos-nightly-x86_64
echo.
set "_CFG_SEL=2"
set /p "_CFG_SEL=Select profile [1-17, default 2]: "
set "TARGET_PROFILE=linux-standard-server-glibc"
if "!_CFG_SEL!"=="1" set "TARGET_PROFILE=linux-minimal-headless-musl"
if "!_CFG_SEL!"=="2" set "TARGET_PROFILE=linux-standard-server-glibc"
if "!_CFG_SEL!"=="3" set "TARGET_PROFILE=freebsd-server-standard"
if "!_CFG_SEL!"=="4" set "TARGET_PROFILE=firecracker-microvm-appliance"
if "!_CFG_SEL!"=="5" set "TARGET_PROFILE=unikraft-nginx-redis"
if "!_CFG_SEL!"=="6" set "TARGET_PROFILE=osv-cloud-runtime"
if "!_CFG_SEL!"=="7" set "TARGET_PROFILE=linux-desktop-sway-wayland"
if "!_CFG_SEL!"=="8" set "TARGET_PROFILE=linux-desktop-hyprland"
if "!_CFG_SEL!"=="9" set "TARGET_PROFILE=linux-desktop-kde-plasma"
if "!_CFG_SEL!"=="10" set "TARGET_PROFILE=linux-desktop-xfce-x11"
if "!_CFG_SEL!"=="11" set "TARGET_PROFILE=freebsd-desktop-xfce"
if "!_CFG_SEL!"=="12" set "TARGET_PROFILE=zephyr-qemu-x86_64-minimal"
if "!_CFG_SEL!"=="13" set "TARGET_PROFILE=zephyr-cortex-m3-mcuboot-signed"
if "!_CFG_SEL!"=="14" set "TARGET_PROFILE=freertos-cortex-m3-mps2-minimal"
if "!_CFG_SEL!"=="15" set "TARGET_PROFILE=freertos-riscv64-static-safety"
if "!_CFG_SEL!"=="16" set "TARGET_PROFILE=reactos-desktop-classic-i686"
if "!_CFG_SEL!"=="17" set "TARGET_PROFILE=reactos-nightly-x86_64"
exit /b 0

:: ## show_config_help
:: Displays CLI usage instructions for config.cmd.
:show_config_help
echo Usage: libscript config os [--profile=^<name^>] [--kernel=^<rtos-zephyr^|rtos-freertos^|...^>] [--board=^<board^>] [--libc=^<picolibc^|newlib^>] [--heap=^<heap_4^|static_only^>] [--mcuboot] [--export=^<out.json^>] [--validate=^<file.json^>]
exit /b 0
