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

set "SCRIPT_DIR=%~dp0"
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
    echo kld_list="${kld_list:-} /boot/modules/virtio_gpu.ko">> "%SYSROOT%\etc
c.conf"
)

(
    echo [system=10]
    echo add path 'dri/*' mode 0666 group video
    echo add path 'drm/*' mode 0666 group video
    echo add path 'input/*' mode 0660 group video
) > "%SYSROOT%\etc\devfs.rules"
echo devfs_system_ruleset="system">> "%SYSROOT%\etc
c.conf"

if "%PROTOCOL%"=="wayland" (
    echo seatd_enable="YES">> "%SYSROOT%\etc
c.conf"
)
if "%PROTOCOL%"=="x11" (
    if not exist "%SYSROOT%\usr\local\etc\X11\xorg.conf.d" mkdir "%SYSROOT%\usr\local\etc\X11\xorg.conf.d"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Display protocol %PROTOCOL% configured.
exit /b 0
