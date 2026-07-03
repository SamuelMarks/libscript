@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the coursier component on Windows.
:: It sets up necessary paths and environment variables required for the component
:: to function correctly within the libscript context.
::
:: ## Usage
:: Call this script to load the environment variables. Do not execute it directly without context.

if "%COURSIER_VERSION%"=="" set COURSIER_VERSION=latest
if "%COURSIER_VERSION%"=="latest" set COURSIER_VERSION=2.1.24
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\coursier\%COURSIER_VERSION%\bin;%PATH%
