@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for gradle
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
if "%GRADLE_VERSION%"=="" set GRADLE_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%GRADLE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GRADLE_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GRADLE_INSTALL_METHOD=libscript_native"
    )
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
goto :action_install

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%GRADLE_INSTALL_METHOD%"=="mise" ( mise ls gradle & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="asdf" ( asdf list gradle & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="vfox" ( vfox ls gradle & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\gradle" ( dir /b "%LIBSCRIPT_HOME%\gradle" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%GRADLE_INSTALL_METHOD%"=="mise" ( mise ls-remote gradle & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="asdf" ( asdf list all gradle & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="vfox" ( vfox ls all gradle & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%GRADLE_RELEASES_URL%"=="" (
    curl -sSL "%GRADLE_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%GRADLE_INSTALL_METHOD%"=="mise" ( mise use "gradle@%GRADLE_VERSION%" & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="asdf" ( asdf global gradle "%GRADLE_VERSION%" & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="vfox" ( vfox use "gradle@%GRADLE_VERSION%" & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%GRADLE_VERSION%"=="latest" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/gradle/gradle/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else if "%GRADLE_VERSION%"=="lts" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/gradle/gradle/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else (
    set "EXACT_VERSION=%GRADLE_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%GRADLE_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\gradle\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gradle\%GRADLE_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%GRADLE_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading gradle %GRADLE_VERSION% to %DOWNLOAD_DIR%\gradle...
    if not exist "%DOWNLOAD_DIR%\gradle" mkdir "%DOWNLOAD_DIR%\gradle"
    if not "%GRADLE_DOWNLOAD_URL%"=="" (
        curl -sSL "%GRADLE_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\gradle\gradle-%GRADLE_VERSION%.zip"
    ) else (
        echo GRADLE_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%GRADLE_INSTALL_METHOD%"=="system" (
    winget install gradle --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%GRADLE_INSTALL_METHOD%"=="mise" ( mise install "gradle@%GRADLE_VERSION%" & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="asdf" ( asdf install gradle "%GRADLE_VERSION%" & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="pkgx" ( pkgx install "gradle@%GRADLE_VERSION%" & exit /b 0 )
if "%GRADLE_INSTALL_METHOD%"=="vfox" ( vfox add gradle & vfox install "gradle@%GRADLE_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\gradle\%GRADLE_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing gradle %GRADLE_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\gradle\gradle-%GRADLE_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\gradle\gradle-%GRADLE_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\gradle\gradle-%GRADLE_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\gradle\gradle-%GRADLE_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%GRADLE_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%GRADLE_DOWNLOAD_URL%" -o "%TEMP%\gradle.zip"
        tar -xf "%TEMP%\gradle.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for gradle.
        exit /b 1
    )
) else (
    echo gradle %GRADLE_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gradle\%GRADLE_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the service manager.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_gradle"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GRADLE_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%GRADLE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %GRADLE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_gradle"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GRADLE_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%GRADLE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %GRADLE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_gradle"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GRADLE_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%GRADLE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %GRADLE_INSTALL_METHOD%.
)
exit /b 0
