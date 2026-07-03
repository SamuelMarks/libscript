@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Elixir on Windows.
::
:: ## Usage
:: Sets `ELIXIR_VERSION` and prepends Elixir to PATH.

if "%ELIXIR_VERSION%"=="" set ELIXIR_VERSION=1.16.2
if "%ELIXIR_VERSION%"=="latest" set ELIXIR_VERSION=1.16.2
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\elixir\%ELIXIR_VERSION%\bin;%PATH%
