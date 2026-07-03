@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Kotlin on Windows.
::
:: ## Usage
:: Sets `KOTLIN_VERSION` and prepends Kotlin to PATH.

if "%KOTLIN_VERSION%"=="" set KOTLIN_VERSION=1.9.20
if "%KOTLIN_VERSION%"=="latest" set KOTLIN_VERSION=1.9.20
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\kotlin\%KOTLIN_VERSION%\bin;%PATH%
