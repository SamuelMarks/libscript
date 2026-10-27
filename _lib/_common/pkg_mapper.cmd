@echo off
:: # pkg_mapper.cmd
::
:: ## Overview
:: Cross-platform package name translation dictionary across native OS package managers.
::
:: ## Usage
:: Maps generic dependency names to platform-specific package identifiers.

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

:: ## Labels
::
:: ### :map_package <generic_name>
:: Maps the provided generic name to a manager-specific ID.
::
:: Parameters:
::   %~2 - Generic package name (e.g., 'git', 'nodejs', 'php')
::
:: Returns:
::   MAPPED_PKG - The resulting package ID(s).
::   errorlevel - 0 if mapping found, 1 if not supported.


:: Prevent accidental direct execution
set "THIS_FILE=%~f0"
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :map_package <generic_name>
:: -----------------------------------------------------------------------------
:: ## map_package
:: Translates a generic package identifier into the native OS package manager name.
:map_package
set "PKG=%~2"
set "MAPPED_PKG="

:: Default PKG_MGR to winget if not defined, as it's built into modern Windows
if "!PKG_MGR!"=="" set "PKG_MGR=winget"

:: --- Mapping Logic ---
:: This follows the patterns established in pkg_mapper.sh

if "!PKG!"=="bun" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oven-sh.Bun"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=bun"
) else if "!PKG!"=="postgres" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PostgreSQL.PostgreSQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=postgresql"
) else if "!PKG!"=="postgresql" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PostgreSQL.PostgreSQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=postgresql"
) else if "!PKG!"=="mariadb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MariaDB.MariaDB"
) else if "!PKG!"=="c_compiler" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="cpp_compiler" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="gcc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=gcc"
) else if "!PKG!"=="g++" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=gcc"
) else if "!PKG!"=="clang" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="llvm" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="lld" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="tcc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Bellard.TCC"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=tcc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tcc"
) else if "!PKG!"=="tinycc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Bellard.TCC"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=tcc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tcc"
) else if "!PKG!"=="binutils" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="flex" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=WinFlexBison.win_flex_bison"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=winflexbison3"
) else if "!PKG!"=="bison" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=WinFlexBison.win_flex_bison"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=winflexbison3"
) else if "!PKG!"=="zstd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Facebook.zstd"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=zstandard"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=zstd"
) else if "!PKG!"=="sqlite" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SQLite.SQLite"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=sqlite3"
) else if "!PKG!"=="sqlite3" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SQLite.SQLite"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=sqlite3"
) else if "!PKG!"=="make" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Make"
) else if "!PKG!"=="git" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Git.Git"
) else if "!PKG!"=="curl" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=cURL.cURL"
) else if "!PKG!"=="tar" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Tar"
) else if "!PKG!"=="unzip" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Info-ZIP.UnZip"
) else if "!PKG!"=="csharp" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.DotNet.SDK.8"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=dotnet-8.0-sdk"
) else if "!PKG!"=="deno" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=DenoLand.Deno"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=deno"
) else if "!PKG!"=="go" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GoLang.Go"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=golang"
) else if "!PKG!"=="java" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.OpenJDK.17"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=openjdk"
) else if "!PKG!"=="jq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=jqlang.jq"
) else if "!PKG!"=="kotlin" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=JetBrains.Kotlin"
) else if "!PKG!"=="nodejs" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OpenJS.NodeJS"
) else if "!PKG!"=="php" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PHP.PHP"
) else if "!PKG!"=="python" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Python.Python.3.11"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=python3"
) else if "!PKG!"=="ruby" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RubyInstallerTeam.Ruby"
) else if "!PKG!"=="rust" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Rustlang.Rustup"
) else if "!PKG!"=="httpd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
) else if "!PKG!"=="apache2" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
) else if "!PKG!"=="caddy" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=caddy.caddy"
) else if "!PKG!"=="nginx" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Nginx.Nginx"
) else if "!PKG!"=="etcd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=etcd.etcd"
) else if "!PKG!"=="rabbitmq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RabbitMQ.RabbitMQ"
) else if "!PKG!"=="memcached" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=memcached"
) else if "!PKG!"=="mysql" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.MySQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mysql"
) else if "!PKG!"=="mysql-server" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.MySQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mysql"
) else if "!PKG!"=="mysql-client" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.MySQL"
) else if "!PKG!"=="geos" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OSGeo.GEOS"
) else if "!PKG!"=="gettext" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GNU.Gettext"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=gettext"
) else if "!PKG!"=="graphviz" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Graphviz.Graphviz"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=graphviz"
)

:: If no mapping found, return the original name
if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!PKG!"

:: End with MAPPED_PKG available to caller
endlocal & set "MAPPED_PKG=%MAPPED_PKG%"
exit /b 0
