@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic setup module for msi-rs on Windows.
:: Resolves C and Rust toolchain requirements, builds msi-rs from source or extracts cached binaries,
:: and sets up version-isolated binaries with alias junctions.
::
:: ## Usage
:: Execute this script to perform generic setup operations for msi-rs:
::   setup_generic.cmd [install|use|download|uninstall|ls|ls-remote]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    set "LIBSCRIPT_ROOT_DIR=%~dp0\..\..\.."
)
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)
if "%MSI_RS_REPO_URL%"=="" (
    set "MSI_RS_REPO_URL=https://github.com/SamuelMarks/msi-rs"
)
if "%MSI_RS_INSTALL_METHOD%"=="" (
    set "MSI_RS_INSTALL_METHOD=libscript_native"
)
if "%MSI_RS_VERSION%"=="" (
    set "MSI_RS_VERSION=latest"
)

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=install"

if /i "%ACTION%"=="ls" goto action_ls
if /i "%ACTION%"=="ls-remote" goto action_ls_remote
if /i "%ACTION%"=="use" goto action_use
if /i "%ACTION%"=="download" goto action_download
if /i "%ACTION%"=="install" goto action_install
if /i "%ACTION%"=="uninstall" goto action_uninstall
if /i "%ACTION%"=="start" goto action_service
if /i "%ACTION%"=="stop" goto action_service
if /i "%ACTION%"=="restart" goto action_service
if /i "%ACTION%"=="status" goto action_service
if /i "%ACTION%"=="health" goto action_service
if /i "%ACTION%"=="logs" goto action_service
if /i "%ACTION%"=="up" goto action_service
if /i "%ACTION%"=="down" goto action_service
if /i "%ACTION%"=="install-service" goto action_install_service
if /i "%ACTION%"=="uninstall-service" goto action_uninstall_service

echo Unknown action "%ACTION%" for msi-rs >&2
exit /b 1

:: ## action_ls
:: Executes action_ls functionality.
:action_ls
if exist "%LIBSCRIPT_HOME%\msi-rs" (
    dir /b "%LIBSCRIPT_HOME%\msi-rs"
)
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if not "%MSI_RS_RELEASES_URL%"=="" (
    curl -sSL "%MSI_RS_RELEASES_URL%"
) else (
    git ls-remote --tags "%MSI_RS_REPO_URL%" 2>nul | findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    if errorlevel 1 echo 0.0.1
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
set "EXACT_VERSION=%MSI_RS_VERSION%"
if "%MSI_RS_VERSION%"=="latest" set "EXACT_VERSION=v0.0.1"

set "TARGET_DIR=%LIBSCRIPT_HOME%\msi-rs\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%"
set "DEFAULT_DIR=%LIBSCRIPT_HOME%\msi-rs\default"

if not exist "%TARGET_DIR%" (
    echo msi-rs %EXACT_VERSION% is not installed. Installing now...
    call "%~dp0setup.cmd" install msi-rs %MSI_RS_VERSION%
)

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
if exist "%DEFAULT_DIR%" rmdir "%DEFAULT_DIR%"
mklink /J "%DEFAULT_DIR%" "%TARGET_DIR%" >nul 2>&1
echo Default msi-rs set to %EXACT_VERSION%.
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
set "EXACT_VERSION=%MSI_RS_VERSION%"
if "%MSI_RS_VERSION%"=="latest" set "EXACT_VERSION=v0.0.1"
set "CACHE_DIR=%DOWNLOAD_DIR%\msi-rs"
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
echo Downloading msi-rs %MSI_RS_VERSION% artifacts to %CACHE_DIR%...
if not "%MSI_RS_DOWNLOAD_URL%"=="" (
    curl -sSL "%MSI_RS_DOWNLOAD_URL%" -o "%CACHE_DIR%\msi-rs-%EXACT_VERSION%.zip"
) else (
    curl -sSL "%MSI_RS_REPO_URL%/archive/refs/tags/%EXACT_VERSION%.zip" -o "%CACHE_DIR%\msi-rs-%EXACT_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
set "EXACT_VERSION=%MSI_RS_VERSION%"
if "%MSI_RS_VERSION%"=="latest" set "EXACT_VERSION=v0.0.1"
set "TARGET_DIR=%LIBSCRIPT_HOME%\msi-rs\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%"
set "DEFAULT_DIR=%LIBSCRIPT_HOME%\msi-rs\default"

if exist "%TARGET_DIR%\bin\msi-cli.exe" (
    echo msi-rs %EXACT_VERSION% is already installed.
    goto link_aliases
)
if exist "%TARGET_DIR%\bin\msi-rs.exe" (
    echo msi-rs %EXACT_VERSION% is already installed.
    goto link_aliases
)

echo Installing msi-rs %EXACT_VERSION% natively to %TARGET_DIR%...
if not exist "%TARGET_DIR%\bin\" mkdir "%TARGET_DIR%\bin\"

:: Attempt to download pre-compiled Windows binary
set "WIN_ARCH=x86_64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "WIN_ARCH=aarch64"
set "RELEASE_URL=%MSI_RS_REPO_URL%/releases/download/%EXACT_VERSION%/msi-tools-%EXACT_VERSION%-%WIN_ARCH%-pc-windows-msvc.zip"
echo [INFO] Attempting to download pre-compiled binary release: %RELEASE_URL%
curl -sSLf "%RELEASE_URL%" -o "%TEMP%\msi_rs_prebuilt.zip"
if not errorlevel 1 (
    echo Extracting pre-compiled binary release...
    if exist "%TEMP%\msi_rs_extracted" rmdir /s /q "%TEMP%\msi_rs_extracted" >nul 2>&1
    powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\msi_rs_prebuilt.zip' -DestinationPath '%TEMP%\msi_rs_extracted' -Force"
    del "%TEMP%\msi_rs_prebuilt.zip" >nul 2>&1
    if exist "%TEMP%\msi_rs_extracted\msi-tools-%EXACT_VERSION%-%WIN_ARCH%-pc-windows-msvc\" (
        xcopy /e /y /q "%TEMP%\msi_rs_extracted\msi-tools-%EXACT_VERSION%-%WIN_ARCH%-pc-windows-msvc\*" "%TARGET_DIR%\bin\" >nul
    ) else (
        xcopy /e /y /q "%TEMP%\msi_rs_extracted\*" "%TARGET_DIR%\bin\" >nul
    )
    rmdir /s /q "%TEMP%\msi_rs_extracted" >nul 2>&1
    call :install_binaries "%TARGET_DIR%\bin"
    goto link_aliases
) else (
    echo [WARN] Binary download failed. Falling back to source build...
)

:: Ensure C toolchain
where cl.exe >nul 2>&1
if errorlevel 1 (
    where gcc.exe >nul 2>&1
    if errorlevel 1 (
        where clang.exe >nul 2>&1
        if errorlevel 1 (
            echo C compiler not found; attempting setup via libscript languages\c...
            if exist "%LIBSCRIPT_ROOT_DIR%\_lib\languages\c\setup.cmd" (
                call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\c\setup.cmd" install c latest
            )
        )
    )
)

:: Ensure Rust toolchain
if exist "%USERPROFILE%\.cargo\bin\cargo.exe" (
    set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
)
where cargo.exe >nul 2>&1
if errorlevel 1 (
    echo Cargo not found; attempting setup via libscript languages\rust...
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\languages\rust\setup.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\rust\setup.cmd" install rust latest
        if exist "%USERPROFILE%\.cargo\bin\cargo.exe" (
            set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
        )
    )
)

set "CACHE_ZIP=%DOWNLOAD_DIR%\msi-rs\msi-rs-%EXACT_VERSION%.zip"
set "BUILD_DIR=%TEMP%\msi_rs_build_%RANDOM%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

if exist "%CACHE_ZIP%" (
    echo Extracting msi-rs from cached zip...
    tar -xf "%CACHE_ZIP%" -C "%BUILD_DIR%" --strip-components=1
    cd /d "%BUILD_DIR%"
    cargo build --release -p msi-cli
    call :install_binaries "%BUILD_DIR%\target\release"
    cd /d "%~dp0"
    rmdir /s /q "%BUILD_DIR%" >nul 2>&1
) else if not "%MSI_RS_DOWNLOAD_URL%"=="" (
    echo Downloading prebuilt msi-rs binary archive...
    curl -sSL "%MSI_RS_DOWNLOAD_URL%" -o "%TEMP%\msi_rs_prebuilt.zip"
    tar -xf "%TEMP%\msi_rs_prebuilt.zip" -C "%TARGET_DIR%"
    del "%TEMP%\msi_rs_prebuilt.zip" >nul 2>&1
) else (
    echo Cloning source repository from %MSI_RS_REPO_URL%...
    git clone "%MSI_RS_REPO_URL%" "%BUILD_DIR%"
    cd /d "%BUILD_DIR%"
    git checkout %EXACT_VERSION%
    cd /d "%BUILD_DIR%"
    cargo build --release -p msi-cli
    call :install_binaries "%BUILD_DIR%\target\release"
    cd /d "%~dp0"
    rmdir /s /q "%BUILD_DIR%" >nul 2>&1
)

:: ## link_aliases
:: Executes link_aliases functionality.
:link_aliases
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
if exist "%DEFAULT_DIR%" rmdir "%DEFAULT_DIR%"
mklink /J "%DEFAULT_DIR%" "%TARGET_DIR%" >nul 2>&1
echo msi-rs %EXACT_VERSION% installation completed.
exit /b 0

:: ## install_binaries
:: Copies built binaries to the destination bin directory and creates drop-in aliases.
:install_binaries
set "RELEASE_DIR=%~1"
for %%B in (msi-cli candle light wix dark heat torch pyro lit smoke msiinfo msibuild msidump msidiff msiextract msi-gui) do (
    if exist "%RELEASE_DIR%\%%B.exe" (
        copy /y "%RELEASE_DIR%\%%B.exe" "%TARGET_DIR%\bin\" >nul
    )
)
if exist "%TARGET_DIR%\bin\msi-cli.exe" (
    copy /y "%TARGET_DIR%\bin\msi-cli.exe" "%TARGET_DIR%\bin\msi-rs.exe" >nul
    copy /y "%TARGET_DIR%\bin\msi-cli.exe" "%TARGET_DIR%\bin\msi.exe" >nul
) else if exist "%TARGET_DIR%\bin\wix.exe" (
    copy /y "%TARGET_DIR%\bin\wix.exe" "%TARGET_DIR%\bin\msi-cli.exe" >nul
    copy /y "%TARGET_DIR%\bin\wix.exe" "%TARGET_DIR%\bin\msi-rs.exe" >nul
    copy /y "%TARGET_DIR%\bin\wix.exe" "%TARGET_DIR%\bin\msi.exe" >nul
)
exit /b 0

:: ## action_service
:: Executes action_service functionality.
:action_service
set "SVC_NAME=libscript_msi-rs"
if not "%LIBSCRIPT_SERVICE_NAME%"=="" set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
set "SVC_NAME=libscript_msi-rs"
if not "%LIBSCRIPT_SERVICE_NAME%"=="" set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
set "SVC_NAME=libscript_msi-rs"
if not "%LIBSCRIPT_SERVICE_NAME%"=="" set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
)
exit /b 0

:: ## action_uninstall
:: Executes action_uninstall functionality.
:action_uninstall
set "EXACT_VERSION=%MSI_RS_VERSION%"
if "%MSI_RS_VERSION%"=="latest" set "EXACT_VERSION=v0.0.1"
set "TARGET_DIR=%LIBSCRIPT_HOME%\msi-rs\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%"
set "DEFAULT_DIR=%LIBSCRIPT_HOME%\msi-rs\default"

if exist "%TARGET_DIR%" rmdir /s /q "%TARGET_DIR%"
if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
if exist "%DEFAULT_DIR%" rmdir "%DEFAULT_DIR%"
echo msi-rs %EXACT_VERSION% uninstalled.
exit /b 0
