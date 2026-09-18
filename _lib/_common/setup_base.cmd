@echo off
setlocal EnableDelayedExpansion
:: # LibScript Common Setup Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component installation on Windows.
:: Resolves root, checks privileges, and delegates to setup scripts.
::
:: ## Usage
:: Your component's `setup.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
:: ```

setlocal EnableDelayedExpansion
set "CALLER_FILE=%THIS_FILE%"
set "THIS_FILE=%~f0"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%~dp0"
    call :find_root
)
goto :root_found

:: ## find_root
:: Executes find_root functionality.
:find_root
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
:: Executes root_found functionality.
:root_found

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

:: Resolve target component directory
set "TARGET_DIR="
if not "%CALLER_FILE%"=="" (
    for %%I in ("%CALLER_FILE%") do set "TARGET_DIR=%%~dpI"
)
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%CD%"
if /i "%TARGET_DIR%"=="%LIBSCRIPT_ROOT_DIR%\_lib\_common" set "TARGET_DIR=%CD%"

:: Privilege Check
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :check_admin
if errorlevel 1 (
    call "%LOG_CMD%" :log_info "Elevating to administrator..."
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv "%~f0"
    exit /b %errorlevel%
)

:: Delegate to specific setup script
set "SETUP_ERR=1"
if exist "%TARGET_DIR%\setup_windows.cmd" (
    call "%TARGET_DIR%\setup_windows.cmd" %*
    set "SETUP_ERR=!errorlevel!"
) else if exist "%TARGET_DIR%\setup_generic.cmd" (
    call "%TARGET_DIR%\setup_generic.cmd" %*
    set "SETUP_ERR=!errorlevel!"
) else if exist "%TARGET_DIR%\setup.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; & '%TARGET_DIR%\setup.ps1' }"
    set "SETUP_ERR=!errorlevel!"
) else (
    call "%LOG_CMD%" :log_error "No setup script found in %TARGET_DIR%"
    exit /b 1
)

if !SETUP_ERR! equ 0 exit /b 0

:: Resolve package name for fallback
if "%PACKAGE_NAME%"=="" (
    for %%I in ("%TARGET_DIR%") do set "PACKAGE_NAME=%%~nxI"
)

:: Fallback to Windows Package Managers (winget)
where winget >nul 2>&1
if not errorlevel 1 (
    set "WINGET_ID="
    if /i "%PACKAGE_NAME%"=="sqlite" set "WINGET_ID=SQLite.SQLite"
    if /i "%PACKAGE_NAME%"=="duckdb" set "WINGET_ID=DuckDB.cli"
    if /i "%PACKAGE_NAME%"=="redis" set "WINGET_ID=Redis.Redis"
    if /i "%PACKAGE_NAME%"=="python" set "WINGET_ID=Python.Python.3.12"
    if /i "%PACKAGE_NAME%"=="nodejs" set "WINGET_ID=OpenJS.NodeJS"
    if /i "%PACKAGE_NAME%"=="rust" set "WINGET_ID=Rustlang.Rustup"
    if /i "%PACKAGE_NAME%"=="rustup" set "WINGET_ID=Rustlang.Rustup"
    if /i "%PACKAGE_NAME%"=="cargo" set "WINGET_ID=Rustlang.Rustup"
    if /i "%PACKAGE_NAME%"=="cargo-binstall" set "WINGET_ID=cargo-bins.cargo-binstall"
    if /i "%PACKAGE_NAME%"=="go" set "WINGET_ID=GoLang.Go"
    if /i "%PACKAGE_NAME%"=="go-pm" set "WINGET_ID=GoLang.Go"
    if /i "%PACKAGE_NAME%"=="pip" set "WINGET_ID=Python.Python.3.12"
    if /i "%PACKAGE_NAME%"=="npm" set "WINGET_ID=OpenJS.NodeJS"
    if /i "%PACKAGE_NAME%"=="7zip" set "WINGET_ID=7zip.7zip"
    if /i "%PACKAGE_NAME%"=="jq" set "WINGET_ID=jqlang.jq"
    if /i "%PACKAGE_NAME%"=="cmake" set "WINGET_ID=Kitware.CMake"
    if /i "%PACKAGE_NAME%"=="bazel" set "WINGET_ID=Bazel.Bazel"
    if /i "%PACKAGE_NAME%"=="caddy" set "WINGET_ID=CaddyServer.Caddy"
    if /i "%PACKAGE_NAME%"=="nginx" set "WINGET_ID=nginxinc.nginx"
    if /i "%PACKAGE_NAME%"=="httpd" set "WINGET_ID=ApacheLounge.httpd"
    if /i "%PACKAGE_NAME%"=="aria2" set "WINGET_ID=aria2.aria2"
    if /i "%PACKAGE_NAME%"=="deno" set "WINGET_ID=DenoLand.Deno"
    if /i "%PACKAGE_NAME%"=="deno-pm" set "WINGET_ID=DenoLand.Deno"
    if /i "%PACKAGE_NAME%"=="bun" set "WINGET_ID=Oven-sh.Bun"
    if /i "%PACKAGE_NAME%"=="bun-pm" set "WINGET_ID=Oven-sh.Bun"
    if /i "%PACKAGE_NAME%"=="zig" set "WINGET_ID=zig.zig"
    if /i "%PACKAGE_NAME%"=="wget" set "WINGET_ID=JernejSimoncic.Wget"
    if /i "%PACKAGE_NAME%"=="curl" set "WINGET_ID=cURL.cURL"
    if /i "%PACKAGE_NAME%"=="busybox" set "WINGET_ID=frippery.busybox-w32"
    if /i "%PACKAGE_NAME%"=="uv" set "WINGET_ID=astral-sh.uv"
    if /i "%PACKAGE_NAME%"=="rye" set "WINGET_ID=Rye.Rye"
    if /i "%PACKAGE_NAME%"=="just" set "WINGET_ID=Casey.Just"
    if /i "%PACKAGE_NAME%"=="helm" set "WINGET_ID=Helm.Helm"
    if /i "%PACKAGE_NAME%"=="powershell" set "WINGET_ID=Microsoft.PowerShell"
    if /i "%PACKAGE_NAME%"=="git" set "WINGET_ID=Git.Git"
    if /i "%PACKAGE_NAME%"=="aws" set "WINGET_ID=Amazon.AWSCLI"
    if /i "%PACKAGE_NAME%"=="awscli" set "WINGET_ID=Amazon.AWSCLI"
    if /i "%PACKAGE_NAME%"=="azure" set "WINGET_ID=Microsoft.AzureCLI"
    if /i "%PACKAGE_NAME%"=="azure-cli" set "WINGET_ID=Microsoft.AzureCLI"
    if /i "%PACKAGE_NAME%"=="gcp" set "WINGET_ID=Google.CloudSDK"
    if /i "%PACKAGE_NAME%"=="google-cloud-sdk" set "WINGET_ID=Google.CloudSDK"
    if /i "%PACKAGE_NAME%"=="pnpm" set "WINGET_ID=pnpm.pnpm"
    if /i "%PACKAGE_NAME%"=="yarn" set "WINGET_ID=Yarn.Yarn"
    if /i "%PACKAGE_NAME%"=="r" set "WINGET_ID=RProject.R"
    if /i "%PACKAGE_NAME%"=="fnm" set "WINGET_ID=Schniz.fnm"
    if /i "%PACKAGE_NAME%"=="nvm" set "WINGET_ID=CoreyButler.NVMforWindows"
    if /i "%PACKAGE_NAME%"=="vfox" set "WINGET_ID=version-fox.vfox"
    if /i "%PACKAGE_NAME%"=="julia" set "WINGET_ID=Julialang.Juliaup"
    if /i "%PACKAGE_NAME%"=="luarocks" set "WINGET_ID=DEVCOM.Lua"
    if /i "%PACKAGE_NAME%"=="gradle" set "WINGET_ID=Gradle.Gradle"
    if /i "%PACKAGE_NAME%"=="maven" set "WINGET_ID=Apache.Maven"
    if /i "%PACKAGE_NAME%"=="php" set "WINGET_ID=PHP.PHP.8.4"
    if /i "%PACKAGE_NAME%"=="c" set "WINGET_ID=MartinStorsjo.LLVM-MinGW.UCRT"
    if /i "%PACKAGE_NAME%"=="cc" set "WINGET_ID=MartinStorsjo.LLVM-MinGW.UCRT"
    if /i "%PACKAGE_NAME%"=="cpp" set "WINGET_ID=MartinStorsjo.LLVM-MinGW.UCRT"
    if /i "%PACKAGE_NAME%"=="cpanm" set "WINGET_ID=StrawberryPerl.StrawberryPerl"
    if /i "%PACKAGE_NAME%"=="csharp" set "WINGET_ID=Microsoft.DotNet.SDK.8"
    if /i "%PACKAGE_NAME%"=="ruby" set "WINGET_ID=RubyInstallerTeam.Ruby.3.3"
    if /i "%PACKAGE_NAME%"=="gem" set "WINGET_ID=RubyInstallerTeam.Ruby.3.3"
    if /i "%PACKAGE_NAME%"=="bundler" set "WINGET_ID=RubyInstallerTeam.Ruby.3.3"
    if /i "%PACKAGE_NAME%"=="swift" set "WINGET_ID=Swift.Toolchain"
    if /i "%PACKAGE_NAME%"=="java" set "WINGET_ID=EclipseAdoptium.Temurin.21.JDK"
    if /i "%PACKAGE_NAME%"=="postgres" set "WINGET_ID=PostgreSQL.PostgreSQL.17"
    if /i "%PACKAGE_NAME%"=="mariadb" set "WINGET_ID=MariaDB.Server"
    if /i "%PACKAGE_NAME%"=="etcd" set "WINGET_ID=etcd.etcd"
    if /i "%PACKAGE_NAME%"=="fluentbit" set "WINGET_ID=Chronosphere.FluentBit"
    if /i "%PACKAGE_NAME%"=="ollama" set "WINGET_ID=Ollama.Ollama"
    if /i "%PACKAGE_NAME%"=="sbt" set "WINGET_ID=sbt.sbt"
    if /i "%PACKAGE_NAME%"=="pub" set "WINGET_ID=Google.DartSDK"
    if /i "%PACKAGE_NAME%"=="stack" set "WINGET_ID=commercialhaskell.stack"

    if defined WINGET_ID (
        call "%LOG_CMD%" :log_info "Native setup failed. Installing !PACKAGE_NAME! via winget (!WINGET_ID!)..."
        winget install --id "!WINGET_ID!" --silent --accept-package-agreements --accept-source-agreements
        if not errorlevel 1 exit /b 0
    ) else (
        call "%LOG_CMD%" :log_info "Native setup failed. Attempting winget install for !PACKAGE_NAME!..."
        winget install --name "!PACKAGE_NAME!" -e --silent --accept-package-agreements --accept-source-agreements
        if not errorlevel 1 exit /b 0
    )
)

exit /b !SETUP_ERR!

:: Helper functions (reachable via call :label)
goto :eof

:: ## libscript_install_binary
:: Executes libscript_install_binary functionality.
:libscript_install_binary
set "src_path=%~1"
set "bin_name=%~2"

if "%PREFIX%"=="" (
    set "dest_dir=%USERPROFILE%\.local\bin"
) else (
    set "dest_dir=%PREFIX%"
)

if not exist "%dest_dir%" mkdir "%dest_dir%"

:: Try SystemRoot if requested and admin
copy /y "%src_path%" "%SystemRoot%\" >nul 2>&1
if not errorlevel 1 (
    call "%LOG_CMD%" :log_info "%bin_name% installed to %SystemRoot%"
    exit /b 0
)

:: Fallback to user bin
copy /y "%src_path%" "%dest_dir%\%bin_name%" >nul 2>&1
if not errorlevel 1 (
    call "%LOG_CMD%" :log_info "%bin_name% installed to %dest_dir%"
    
    REM Check if dest_dir is in PATH
    echo %PATH% | findstr /i /c:"%dest_dir%" >nul
    if errorlevel 1 (
        call "%LOG_CMD%" :log_warn "%dest_dir% is not in your PATH."
    )
    exit /b 0
)

call "%LOG_CMD%" :log_error "Failed to install %bin_name% to %dest_dir%"
exit /b 1
