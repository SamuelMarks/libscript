@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the just component on Windows.
:: It sets up necessary paths and environment variables required for the component
:: to function correctly within the libscript context.
::
:: ## Usage
:: Call this script to load the environment variables. Do not execute it directly without context.

if "%JUST_VERSION%"=="" set JUST_VERSION=latest
if "%JUST_VERSION%"=="latest" set JUST_VERSION=1.39.0
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\just\%JUST_VERSION%\bin;%PATH%
