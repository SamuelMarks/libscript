@echo off
setlocal EnableDelayedExpansion
:: # LibScript Component Core Module (Windows Batch)
::
:: ## Overview
:: Unified CLI routing and lifecycle management for Windows components.
:: Mirroring component_core.sh with full argument parsing and schema integration.
::
:: ## Usage
:: Your component's `cli.cmd` should call this.
::
:: ```batch
:: @echo off
:: :: PACKAGE_NAME is inferred from directory name
:: :: (Optional: set "PACKAGE_NAME=nodejs" to override)
:: call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
:: ```

setlocal EnableDelayedExpansion

:: Identify directories
set "CALLER_FILE=%THIS_FILE%"
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "COMP_DIR="
if not "%CALLER_FILE%"=="" (
    for %%I in ("%CALLER_FILE%") do set "COMP_DIR=%%~dpI"
)
if "%COMP_DIR:~-1%"=="\" set "COMP_DIR=%COMP_DIR:~0,-1%"
if "%COMP_DIR%"=="" set "COMP_DIR=%CD%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    for %%I in ("%SCRIPT_DIR%\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
)

set "SCHEMA_FILE=%COMP_DIR%\vars.schema.json"
set "MANIFEST_FILE=%COMP_DIR%\manifest.json"
set "BASE_SCHEMA_FILE=%LIBSCRIPT_ROOT_DIR%\_lib\_common\base_vars.schema.json"

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

set "ACTION=%~1"
set "REQ_PKG=%~2"
set "VERSION=%~3"

:: Help / Version / Basic Routing
if "%ACTION%"=="" goto :show_help
if /i "%ACTION%"=="help" goto :show_help
if /i "%ACTION%"=="--help" goto :show_help
if /i "%ACTION%"=="-h" goto :show_help
if /i "%ACTION%"=="/?" goto :show_help

if /i "%ACTION%"=="--version" (
    echo %LIBSCRIPT_VERSION%
    exit /b 0
)
if /i "%ACTION%"=="-v" (
    echo %LIBSCRIPT_VERSION%
    exit /b 0
)

:: Validate Required Args
if "!REQ_PKG!"=="" (
    call "%LOG_CMD%" :log_error "package_name is required for !ACTION!"
    exit /b 1
)

:: Auto-set component version variable (e.g. NODEJS_VERSION)
set "pkg_up=!PACKAGE_NAME!"
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
if not "!VERSION!"=="" (
    set "!pkg_up!_VERSION=!VERSION!"
    set "LIBSCRIPT_VERSION=!VERSION!"
)

:: Shift initial args
shift & shift & shift

:: Argument Parsing Loop
:: ## parse_loop
:: Executes parse_loop functionality.
:parse_loop
set "arg=%~1"
if "!arg!"=="" goto :routing

:: Skip parsing for certain actions that pass-through
if /i "!ACTION!"=="start"   goto :routing
if /i "!ACTION!"=="stop"    goto :routing
if /i "!ACTION!"=="restart" goto :routing
if /i "!ACTION!"=="status"  goto :routing
if /i "!ACTION!"=="run"     goto :routing
if /i "!ACTION!"=="env"     goto :routing
if /i "!ACTION!"=="exec"    goto :routing
if /i "!ACTION!"=="network" goto :routing
if /i "!ACTION!"=="firewall" goto :routing
if /i "!ACTION!"=="node"    goto :routing
if /i "!ACTION!"=="dns"     goto :routing
if /i "!ACTION!"=="ssh"     goto :routing
if /i "!ACTION!"=="cleanup" goto :routing
if /i "!ACTION!"=="backup"  goto :routing
if /i "!ACTION!"=="restore" goto :routing
if /i "!ACTION!"=="diff"    goto :routing

if "!arg:~0,2!"=="--" (
    set "key_val=!arg:~2!"
    for /f "tokens=1* delims==" %%A in ("!key_val!") do (
        set "key=%%A"
        set "val=%%B"
        if "!val!"=="" set "val=true"
        set "!key!=!val!"
        setx !key! "!val!" >nul 2>&1
    )
)

shift
goto :parse_loop

:: ## routing
:: Executes routing functionality.
:routing
:: Reconstruct missing positional arguments for special subcommands that bypass parsing
if /i "!ACTION!"=="network" set "bypass_args=1"
if /i "!ACTION!"=="firewall" set "bypass_args=1"
if /i "!ACTION!"=="node" set "bypass_args=1"
if /i "!ACTION!"=="dns" set "bypass_args=1"
if /i "!ACTION!"=="ssh" set "bypass_args=1"
if /i "!ACTION!"=="cleanup" set "bypass_args=1"

if "!bypass_args!"=="1" (
    set "ARG1=!REQ_PKG!"
    set "ARG2=!VERSION!"
    set "ARG3=%~1"
    set "ARG4=%~2"
    set "ARG5=%~3"
    set "ARG6=%~4"
) else (
    set "ARG1=%~1"
    set "ARG2=%~2"
    set "ARG3=%~3"
    set "ARG4=%~4"
    set "ARG5=%~5"
    set "ARG6=%~6"
)

:: Lifecycle Routing
if /i "!ACTION!"=="info" (
    if defined PREFIX (
        set "INSTALLED_DIR=!PREFIX!"
    ) else if defined LIBSCRIPT_HOME (
        set "INSTALLED_DIR=!LIBSCRIPT_HOME!\!PACKAGE_NAME!\!VERSION!"
    ) else (
        set "INSTALLED_DIR=%USERPROFILE%\.libscript\!PACKAGE_NAME!\!VERSION!"
    )
    echo Component: !PACKAGE_NAME!
    echo Version: !VERSION!
    echo Install Path: !INSTALLED_DIR!
    if exist "!INSTALLED_DIR!" (
        echo Status: Installed
    ) else (
        echo Status: Not Installed
    )
    exit /b 0
)

if /i "!ACTION!"=="env" (
    if not defined FORMAT set "FORMAT=cmd"
    if defined PREFIX (
        set "INSTALLED_DIR=!PREFIX!"
    ) else (
        set "INSTALLED_DIR=!LIBSCRIPT_ROOT_DIR!\installed\!PACKAGE_NAME!"
    )
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.sh" "!FORMAT!" "!INSTALLED_DIR!"
    exit /b !errorlevel!
)

if /i "!ACTION!"=="test" (
    set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%USERPROFILE%\.local\bin;!PATH!"
    for /d %%P in ("%LOCALAPPDATA%\Programs\Python\Python*") do set "PATH=%%P;%%P\Scripts;!PATH!"
    for /d %%P in ("%ProgramFiles%\Python*") do set "PATH=%%P;%%P\Scripts;!PATH!"
    if exist "%LOCALAPPDATA%\Programs\Ollama" set "PATH=%LOCALAPPDATA%\Programs\Ollama;!PATH!"
    for /d %%L in ("%LOCALAPPDATA%\Programs\Lua*") do set "PATH=%%L\bin;!PATH!"
    if exist "%ProgramFiles%\7-Zip" set "PATH=%ProgramFiles%\7-Zip;!PATH!"
    if exist "%ProgramFiles%\CMake\bin" set "PATH=%ProgramFiles%\CMake\bin;!PATH!"
    if exist "%ProgramFiles%\Git\bin" set "PATH=%ProgramFiles%\Git\bin;!PATH!"
    if exist "%ProgramFiles%\Go\bin" set "PATH=%ProgramFiles%\Go\bin;!PATH!"
    if exist "%ProgramFiles%\nodejs" set "PATH=%ProgramFiles%\nodejs;!PATH!"
    if exist "%ProgramFiles%\dotnet" set "PATH=%ProgramFiles%\dotnet;!PATH!"
    for /d %%R in ("C:\Ruby*") do set "PATH=%%R\bin;!PATH!"
    for /d %%R in ("%ProgramFiles(x86)%\R\R-*") do set "PATH=%%R\bin;!PATH!"
    for /d %%R in ("%ProgramFiles%\R\R-*") do set "PATH=%%R\bin;!PATH!"
    if exist "C:\Strawberry\perl\bin" set "PATH=C:\Strawberry\perl\bin;C:\Strawberry\c\bin;!PATH!"
    for /d %%J in ("%ProgramFiles%\Eclipse Adoptium\jdk*") do set "PATH=%%J\bin;!PATH!"
    for /d %%E in ("%ProgramFiles%\Erlang*") do set "PATH=%%E\bin;!PATH!"
    if exist "%USERPROFILE%\.local\sbt\sbt\bin" set "PATH=%USERPROFILE%\.local\sbt\sbt\bin;!PATH!"
    if exist "%ProgramFiles%\sbt\bin" set "PATH=%ProgramFiles%\sbt\bin;!PATH!"
    if exist "%ProgramFiles(x86)%\sbt\bin" set "PATH=%ProgramFiles(x86)%\sbt\bin;!PATH!"
    for /d %%M in ("%ProgramFiles%\MariaDB*") do set "PATH=%%M\bin;!PATH!"
    for /d %%P in ("%ProgramFiles%\PostgreSQL\*") do set "PATH=%%P\bin;!PATH!"
    if exist "%ProgramFiles%\Redis" set "PATH=%ProgramFiles%\Redis;!PATH!"
    if exist "%JAVA_HOME%\bin" set "PATH=%JAVA_HOME%\bin;!PATH!"
    if exist "%ProgramFiles%\vfox" set "PATH=%ProgramFiles%\vfox;!PATH!"
    for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do set "PATH=%%S\usr\bin;!PATH!"
    for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do set "PATH=%%S\usr\bin;!PATH!"
    if exist "%ProgramFiles%\mosquitto" set "PATH=%ProgramFiles%\mosquitto;!PATH!"
    if exist "%ProgramFiles%\qemu" set "PATH=%ProgramFiles%\qemu;!PATH!"
    if exist "%ProgramFiles%\Oracle\VirtualBox" set "PATH=%ProgramFiles%\Oracle\VirtualBox;!PATH!"
    if exist "%ProgramFiles%\fluent-bit\bin" set "PATH=%ProgramFiles%\fluent-bit\bin;!PATH!"
    if exist "%ProgramFiles%\Amazon\AWSCLIV2" set "PATH=%ProgramFiles%\Amazon\AWSCLIV2;!PATH!"
    if exist "%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin" set "PATH=%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin;!PATH!"
    if exist "%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin" set "PATH=%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin;!PATH!"
    if exist "%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin" set "PATH=%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin;!PATH!"
    if exist "%ProgramFiles%\Microsoft SDKs\Azure\CLI2\wbin" set "PATH=%ProgramFiles%\Microsoft SDKs\Azure\CLI2\wbin;!PATH!"
    if exist "%ProgramFiles(x86)%\Microsoft SDKs\Azure\CLI2\wbin" set "PATH=%ProgramFiles(x86)%\Microsoft SDKs\Azure\CLI2\wbin;!PATH!"
    if exist "%ProgramFiles(x86)%\Yarn\bin" set "PATH=%ProgramFiles(x86)%\Yarn\bin;!PATH!"
    if exist "%ProgramFiles%\Yarn\bin" set "PATH=%ProgramFiles%\Yarn\bin;!PATH!"
    if exist "%LOCALAPPDATA%\Yarn\bin" set "PATH=%LOCALAPPDATA%\Yarn\bin;!PATH!"
    if exist "%USERPROFILE%\.cargo\bin" set "PATH=%USERPROFILE%\.cargo\bin;!PATH!"
    if exist "%USERPROFILE%\.bun\bin" set "PATH=%USERPROFILE%\.bun\bin;!PATH!"
    if exist "%USERPROFILE%\.rye\shims" set "PATH=%USERPROFILE%\.rye\shims;!PATH!"
    if exist "%USERPROFILE%\scoop\shims" set "PATH=%USERPROFILE%\scoop\shims;!PATH!"
    if exist "%USERPROFILE%\vcpkg" set "PATH=%USERPROFILE%\vcpkg;!PATH!"
    if exist "%USERPROFILE%\.pyenv\pyenv-win\bin" set "PATH=%USERPROFILE%\.pyenv\pyenv-win\bin;%USERPROFILE%\.pyenv\pyenv-win\shims;!PATH!"
    if exist "%APPDATA%\nvm" set "PATH=%APPDATA%\nvm;!PATH!"
    if exist "%ProgramData%\chocolatey\bin" set "PATH=%ProgramData%\chocolatey\bin;!PATH!"
    for /d %%E in ("%ProgramData%\chocolatey\lib\Elixir*") do (
        if exist "%%E\tools\bin" set "PATH=%%E\tools\bin;!PATH!"
        if exist "%%E\bin" set "PATH=%%E\bin;!PATH!"
    )
    for /d %%W in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\*") do (
        set "PATH=%%W;!PATH!"
        for /d %%S in ("%%W\*") do (
            if exist "%%S\bin" set "PATH=%%S\bin;!PATH!"
        )
    )
    set "PATH=!PATH!;%LOCALAPPDATA%\Microsoft\WindowsApps"
    if defined LIBSCRIPT_HOME (
        set "PKG_HOME=!LIBSCRIPT_HOME!\!PACKAGE_NAME!"
    ) else (
        set "PKG_HOME=%USERPROFILE%\.libscript\!PACKAGE_NAME!"
    )
    if exist "!PKG_HOME!\!VERSION!\bin" set "PATH=!PKG_HOME!\!VERSION!\bin;!PATH!"
    if exist "!PKG_HOME!\latest\bin" set "PATH=!PKG_HOME!\latest\bin;!PATH!"
    if exist "!PKG_HOME!\!VERSION!" set "PATH=!PKG_HOME!\!VERSION!;!PATH!"
    if exist "!PKG_HOME!\latest" set "PATH=!PKG_HOME!\latest;!PATH!"

    if exist "%COMP_DIR%\test.cmd" (
        call "%COMP_DIR%\test.cmd"
    ) else if exist "%COMP_DIR%\test.ps1" (
        powershell -ExecutionPolicy Bypass -File "%COMP_DIR%\test.ps1"
    ) else (
        echo Error: test.cmd/ps1 not found in %COMP_DIR% 1>&2
        exit /b 1
    )
    exit /b !errorlevel!
)

if /i "!ACTION!"=="uninstall" set "ACTION=remove"
if /i "!ACTION!"=="remove" (
    if exist "%COMP_DIR%\uninstall.cmd" (
        call "%COMP_DIR%\uninstall.cmd"
    ) else if exist "%COMP_DIR%\uninstall.ps1" (
        powershell -ExecutionPolicy Bypass -File "%COMP_DIR%\uninstall.ps1"
    ) else (
        echo Error: uninstall.cmd/ps1 not found in %COMP_DIR% 1>&2
        exit /b 1
    )
    exit /b !errorlevel!
)

:: Default to setup.cmd
if exist "%COMP_DIR%\setup.cmd" (
    call "%COMP_DIR%\setup.cmd"
) else if exist "%COMP_DIR%\setup.sh" (
    REM Fallback to WSL/GitBash if setup.sh exists? No, keep it native for now.
    echo Error: setup.cmd not found in %COMP_DIR% 1>&2
    exit /b 1
)
exit /b !errorlevel!

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: cli.cmd [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]
echo.
echo Commands:
echo   install, remove, uninstall, test, status, start, stop, restart, env, run, exec
echo.
if exist "%MANIFEST_FILE%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%A in ('jq -r "if .title and .description then .title + \": \" + .description elif .title then .title elif .description then .description else \"\" end" "%MANIFEST_FILE%"') do (
            if not "%%A"=="" echo   %%A
        )
        for /f "delims=" %%A in ('jq -r "if .versions then \"Supported Versions: \" + (.versions | join(\", \")) else \"\" end" "%MANIFEST_FILE%"') do (
            if not "%%A"=="" echo   %%A
        )
    )
)
echo.
echo Available Options:
where jq >nul 2>&1
if !errorlevel! equ 0 (
    if exist "%SCHEMA_FILE%" (
        jq -n --slurpfile base "%BASE_SCHEMA_FILE%" --slurpfile comp "%SCHEMA_FILE%" "($base[0].properties // {}) * ($comp[0].properties // {}) | to_entries[] | \"  --\" + .key + \"=\" + (.value.default // \"none\") + \"\t\" + .value.description" 2>nul
    )
) else (
    echo   ^(jq is required for dynamic options list^)
)
exit /b 0
