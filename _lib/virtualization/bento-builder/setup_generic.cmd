@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup and box-builder orchestration module for Bento Builder stack, provisioning
:: Bento::VagrantMsdos and Bento::VagrantFreedos plugins and delegating MS-DOS (1.25, 2.0, 4.0)
:: and FreeDOS (1.3, 1.4) .box builds to ..\bento\{msdos,freedos}-builder.cmd.
::
:: ## Usage
:: Internal generic setup and build script for Bento Builder on Windows.

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
if "%VERSION%"=="" set "VERSION=latest"
if not defined LIBSCRIPT_HOME set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%BENTO_REPO_URL%"=="" (
    if defined BENTO_BUILDER_REPO_URL (
        set "BENTO_REPO_URL=%BENTO_BUILDER_REPO_URL%"
    ) else (
        set "BENTO_REPO_URL=https://github.com/SamuelMarks/bento.git"
    )
)
if "%BENTO_BRANCH%"=="" (
    if defined BENTO_BUILDER_BRANCH (
        set "BENTO_BRANCH=%BENTO_BUILDER_BRANCH%"
    ) else (
        set "BENTO_BRANCH=multi-os-qemu-aarch64"
    )
)
if "%BENTO_BUILDER_INSTALL_MSDOS_PLUGIN%"=="" set "BENTO_BUILDER_INSTALL_MSDOS_PLUGIN=1"
if "%BENTO_BUILDER_FORCE_REBUILD%"=="" (
    if defined FORCE_REBUILD (
        set "BENTO_BUILDER_FORCE_REBUILD=%FORCE_REBUILD%"
    ) else (
        set "BENTO_BUILDER_FORCE_REBUILD=0"
    )
)

if /i "%ACTION%"=="ls" (
    echo Bento Builder virtualization environment
    exit /b 0
)
if /i "%ACTION%"=="build" goto :action_build_or_register
if /i "%ACTION%"=="box" goto :action_build_or_register
if /i "%ACTION%"=="register" goto :action_build_or_register
if /i "%ACTION%"=="test" (
    set "STACK="
    call "!SCRIPT_DIR!\test.cmd"
    exit /b !ERRORLEVEL!
)
if /i "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\bento-builder\%VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\bento-builder\%VERSION%" >nul 2>&1
    exit /b 0
)

if /i "%ACTION%"=="install" (
    if exist "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\.installed" (
        echo [INFO] bento-builder %VERSION% is already installed.
        exit /b 0
    )
    echo Provisioning Bento Builder environment on Windows...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\qemu\setup.cmd" install
    set "STACK="
    if /i not "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\virtualbox\setup.cmd" install
        set "STACK="
    )
    call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\packer\setup.cmd" install
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\vagrant\setup.cmd" install
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\ruby\setup.cmd" install
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
    call :find_bento_dir
    if defined RESOLVED_BENTO_DIR (
        if not exist "!RESOLVED_BENTO_DIR!\.git" if defined BENTO_DIR if not "%LIBSCRIPT_OFFLINE%"=="1" (
            git clone --branch "!BENTO_BRANCH!" "!BENTO_REPO_URL!" "!RESOLVED_BENTO_DIR!" 2>nul
        )
        call :configure_bento_dos_plugins "!RESOLVED_BENTO_DIR!"
    )
    if not exist "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\bin" mkdir "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\bin"
    (
        echo @echo off
        echo call "%LIBSCRIPT_ROOT_DIR%\_lib\virtualization\bento-builder\cli.cmd" %%*
    ) > "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\bin\bento-builder.cmd"
    echo installed > "%LIBSCRIPT_HOME%\bento-builder\%VERSION%\.installed"
    echo Bento Builder environment provisioned on Windows.
)
exit /b 0

:: ## find_bento_dir
:: Locates the local Bento directory on Windows via BENTO_DIR, ..\bento, or USERPROFILE\bento.
:find_bento_dir
set "RESOLVED_BENTO_DIR="
if defined BENTO_DIR if exist "!BENTO_DIR!\" (
    for %%D in ("!BENTO_DIR!") do set "RESOLVED_BENTO_DIR=%%~fD"
    exit /b 0
)
for %%C in ("!LIBSCRIPT_ROOT_DIR!\..\bento" "%CD%\..\bento" "%CD%\bento" "%USERPROFILE%\bento") do (
    if not defined RESOLVED_BENTO_DIR (
        if exist "%%~fC\bento.gemspec" set "RESOLVED_BENTO_DIR=%%~fC"
        if exist "%%~fC\os_pkrvars\" set "RESOLVED_BENTO_DIR=%%~fC"
    )
)
exit /b 0

:: ## configure_bento_dos_plugins
:: Configures RUBYLIB for Bento::VagrantMsdos and Bento::VagrantFreedos with legacy vagrant-msdos fallback.
:configure_bento_dos_plugins
set "_P_DIR=%~1"
if not "!BENTO_BUILDER_INSTALL_MSDOS_PLUGIN!"=="1" exit /b 0
if exist "!_P_DIR!\lib\" (
    echo ;!RUBYLIB!; | findstr /I /C:";!_P_DIR!\lib;" >nul 2>&1
    if errorlevel 1 (
        if "!RUBYLIB!"=="" (
            set "RUBYLIB=!_P_DIR!\lib"
        ) else (
            set "RUBYLIB=!_P_DIR!\lib;!RUBYLIB!"
        )
    )
)
if exist "!_P_DIR!\lib\bento\vagrant_msdos.rb" if exist "!_P_DIR!\lib\bento\vagrant_freedos.rb" (
    echo [INFO] Detected Bento DOS Vagrant plugins in !_P_DIR!\lib.
    exit /b 0
)
if not "%LIBSCRIPT_OFFLINE%"=="1" if exist "!_P_DIR!\vagrant-msdos\vagrant-msdos.gemspec" (
    vagrant plugin list 2>nul | findstr /I /C:"vagrant-msdos" >nul 2>&1
    if errorlevel 1 (
        pushd "!_P_DIR!\vagrant-msdos"
        call gem build vagrant-msdos.gemspec 2>nul
        for %%G in (vagrant-msdos-*.gem) do call vagrant plugin install "%%~fG" 2>nul
        popd
    )
)
exit /b 0

:: ## has_cached_bento_box
:: Checks whether builds\build_complete\<stem>-*.qemu.box already exists in RESOLVED_BENTO_DIR.
:has_cached_bento_box
set "_H_STEM=%~1"
set "CACHED_BOX_PATH="
for %%A in (aarch64 x86_64 i386) do (
    if not defined CACHED_BOX_PATH if exist "!RESOLVED_BENTO_DIR!\builds\build_complete\!_H_STEM!-%%A.qemu.box" (
        set "CACHED_BOX_PATH=!RESOLVED_BENTO_DIR!\builds\build_complete\!_H_STEM!-%%A.qemu.box"
    )
)
exit /b 0

:: ## action_build_or_register
:: Builds a requested DOS or OS target via ..\bento\{msdos,freedos}-builder.cmd and registers boxes idempotently.
:action_build_or_register
call :find_bento_dir
if not defined RESOLVED_BENTO_DIR (
    echo [ERROR] Could not locate ..\bento directory; set BENTO_DIR to your Bento checkout. 1>&2
    exit /b 1
)
call :configure_bento_dos_plugins "!RESOLVED_BENTO_DIR!"

if /i "!ACTION!"=="register" goto :finish_register
if "!BENTO_BUILDER_TARGET_OS!"=="" goto :finish_register

set "_TGT=!BENTO_BUILDER_TARGET_OS!"
if /i "!_TGT:~0,6!"=="msdos-" (
    set "_VER=!_TGT:~6!"
    call :has_cached_bento_box "!_TGT!"
    if not "!BENTO_BUILDER_FORCE_REBUILD!"=="1" if defined CACHED_BOX_PATH (
        echo [SKIP] !_TGT! box already built at !CACHED_BOX_PATH!; registering idempotently.
        goto :finish_register
    )
    if exist "!RESOLVED_BENTO_DIR!\msdos-builder.cmd" (
        pushd "!RESOLVED_BENTO_DIR!"
        set "MSDOS_VERSION=!_VER!"
        call "!RESOLVED_BENTO_DIR!\msdos-builder.cmd" all
        set "_B_RC=!ERRORLEVEL!"
        popd
        if not "!_B_RC!"=="0" exit /b !_B_RC!
        goto :finish_register
    )
    echo [ERROR] Missing !RESOLVED_BENTO_DIR!\msdos-builder.cmd 1>&2
    exit /b 1
)

if /i "!_TGT:~0,7!"=="freedos" (
    set "_VER=1.3"
    if /i "!_TGT:~0,8!"=="freedos-" set "_VER=!_TGT:~8!"
    set "_STEM=freedos-!_VER!"
    call :has_cached_bento_box "!_STEM!"
    if not "!BENTO_BUILDER_FORCE_REBUILD!"=="1" if defined CACHED_BOX_PATH (
        echo [SKIP] !_STEM! box already built at !CACHED_BOX_PATH!; registering idempotently.
        goto :finish_register
    )
    if exist "!RESOLVED_BENTO_DIR!\freedos-builder.cmd" (
        pushd "!RESOLVED_BENTO_DIR!"
        set "FREEDOS_VERSION=!_VER!"
        call "!RESOLVED_BENTO_DIR!\freedos-builder.cmd" box
        set "_B_RC=!ERRORLEVEL!"
        popd
        if not "!_B_RC!"=="0" exit /b !_B_RC!
        goto :finish_register
    )
    echo [ERROR] Missing !RESOLVED_BENTO_DIR!\freedos-builder.cmd 1>&2
    exit /b 1
)

:: ## finish_register
:: Invokes tests\register_bento_boxes.cmd against RESOLVED_BENTO_DIR.
:finish_register
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd" --bento-dir "!RESOLVED_BENTO_DIR!"
exit /b !ERRORLEVEL!
