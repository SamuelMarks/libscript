@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for Bento Builder stack.
::
:: ## Usage
:: Internal generic setup script for Bento Builder on Windows.

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

if "%ACTION%"=="" set ACTION=install
if "%VERSION%"=="" set "VERSION=latest"
if not defined LIBSCRIPT_HOME set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%BENTO_REPO_URL%"=="" set "BENTO_REPO_URL=https://github.com/SamuelMarks/bento.git"
if "%BENTO_BRANCH%"=="" set "BENTO_BRANCH=multi-os-qemu-aarch64"

if "%ACTION%"=="install" (
    if exist "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\.installed" (
        echo [INFO] bento-builder %VERSION% is already installed.
        exit /b 0
    )
    echo Provisioning Bento Builder environment on Windows...
    set "STACK="
    call "%~dp0\..\..\..\_lib\orchestration\qemu\setup.cmd" install
    set "STACK="
    if /i not "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        call "%~dp0\..\..\..\_lib\orchestration\virtualbox\setup.cmd" install
        set "STACK="
    )
    call "%~dp0\..\..\..\_lib\orchestration\packer\setup.cmd" install
    set "STACK="
    call "%~dp0\..\..\..\_lib\orchestration\vagrant\setup.cmd" install
    set "STACK="
    call "%~dp0\..\..\..\_lib\languages\ruby\setup.cmd" install
    set "STACK="

    where 7z >nul 2>&1
    if !errorlevel! neq 0 (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install 7zip latest
    )
    where git >nul 2>&1
    if !errorlevel! neq 0 (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install git-servers/utils latest
    )
    if defined BENTO_DIR (
        if not exist "!BENTO_DIR!\.git" (
            git clone --branch "!BENTO_BRANCH!" "!BENTO_REPO_URL!" "!BENTO_DIR!" 2>nul
        ) else (
            git -C "!BENTO_DIR!" checkout "!BENTO_BRANCH!" 2>nul
        )
    )
    if "%BENTO_BUILDER_INSTALL_MSDOS_PLUGIN%"=="" set "BENTO_BUILDER_INSTALL_MSDOS_PLUGIN=1"
    if "!BENTO_BUILDER_INSTALL_MSDOS_PLUGIN!"=="1" if defined BENTO_DIR if exist "!BENTO_DIR!\vagrant-msdos\vagrant-msdos.gemspec" (
        vagrant plugin list 2>nul | findstr /I /C:"vagrant-msdos" >nul 2>&1
        if errorlevel 1 (
            pushd "!BENTO_DIR!\vagrant-msdos"
            call gem build vagrant-msdos.gemspec 2>nul
            for %%G in (vagrant-msdos-*.gem) do call vagrant plugin install "%%~fG" 2>nul
            popd
        )
    )
    if not exist "%LIBSCRIPT_HOME%\bento-builder\%VERSION%" mkdir "%LIBSCRIPT_HOME%\bento-builder\%VERSION%"
    echo installed > "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\.installed"
    echo Bento Builder environment provisioned on Windows.
)
exit /b 0
