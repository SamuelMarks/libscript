@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the maven component on Windows.
:: It sets up necessary paths and environment variables required for the component
:: to function correctly within the libscript context.
::
:: ## Usage
:: Call this script to load the environment variables. Do not execute it directly without context.

if "%MAVEN_VERSION%"=="" set MAVEN_VERSION=latest
if "%MAVEN_VERSION%"=="latest" set MAVEN_VERSION=3.9.6
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\maven\%MAVEN_VERSION%\bin;%PATH%
