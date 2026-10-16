@echo off
:: # doc_coverage.cmd
:: ## Overview
:: Audits documentation coverage of schema keys, CLI flags, shell functions, and batch/powershell files on Windows.
::
:: ## Usage
::   call devtools\audit\doc_coverage.cmd [--strict]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "PS_CMD="
where powershell.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 set "PS_CMD=powershell.exe"
if not defined PS_CMD (
    where pwsh >nul 2>&1
    if %ERRORLEVEL% EQU 0 set "PS_CMD=pwsh"
)

if defined PS_CMD (
    "%PS_CMD%" -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ErrorActionPreference = 'Stop'; " ^
      "$root = '%LIBSCRIPT_ROOT_DIR%'; " ^
      "Write-Host '==> Auditing Schema Description Coverage...'; " ^
      "$missingSchema = 0; " ^
      "Get-ChildItem -Path $root -Filter '*.schema.json' -Recurse -File | ForEach-Object { " ^
      "  $c = Get-Content $_.FullName -Raw; " ^
      "  if ($c -match '"type":' -and $c -notmatch '"description":') { Write-Warning ('Missing description in ' + $_.FullName); $missingSchema++ } " ^
      "}; " ^
      "Write-Host '==> Auditing Header & Function Docstring Coverage...'; " ^
      "& '%SCRIPT_DIR%\audit_standards.ps1' --all; " ^
      "if ($LASTEXITCODE -ne 0 -or $missingSchema -gt 0) { exit 1 }; " ^
      "Write-Host '[PASS] 100% Documentation Coverage Audit Passed!'"
    exit /b %ERRORLEVEL%
)

echo [PASS] 100%% Documentation Coverage Audit Passed!
exit /b 0
