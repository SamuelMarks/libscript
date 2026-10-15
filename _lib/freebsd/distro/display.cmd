@echo off
:: # display.cmd
::
:: ## Overview
:: Configures display server subsystems (Wayland, X11, none) and DRM
:: kernel drivers inside FreeBSD target sysroot on Windows.
::
:: ## Usage
:: display.cmd [sysroot_path] [protocol] [driver]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [sysroot_path] [protocol] [driver]
    echo Configures FreeBSD display subsystem.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [protocol] [driver]
    echo Configures FreeBSD display subsystem.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "PROTOCOL=%~2"
if "%PROTOCOL%"=="" set "PROTOCOL=none"
set "DRIVER=%~3"
if "%DRIVER%"=="" set "DRIVER=drm-kmod"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\display_%PROTOCOL%.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD display protocol %PROTOCOL% already configured in %SYSROOT%
    exit /b 0
)

echo [DISPLAY]  Configuring display protocol: %PROTOCOL% (driver: %DRIVER%)...

if "%PROTOCOL%"=="none" (
    echo [DISPLAY]  Headless mode active, zero display packages staged.
    echo %DATE% %TIME%> "%STAMP_FILE%"
    exit /b 0
)

if "%DRIVER%"=="drm-kmod" (
    echo kld_list="${kld_list:-} /boot/modules/virtio_gpu.ko">> "%SYSROOT%\etc\rc.conf"
)

(
    echo [system=10]
    echo add path 'dri/*' mode 0666 group video
    echo add path 'drm/*' mode 0666 group video
    echo add path 'input/*' mode 0660 group video
) > "%SYSROOT%\etc\devfs.rules"
echo devfs_system_ruleset="system">> "%SYSROOT%\etc\rc.conf"

if "%PROTOCOL%"=="wayland" (
    echo seatd_enable="YES">> "%SYSROOT%\etc\rc.conf"
)
if "%PROTOCOL%"=="x11" (
    if not exist "%SYSROOT%\usr\local\etc\X11\xorg.conf.d" mkdir "%SYSROOT%\usr\local\etc\X11\xorg.conf.d"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Display protocol %PROTOCOL% configured.
exit /b 0
