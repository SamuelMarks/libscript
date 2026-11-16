@echo off
:: # users.cmd
::
:: ## Overview
:: Provisions local user accounts and optional Winlogon autologin inside the ReactOS sysroot on Windows.
::
:: ## Usage
:: _lib\reactos\distro\users.cmd [sysroot_path] [username] [password] [is_admin] [autologin_user]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "USER_NAME=%~2"
if "!USER_NAME!"=="" set "USER_NAME=admin"
set "USER_PASS=%~3"
if "!USER_PASS!"=="" set "USER_PASS=vagrant"
set "IS_ADMIN=%~4"
if "!IS_ADMIN!"=="" set "IS_ADMIN=true"
set "AUTOLOGIN=%~5"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\users.stamp"
set "LS_STAGE=!SYSROOT!\iso_root\libscript"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS user accounts already provisioned in !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!LS_STAGE!" mkdir "!LS_STAGE!"

echo net user "!USER_NAME!" "!USER_PASS!" /add ^>nul 2^>^&1>> "!LS_STAGE!\firstboot.cmd"
if /I "!IS_ADMIN!"=="true" echo net localgroup Administrators "!USER_NAME!" /add ^>nul 2^>^&1>> "!LS_STAGE!\firstboot.cmd"
if /I "!IS_ADMIN!"=="yes" echo net localgroup Administrators "!USER_NAME!" /add ^>nul 2^>^&1>> "!LS_STAGE!\firstboot.cmd"

if not "!AUTOLOGIN!"=="" (
    (
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
        echo "AutoAdminLogon"="1"
        echo "DefaultUserName"="!AUTOLOGIN!"
        echo "DefaultPassword"="!USER_PASS!"
    ) >> "!LS_STAGE!\hivesft_delta.reg"
)

echo provisioned> "!STAMP_FILE!"
echo [OK]       ReactOS user provisioning configured ^(user=!USER_NAME!^).
exit /b 0
