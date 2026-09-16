@echo off
:: ## Overview
:: Windows setup for memcached
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install
if "%MEMCACHED_VERSION%"=="" set MEMCACHED_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%MEMCACHED_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "MEMCACHED_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "MEMCACHED_INSTALL_METHOD=libscript_native"
    )
)

:: Resolve download URL for Windows
if "%MEMCACHED_DOWNLOAD_URL%"=="" (
    set "_tmp_ver=%MEMCACHED_VERSION%"
)
if "%MEMCACHED_DOWNLOAD_URL%"=="" (
    if "%_tmp_ver%"=="latest" (
        for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "git ls-remote --tags 'https://github.com/SamuelMarks/memcached-windows' 2^>$null ^| Select-String -Pattern '\d+\.\d+\.\d+' -AllMatches ^| ForEach-Object { $_.Matches.Value } ^| Sort-Object {[version]$_} ^| Select-Object -Last 1"`) do set "_tmp_ver=%%I"
    )
)
if "%MEMCACHED_DOWNLOAD_URL%"=="" (
    if "%_tmp_ver%"=="latest" set "_tmp_ver=1.6.45"
    if "!_tmp_ver:~0,1!"=="v" set "_tmp_ver=!_tmp_ver:~1!"
    if not "%_tmp_ver%"=="" (
        set "MEMCACHED_DOWNLOAD_URL=https://github.com/SamuelMarks/memcached-windows/releases/download/v!_tmp_ver!/Memcached-!_tmp_ver!-win64.zip"
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
if "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## action_ls
:: Executes action_ls functionality.
:action_ls
if "%MEMCACHED_INSTALL_METHOD%"=="mise" ( mise ls memcached & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="asdf" ( asdf list memcached & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="vfox" ( vfox ls memcached & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\memcached" ( dir /b "%LIBSCRIPT_HOME%\memcached" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%MEMCACHED_INSTALL_METHOD%"=="mise" ( mise ls-remote memcached & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="asdf" ( asdf list all memcached & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="vfox" ( vfox ls all memcached & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%MEMCACHED_RELEASES_URL%"=="" (
    curl -sSL "%MEMCACHED_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/SamuelMarks/memcached-windows" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%MEMCACHED_INSTALL_METHOD%"=="mise" ( mise use "memcached@%MEMCACHED_VERSION%" & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="asdf" ( asdf global memcached "%MEMCACHED_VERSION%" & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="vfox" ( vfox use "memcached@%MEMCACHED_VERSION%" & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%MEMCACHED_VERSION%"=="latest" (set "EXACT_VERSION=1.6.45"
) else if "%MEMCACHED_VERSION%"=="lts" (set "EXACT_VERSION=1.6.45"
) else (
    set "EXACT_VERSION=%MEMCACHED_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%MEMCACHED_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\memcached\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\memcached\%MEMCACHED_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%MEMCACHED_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading memcached %MEMCACHED_VERSION% to %DOWNLOAD_DIR%\memcached...
    if not exist "%DOWNLOAD_DIR%\memcached" mkdir "%DOWNLOAD_DIR%\memcached"
    if not "%MEMCACHED_DOWNLOAD_URL%"=="" (
        curl -sSL "%MEMCACHED_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.zip"
    ) else (
        echo MEMCACHED_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%MEMCACHED_INSTALL_METHOD%"=="system" (
    winget install memcached --accept-package-agreements --accept-source-agreements 2>nul || choco install memcached -y
    exit /b !errorlevel!
)
if "%MEMCACHED_INSTALL_METHOD%"=="mise" ( mise install "memcached@%MEMCACHED_VERSION%" & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="asdf" ( asdf install memcached "%MEMCACHED_VERSION%" & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="pkgx" ( pkgx install "memcached@%MEMCACHED_VERSION%" & exit /b 0 )
if "%MEMCACHED_INSTALL_METHOD%"=="vfox" ( vfox add memcached & vfox install "memcached@%MEMCACHED_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\memcached\%MEMCACHED_VERSION%"
if not exist "%TARGET_DIR%\bin\memcached.exe" (
    echo Installing memcached %MEMCACHED_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.zip" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.zip" -C "%TARGET_DIR%" 2>nul || powershell -NoProfile -Command "Expand-Archive -Path '%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.zip' -DestinationPath '%TARGET_DIR%' -Force"
    ) else if exist "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.tar.gz" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "%DOWNLOAD_DIR%\memcached\memcached-%MEMCACHED_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%MEMCACHED_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%MEMCACHED_DOWNLOAD_URL%" -o "%TEMP%\memcached.zip"
        tar -xf "%TEMP%\memcached.zip" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "%TEMP%\memcached.zip" -C "%TARGET_DIR%" 2>nul || powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\memcached.zip' -DestinationPath '%TARGET_DIR%' -Force"
        del /f /q "%TEMP%\memcached.zip" 2>nul
    ) else (
        echo No download URL or cache available for memcached.
        exit /b 1
    )
    if not exist "%TARGET_DIR%\bin\memcached.exe" (
        for /d %%D in ("%TARGET_DIR%\Memcached-*") do (
            if exist "%%D\bin" (
                xcopy /E /I /Y "%%D\bin\*" "%TARGET_DIR%\bin" >nul 2>&1
            )
        )
    )
) else (
    echo memcached %MEMCACHED_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\memcached\%MEMCACHED_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Executes action_service functionality.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_memcached"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MEMCACHED_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%MEMCACHED_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %MEMCACHED_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_memcached"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MEMCACHED_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%MEMCACHED_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %MEMCACHED_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_memcached"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MEMCACHED_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%MEMCACHED_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %MEMCACHED_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall
:: Executes action_uninstall functionality.
:action_uninstall
if "%MEMCACHED_INSTALL_METHOD%"=="libscript_native" (
    echo Uninstalling memcached %MEMCACHED_VERSION%...
    if exist "%LIBSCRIPT_HOME%\memcached\%MEMCACHED_VERSION%" (
        rmdir /s /q "%LIBSCRIPT_HOME%\memcached\%MEMCACHED_VERSION%" 2>nul
    )
) else (
    echo Uninstall not implemented or supported for %MEMCACHED_INSTALL_METHOD%.
)
exit /b 0
