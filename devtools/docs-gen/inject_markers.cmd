@echo off
setlocal EnableDelayedExpansion

:: Injects <!-- BEGIN_VARS --> and <!-- BEGIN_PLATFORMS --> markers into
:: README.md files. Windows equivalent of inject_markers.sh

set "ROOT_DIR=%~dp0..\.."

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    $rootDir = Resolve-Path '%ROOT_DIR%';
    $components = Get-ChildItem -Path (Join-Path $rootDir '_lib') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne '_lib' };

    foreach ($comp in $components) {
        $readmePath = Join-Path $comp.FullName 'README.md';
        if (-Not (Test-Path $readmePath)) { continue; }

        $content = Get-Content $readmePath -Raw;
        $modified = $false;

        if ($content -notmatch '<!-- BEGIN_VARS -->') {
            if ($content -match '(?i)## Configuration Options') {
                $content = $content -replace '(?is)## Configuration Options.*?(?=^## |\Z)', ""## Configuration Options`n`nThe following environment variables can be passed to the CLI (\`--KEY=VALUE\`) or exported before running the setup script.`n`n<!-- BEGIN_VARS -->`n<!-- END_VARS -->`n`n"";
            } else {
                $content += ""`n## Configuration Options`n`n<!-- BEGIN_VARS -->`n<!-- END_VARS -->`n"";
            }
            $modified = $true;
        }

        if ($content -notmatch '<!-- BEGIN_PLATFORMS -->') {
            if ($content -match '(?i)## Platform Support') {
                $content = $content -replace '(?is)## Platform Support.*?(?=^## |\Z)', ""## Platform Support`n`n<!-- BEGIN_PLATFORMS -->`n<!-- END_PLATFORMS -->`n`n"";
            } else {
                $content += ""`n## Platform Support`n`n<!-- BEGIN_PLATFORMS -->`n<!-- END_PLATFORMS -->`n"";
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