@echo off
:: # git.cmd
::
:: ## Overview
:: Common Git manipulation utilities for Windows batch.
::
:: ## Usage
:: Provides :git_get <repo> <target> [branch] for idempotent repo cloning/pulling.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if not "%~1"=="" (
    call :%*
    exit /b %errorlevel%
)
exit /b 0

:: ## git_get
:: Executes git_get functionality.
:git_get
set "repo=%~1"
set "target=%~2"
set "branch=%~3"

if "%target%"=="" exit /b 1

set "GIT_DIR_=%target%\.git"
if exist "%GIT_DIR_%" (
    if not "%branch%"=="" (
        git --git-dir="%GIT_DIR_%" --work-tree="%target%" fetch origin "%branch%":"%branch%"
    ) else (
        git --git-dir="%GIT_DIR_%" --work-tree="%target%" pull --ff-only
    )
) else (
    if not exist "%target%" mkdir "%target%"
    if not "%branch%"=="" (
        git clone --depth=1 --single-branch --branch "%branch%" "%repo%" "%target%"
    ) else (
        git clone --depth=1 --single-branch "%repo%" "%target%"
    )
)
exit /b %errorlevel%
