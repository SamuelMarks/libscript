@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup and synthesis router for FreeRTOS (_lib\kernel\freertos\).
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and assemble capabilities.
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%ACTION%"=="" set "ACTION=install"
if "%FREERTOS_VERSION%"=="" set "FREERTOS_VERSION=11.1.0"
set "EXACT_VERSION=%FREERTOS_VERSION%"
if /i "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=10.5.1"
if /i "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=11.1.0"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="bootstrap" goto :action_install
if /i "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="compile" goto :action_assemble
if /i "%ACTION%"=="assemble" goto :action_assemble
goto :action_other

:: ## action_ls
:: Lists locally installed FreeRTOS versions.
:action_ls
if exist "%LIBSCRIPT_HOME%\freertos" dir /b "%LIBSCRIPT_HOME%\freertos"
exit /b 0

:: ## action_ls_remote
:: Displays available FreeRTOS LTS and mainline versions.
:action_ls_remote
echo 10.5.1 ^(LTS^)
echo 11.1.0
exit /b 0

:: ## action_download
:: Downloads FreeRTOS-Kernel source archive to local cache.
:action_download
set "CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache\freertos"
if not exist "!CACHE_DIR!" mkdir "!CACHE_DIR!"
set "URL=https://github.com/FreeRTOS/FreeRTOS-Kernel/archive/refs/tags/V!EXACT_VERSION!.zip"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!CACHE_DIR!\FreeRTOS-Kernel-V!EXACT_VERSION!.zip"
exit /b !errorlevel!

:: ## action_install
:: Installs FreeRTOS environment wrapper or triggers stage3 firmware build.
:action_install
if "%LIBSCRIPT_IMAGE_BUILD%"=="1" if "%LIBSCRIPT_STAGE%"=="stage3" goto :action_assemble
set "TARGET_DIR=%LIBSCRIPT_HOME%\freertos\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\freertos-env-check.cmd" if not "%FORCE_REINSTALL%"=="1" (
    echo [INFO] freertos !EXACT_VERSION! is already installed at !TARGET_DIR!.
    exit /b 0
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
> "!TARGET_DIR!\bin\freertos-env-check.cmd" echo @echo FreeRTOS Kernel V!EXACT_VERSION! ^(FREERTOS_KERNEL_PATH=!TARGET_DIR!^)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "freertos" "%FREERTOS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "freertos" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_use
:: Switches active FreeRTOS version alias.
:action_use
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "freertos" "%FREERTOS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "freertos" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_assemble
:: Invokes build_firmware.cmd to synthesize target FreeRTOS firmware or Win32 simulator.
:action_assemble
set "STACK="
call "!SCRIPT_DIR!\build_firmware.cmd"
exit /b !errorlevel!

:: ## action_other
:: Delegates generic service/uninstall actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "freertos" "%ACTION%" "%FREERTOS_VERSION%" "libscript_native" "" "" "" "%LIBSCRIPT_HOME%\freertos\!EXACT_VERSION!\bin\freertos-env-check.cmd" "%LIBSCRIPT_HOME%\freertos\!EXACT_VERSION!"
exit /b !errorlevel!
