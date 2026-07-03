@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Zig on Windows.
::
:: ## Usage
:: Sets `ZIG_VERSION` and prepends Zig to PATH.

if "%ZIG_VERSION%"=="" set ZIG_VERSION=0.12.0
if "%ZIG_VERSION%"=="latest" set ZIG_VERSION=0.12.0
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\zig\%ZIG_VERSION%;%PATH%
