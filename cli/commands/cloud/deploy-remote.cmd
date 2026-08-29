@echo off
:: # deploy-remote.cmd
::
:: ## Overview
:: Orchestrates idempotent deployment of multiple apps to a remote host.
:: 
:: ## Usage
:: Execute this script to deploy applications and configure shared databases.
:: Syntax: deploy-remote <user@host> [--app <path>@<domain>]... [--shared-db <engine>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
shift
call "%~dp0..\..\..\_lib\cloud\core\deploy_remote.cmd" %*
goto :eof
