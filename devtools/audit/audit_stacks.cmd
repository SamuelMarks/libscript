@echo off
:: # audit_stacks.cmd
::
:: ## Overview
:: Performs an audit and validation of all defined application stacks.
:: 
:: ## Usage
:: Execute this script to check the integrity of stack definitions.

setlocal EnableDelayedExpansion

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Performs an audit and validation of all defined application stacks.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:main
:: ## main
:: Executes main functionality.
:: Audits stack documentation. Windows equivalent of audit_stacks.sh

set "ROOT_DIR=%~dp0..\.."

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    $rootDir = Resolve-Path '%ROOT_DIR%';
    $stacks = Get-ChildItem -Path (Join-Path $rootDir 'stacks') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne 'stacks' };

    foreach ($stack in $stacks) {
        $readmePath = Join-Path $stack.FullName 'README.md';
        
        if (-Not (Test-Path $readmePath)) {
            Write-Host ""WARNING: Stack $($stack.Name) is missing a README.md"";
            continue;
        }

        $content = Get-Content $readmePath -Raw;

        if ($content -notmatch '(?i)components' -and $content -notmatch '(?i)orchestrates' -and $content -notmatch '(?i)libscript\.json') {
            Write-Host ""WARNING: Stack $($stack.Name) README may not explicitly list orchestrated _lib components or libscript.json usage."";
            
            if ($content -notmatch '(?i)## Orchestrated Components') {
                $content += ""`n## Orchestrated Components`nThis stack orchestrates the following LibScript components:`n- (Please document required components here)`n"";
                [IO.File]::WriteAllText($readmePath, $content, [Text.Encoding]::UTF8);
            }
        }
    }
    Write-Host 'Stack audit complete.'
}"
exit /b %ERRORLEVEL%