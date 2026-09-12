@echo off
:: # inject_markers.cmd
::
:: ## Overview
:: Injects specific markers or tags into documentation files.
:: 
:: ## Usage
:: Execute this script to apply structural markers to docs.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Executes show_help functionality.
:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Injects specific markers or tags into documentation files.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes main functionality.
:main
:: ## main
:: Executes main functionality.
:: Injects <!-- BEGIN_VARS --> and <!-- BEGIN_PLATFORMS --> markers into
:: README.md files. Windows equivalent of inject_markers.sh

set "ROOT_DIR=%~dp0..\.."

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    $rootDir = Resolve-Path '%ROOT_DIR%';
    $libComps = Get-ChildItem -Path (Join-Path $rootDir '_lib') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne '_lib' };
    $stackComps = Get-ChildItem -Path (Join-Path $rootDir 'stacks') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne 'stacks' };
    $components = @($libComps) + @($stackComps);

    foreach ($comp in $components) {
        $readmePath = Join-Path $comp.FullName 'README.md';
        if (-Not (Test-Path $readmePath)) { continue; }

        $content = Get-Content $readmePath -Raw;
        $modified = $false;

        if ($content -notmatch '<!-- BEGIN_VARS -->') {
            $varsBlock = ""## Configuration Options`n`nThe following environment variables can be passed to the CLI (\`--KEY=VALUE\`) or exported before running the setup script.`n`n<!-- BEGIN_VARS -->`n<!-- END_VARS -->`n`n"";
            if ($content -match '(?i)## (Configuration Options|Variables|Environment Variables)') {
                $content = $content -replace '(?is)## (Configuration Options|Variables|Environment Variables).*?(?=^## |\Z)', $varsBlock;
            } elseif ($content -match '(?i)## Platform Support') {
                $content = $content -replace '(?is)(## Platform Support)', ($varsBlock + ""`$1"");
            } else {
                $content += ""`n"" + $varsBlock;
            }
            $modified = $true;
        }

        if ($content -notmatch '<!-- BEGIN_PLATFORMS -->') {
            $platBlock = ""## Platform Support`n`n<!-- BEGIN_PLATFORMS -->`n<!-- END_PLATFORMS -->`n`n"";
            if ($content -match '(?i)## Platform Support') {
                $content = $content -replace '(?is)## Platform Support.*?(?=^## |\Z)', $platBlock;
            } elseif ($content -match '(?i)## Orchestrated Components') {
                $content = $content -replace '(?is)(## Orchestrated Components)', ($platBlock + ""`$1"");
            } else {
                $content += ""`n"" + $platBlock;
            }
            $modified = $true;
        }

        if ($modified) {
            [IO.File]::WriteAllText($readmePath, $content, [Text.Encoding]::UTF8);
        }
    }
    Write-Host 'Markers injected.'
}"
exit /b %ERRORLEVEL%