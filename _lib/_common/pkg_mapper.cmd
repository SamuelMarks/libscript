@echo off
:: # LibScript Package Mapper Module (Windows Batch)
::
:: ## Overview
:: This module translates generic package names (e.g., 'php', 'postgres') into 
:: specific package IDs used by Windows package managers (winget, choco, scoop).
:: It mirrors the logic in `pkg_mapper.sh` to ensure cross-platform consistency.
::
:: ## Usage
:: Call the `:map_package` label with the generic package name and the package manager.
:: The result is returned in the `MAPPED_PKG` environment variable.
::
:: Example:
::   set "PKG_MGR=winget"
::   call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mapper.cmd" :map_package "php"
::   echo Mapped package: %MAPPED_PKG%
::
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

setlocal EnableDelayedExpansion

:: Prevent accidental direct execution
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :map_package <generic_name>
:: -----------------------------------------------------------------------------
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
) else if "!PKG!"=="g++" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
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
)

:: If no mapping found, return the original name
if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!PKG!"

:: End with MAPPED_PKG available to caller
endlocal & set "MAPPED_PKG=%MAPPED_PKG%"
exit /b 0
