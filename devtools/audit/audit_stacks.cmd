@echo off
setlocal EnableDelayedExpansion

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