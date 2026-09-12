@echo off
setlocal EnableDelayedExpansion
:: # find_replace_exec.cmd
::
:: ## Overview
:: Windows Batch executable literal string replacer.
::
:: ## Usage
:: find_replace_exec "find" "replace" filename

set "THIS_FILE=%~f0"

if "%~3"=="" (
    echo Usage: find_replace_exec "find" "replace" filename >&2
    exit /b 1
)

set "SEARCH=%~1"
set "REPLACE=%~2"
set "FILE=%~3"

if not exist "%FILE%" (
    echo Error: Cannot read file "%FILE%" >&2
    exit /b 1
)

powershell -NoProfile -Command "$content = [System.IO.File]::ReadAllText($env:FILE); $newContent = $content.Replace($env:SEARCH, $env:REPLACE); [Console]::Out.Write($newContent)"
exit /b 0
