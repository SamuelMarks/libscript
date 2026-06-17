@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%~dp0..\.."

:: Ensure markers exist
set "ROOT_DIR_FOR_INJECT=%ROOT_DIR%"
call "%SCRIPT_DIR%inject_markers.cmd"

echo Generating markdown docs...

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $rootDir = Resolve-Path '%ROOT_DIR%'; $readmes = Get-ChildItem -Path $rootDir -Filter 'README.md' -Recurse | Where-Object { $_.FullName -match '(_lib|app-servers|stacks)' }; foreach ($readme in $readmes) { $dir = $readme.DirectoryName; $schema = Join-Path $dir 'vars.schema.json'; if (Test-Path $schema) { $varsTmp = New-TemporaryFile; $platTmp = New-TemporaryFile; Add-Content $varsTmp '| Variable | Description | Default | Aliases/Examples |'; Add-Content $varsTmp '|---|---|---|---|'; $baseSchema = Join-Path $rootDir '_lib\_common\base_vars.schema.json'; if ($dir -match '_lib[/\\]' -and (Test-Path $baseSchema)) { $json = Get-Content $baseSchema | ConvertFrom-Json; if ($json.properties) { foreach ($p in $json.properties.psobject.properties) { $key = $p.Name; $val = $p.Value; $desc = if ($val.description) { $val.description } else { '' }; $def = if ($val.default) { $val.default } else { 'none' }; $aliases = @(); if ($val.version_aliases) { $aliases += $val.version_aliases }; if ($val.examples) { $aliases += $val.examples }; $aliasStr = $aliases -join ', '; Add-Content $varsTmp \"| ``$key`` | $desc | ``$def`` | $aliasStr |\" } } } $json = Get-Content $schema | ConvertFrom-Json; if ($json.properties) { foreach ($p in $json.properties.psobject.properties) { $key = $p.Name; $val = $p.Value; $desc = if ($val.description) { $val.description } else { '' }; $def = if ($val.default) { $val.default } else { 'none' }; $aliases = @(); if ($val.version_aliases) { $aliases += $val.version_aliases }; if ($val.examples) { $aliases += $val.examples }; $aliasStr = $aliases -join ', '; Add-Content $varsTmp \"| ``$key`` | $desc | ``$def`` | $aliasStr |\" } } Add-Content $platTmp '- Linux'; Add-Content $platTmp '- macOS'; Add-Content $platTmp '- Windows'; $content = Get-Content $readme.FullName -Raw; $varsContent = Get-Content $varsTmp -Raw; $content = $content -replace '(?is)(<!-- BEGIN_VARS -->).*?(<!-- END_VARS -->)', \"`$1`n$varsContent`n`$2\"; $platContent = Get-Content $platTmp -Raw; $content = $content -replace '(?is)(<!-- BEGIN_PLATFORMS -->).*?(<!-- END_PLATFORMS -->)', \"`$1`n$platContent`n`$2\"; [IO.File]::WriteAllText($readme.FullName, $content, [Text.Encoding]::UTF8); Remove-Item $varsTmp; Remove-Item $platTmp; } } }"

echo Done.
exit /b %ERRORLEVEL%