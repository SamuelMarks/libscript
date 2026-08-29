@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for C# on Windows.
::
:: ## Usage
:: Sets `DOTNET_ROOT` and prepends it to PATH.
set "THIS_FILE=%~f0"

if "%CSHARP_VERSION%"=="" set CSHARP_VERSION=latest
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set DOTNET_ROOT=%LIBSCRIPT_HOME%\csharp\%CSHARP_VERSION%
set PATH=%DOTNET_ROOT%;%PATH%
