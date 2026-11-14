@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup for cross-platform .NET 8 WiX v4/v5 and WiX v3.14 Toolset.
::
:: ## Usage
:: Managed by libscript (`install`, `ls`, `ls-remote`, `use`, `download`).

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
if "%ACTION%"=="" set "ACTION=install"
if "%WIX_VERSION%"=="" set "WIX_VERSION=5.0.2"
set "EXACT_VERSION=%WIX_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=5.0.2"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "TARGET_DIR=%LIBSCRIPT_HOME%\wix\!EXACT_VERSION!"

if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\wix" dir /b "%LIBSCRIPT_HOME%\wix"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 5.0.2
    echo 4.0.5
    echo 3.14
    exit /b 0
)
if /I "%ACTION%"=="use" (
    if not exist "!TARGET_DIR!" (
        set "ACTION=install"
        call "%~f0"
    )
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "wix" "%WIX_VERSION%" "!EXACT_VERSION!"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "wix" "default" "!EXACT_VERSION!"
    exit /b 0
)
if /I not "%ACTION%"=="install" exit /b 0

if "!EXACT_VERSION!"=="3.14" (
    if exist "!TARGET_DIR!\bin\candle.exe" (
        echo [INFO] wix 3.14 is already installed.
        exit /b 0
    )
    if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
    set "DL_URL=%WIX_DOWNLOAD_URL%"
    if "!DL_URL!"=="" set "DL_URL=https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314-binaries.zip"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "%TEMP%\wix314.zip"
    tar -xf "%TEMP%\wix314.zip" -C "!TARGET_DIR!\bin"
    del /f /q "%TEMP%\wix314.zip" >nul 2>&1
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "wix" "%WIX_VERSION%" "!EXACT_VERSION!"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "wix" "default" "!EXACT_VERSION!"
    exit /b 0
)

if exist "!TARGET_DIR!\bin\wix.exe" (
    echo [INFO] wix !EXACT_VERSION! is already installed.
    exit /b 0
)
where dotnet >nul 2>&1
if errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install csharp 8.0
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\csharp\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\csharp\env.cmd"
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
dotnet tool install --tool-path "!TARGET_DIR!\bin" wix --version "!EXACT_VERSION!" || dotnet tool update --tool-path "!TARGET_DIR!\bin" wix --version "!EXACT_VERSION!"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "wix" "%WIX_VERSION%" "!EXACT_VERSION!"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "wix" "default" "!EXACT_VERSION!"
exit /b 0
