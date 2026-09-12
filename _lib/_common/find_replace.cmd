@echo off
setlocal EnableDelayedExpansion
:: # LibScript Find and Replace Module (Windows Batch)
::
:: ## Overview
:: This module safely replaces strings in files without regex corruption.
::
:: ## Usage
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\find_replace.cmd" :find_replace "search" "replace" "file.txt"
:: ```

set "THIS_FILE=%~f0"

if not "%~1"=="" goto %~1
exit /b 0

:: ## find_replace
:: Executes find_replace functionality.
:find_replace
set "SEARCH=%~1"
set "REPLACE=%~2"
set "FILE=%~3"

if not exist "%FILE%" (
    echo Error: Cannot read file "%FILE%" >&2
    exit /b 1
)

powershell -NoProfile -Command "$content = [System.IO.File]::ReadAllText($env:FILE); $newContent = $content.Replace($env:SEARCH, $env:REPLACE); [Console]::Out.Write($newContent)"
exit /b 0
