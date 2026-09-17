@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the Actix+Diesel authentication scaffold stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for serve-actix-diesel-auth-scaffold.

:: Environment variables for Windows
set "THIS_FILE=%~f0"
if "%SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST%"=="" set "SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST=%TEMP%\serve-actix-diesel-auth-scaffold\serve-actix-diesel-auth-scaffold"
if "%SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR%"=="" set "SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR=%TEMP%\serve-actix-diesel-auth-scaffold\serve-actix-diesel-auth-scaffold"
