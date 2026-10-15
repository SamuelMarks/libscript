@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup module for msi-rs.
:: Resolves dependencies (Git, Rust, MSVC, vcredist), clones or fetches msi-rs,
:: builds the msi-rs binaries, and links them into the isolated version directory.
::
:: ## Usage
:: setup_generic.cmd [install|download|ls|ls-remote|use|uninstall]

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

if "%ACTION%"=="" set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=install"
if "%MSI_RS_VERSION%"=="" set "MSI_RS_VERSION=v0.0.1"
if "%MSI_RS_REPO_URL%"=="" set "MSI_RS_REPO_URL=https://github.com/SamuelMarks/msi-rs"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## action_ls
:: Lists locally installed msi-rs versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\msi-rs" dir /b "%LIBSCRIPT_HOME%\msi-rs"
exit /b 0

:: ## action_ls_remote
:: Lists remote tags available from the upstream msi-rs repository.
:action_ls_remote
git ls-remote --tags "%MSI_RS_REPO_URL%" 2>nul
exit /b 0

:: ## action_use
:: Links the specified msi-rs version as the default active version.
:action_use
set "TARGET_DIR=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\msi-rs\latest"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" 2>nul
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Clones or updates the msi-rs source repository in the download cache.
:action_download
if not exist "%DOWNLOAD_DIR%\msi-rs" mkdir "%DOWNLOAD_DIR%\msi-rs"
if not "%MSI_RS_DOWNLOAD_URL%"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "%MSI_RS_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\msi-rs\msi-rs-%MSI_RS_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Builds and installs msi-rs binaries into the isolated version directory.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%"
if exist "%TARGET_DIR%\bin\candle.exe" if exist "%TARGET_DIR%\bin\light.exe" (
    echo [INFO] msi-rs %MSI_RS_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"

set "_OLD_STACK=%STACK%"
set "STACK="
where git >nul 2>&1 || call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install git latest
where cargo >nul 2>&1 || call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install rust latest
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install vcredist latest
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install msvc latest
set "STACK=%_OLD_STACK%"

set "PATH=%USERPROFILE%\.cargo\bin;%ProgramFiles%\Git\cmd;%PATH%"
set "SRC_DIR=%DOWNLOAD_DIR%\msi-rs\src-%MSI_RS_VERSION%"
if not exist "%SRC_DIR%\.git" (
    if exist "%SRC_DIR%" rmdir /s /q "%SRC_DIR%"
    git clone "%MSI_RS_REPO_URL%" "%SRC_DIR%"
)
pushd "%SRC_DIR%"
git fetch --all --tags 2>nul
if not "%MSI_RS_VERSION%"=="latest" (
    git checkout "%MSI_RS_VERSION%" 2>nul
)
cargo build --release --bins
popd

for %%B in (msi msi-cli candle light wix dark heat torch pyro lit smoke msiinfo msibuild msidump msidiff msiextract) do (
    if exist "%SRC_DIR%\target\release\%%B.exe" (
        copy /y "%SRC_DIR%\target\release\%%B.exe" "%TARGET_DIR%\bin\%%B.exe" >nul
    )
)

set "ALIAS_DIR=%LIBSCRIPT_HOME%\msi-rs\latest"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" 2>nul
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_uninstall
:: Removes the installed msi-rs version directory.
:action_uninstall
set "TARGET_DIR=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%"
if exist "%TARGET_DIR%" rmdir /s /q "%TARGET_DIR%"
exit /b 0
