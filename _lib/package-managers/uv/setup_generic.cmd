@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for uv with reuse-else-create semantics.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
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

if "%ACTION%"=="" set ACTION=install
if "%UV_VERSION%"=="" set UV_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%UV_INSTALL_METHOD%"=="" (
    set "UV_INSTALL_METHOD=libscript_native"
)

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if "%ACTION%"=="start" goto :action_service
if "%ACTION%"=="stop" goto :action_service
if "%ACTION%"=="restart" goto :action_service
if "%ACTION%"=="status" goto :action_service
if "%ACTION%"=="health" goto :action_service
if "%ACTION%"=="logs" goto :action_service
if "%ACTION%"=="up" goto :action_service
if "%ACTION%"=="down" goto :action_service
if "%ACTION%"=="install-service" goto :action_install_service
if "%ACTION%"=="uninstall-service" goto :action_uninstall_service
goto :action_install

:: ## find_existing_uv
:: Checks LIBSCRIPT_HOME, USERPROFILE\.local\bin, and system PATH for an existing uv.exe binary.
:find_existing_uv
if exist "%LIBSCRIPT_HOME%\uv\%UV_VERSION%\bin\uv.exe" exit /b 0
if exist "%LIBSCRIPT_HOME%\uv\default\bin\uv.exe" exit /b 0
if exist "%USERPROFILE%\.local\bin\uv.exe" exit /b 0
where uv >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%UV_INSTALL_METHOD%"=="mise" ( mise ls uv & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="asdf" ( asdf list uv & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="vfox" ( vfox ls uv & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\uv" ( dir /b "%LIBSCRIPT_HOME%\uv" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%UV_INSTALL_METHOD%"=="mise" ( mise ls-remote uv & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="asdf" ( asdf list all uv & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="vfox" ( vfox ls all uv & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%UV_RELEASES_URL%"=="" (
    curl -sSL "%UV_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/astral-sh/uv" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%UV_INSTALL_METHOD%"=="mise" ( mise use "uv@%UV_VERSION%" & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="asdf" ( asdf global uv "%UV_VERSION%" & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="vfox" ( vfox use "uv@%UV_VERSION%" & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%UV_VERSION%"=="latest" (set "EXACT_VERSION=%UV_VERSION%"
) else if "%UV_VERSION%"=="lts" (set "EXACT_VERSION=%UV_VERSION%"
) else (
    set "EXACT_VERSION=%UV_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%UV_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\uv\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\uv\%UV_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%UV_INSTALL_METHOD%"=="libscript_native" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :find_existing_uv
        if not errorlevel 1 (
            echo [REUSE] uv is already installed; skipping download.
            exit /b 0
        )
    )
    echo Downloading uv %UV_VERSION% to %DOWNLOAD_DIR%\uv...
    if not exist "%DOWNLOAD_DIR%\uv" mkdir "%DOWNLOAD_DIR%\uv"
    if not "%UV_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%UV_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\uv\uv-%UV_VERSION%.zip"
    ) else (
        echo UV_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if not "%FORCE_REINSTALL%"=="1" (
    call :find_existing_uv
    if not errorlevel 1 (
        echo [REUSE] uv ^(%UV_VERSION%^) is already installed.
        exit /b 0
    )
)
if "%UV_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends uv
    exit /b !errorlevel!
)
if "%UV_INSTALL_METHOD%"=="mise" ( mise install "uv@%UV_VERSION%" & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="asdf" ( asdf install uv "%UV_VERSION%" & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="pkgx" ( pkgx install "uv@%UV_VERSION%" & exit /b 0 )
if "%UV_INSTALL_METHOD%"=="vfox" ( vfox add uv & vfox install "uv@%UV_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\uv\%UV_VERSION%"
if not exist "%TARGET_DIR%\bin\uv.exe" (
    echo Installing uv %UV_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\uv\uv-%UV_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\uv\uv-%UV_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\uv\uv-%UV_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\uv\uv-%UV_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%UV_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%UV_DOWNLOAD_URL%" "%TEMP%\uv.zip"
        tar -xf "%TEMP%\uv.zip" -C "%TARGET_DIR%"
    ) else (
        set "_UV_ARCH=x86_64"
        if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "_UV_ARCH=aarch64"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://github.com/astral-sh/uv/releases/latest/download/uv-!_UV_ARCH!-pc-windows-msvc.zip" "%TEMP%\uv.zip"
        if not errorlevel 1 (
            tar -xf "%TEMP%\uv.zip" -C "%TARGET_DIR%\bin"
            del /f /q "%TEMP%\uv.zip" 2>nul
        ) else (
            echo No download URL or cache available for uv.
            exit /b 1
        )
    )
) else (
    echo uv %UV_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\uv\%UV_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
set "DEFAULT_DIR=%LIBSCRIPT_HOME%\uv\default"
if not "%TARGET_DIR%"=="%DEFAULT_DIR%" (
    if exist "%DEFAULT_DIR%" rmdir "%DEFAULT_DIR%" 2>nul
    mklink /J "%DEFAULT_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the service manager.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_uv"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%UV_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%UV_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %UV_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_uv"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%UV_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%UV_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %UV_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_uv"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%UV_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%UV_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %UV_INSTALL_METHOD%.
)
exit /b 0
