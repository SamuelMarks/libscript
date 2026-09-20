# ## Overview
# Generates markdown documentation for the libscript codebase.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for generate_markdown_docs.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: generate_markdown_docs.ps1"
    Write-Host "Generates markdown documentation for the libscript codebase."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --help, -h, /?, -?  Show this help message."
    exit 0
}

$rootDir = if ($env:ROOT_DIR) { Resolve-Path $env:ROOT_DIR } else { Resolve-Path (Join-Path $PSScriptRoot '..\..') }

# Ensure markers exist
$injectScript = Join-Path $PSScriptRoot 'inject_markers.ps1'
if (Test-Path $injectScript) {
    & $injectScript
}

Write-Host "Generating markdown docs..."

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$libReadmes = Get-ChildItem -Path (Join-Path $rootDir '_lib') -Filter 'README.md' -Recurse -Depth 2 | Where-Object {
    Test-Path (Join-Path $_.DirectoryName 'vars.schema.json')
}
$stackReadmes = Get-ChildItem -Path (Join-Path $rootDir 'stacks') -Filter 'README.md' -Recurse -Depth 2 | Where-Object {
    Test-Path (Join-Path $_.DirectoryName 'vars.schema.json')
}
$readmes = @($libReadmes) + @($stackReadmes)

$baseSchema = Join-Path $rootDir '_lib\_common\base_vars.schema.json'

$modifiedReadmes = @()
foreach ($readme in $readmes) {
    $dir = $readme.DirectoryName
    $schema = Join-Path $dir 'vars.schema.json'

    $varsLines = @(
        "| Variable | Description | Default | Aliases/Examples |",
        "|---|---|---|---|"
    )

    if ($dir.Contains('_lib') -and (Test-Path $baseSchema)) {
        $json = Get-Content $baseSchema -Raw | ConvertFrom-Json
        if ($json.properties) {
            foreach ($p in $json.properties.psobject.properties) {
                $key = $p.Name
                $val = $p.Value
                $desc = if ($val.description) { ($val.description -replace "`r?`n", " ") } else { "" }
                $def = if ($null -ne $val.default -and "" -ne $val.default) { $val.default } else { "none" }
                $aliases = @()
                if ($val.version_aliases) { $aliases += $val.version_aliases }
                if ($val.examples) { $aliases += $val.examples }
                $aliasStr = $aliases -join ", "
                $varsLines += "| ``$key`` | $desc | ``$def`` | $aliasStr |"
            }
        }
    }

    $json = Get-Content $schema -Raw | ConvertFrom-Json
    if ($json.properties) {
        foreach ($p in $json.properties.psobject.properties) {
            $key = $p.Name
            $val = $p.Value
            $desc = if ($val.description) { ($val.description -replace "`r?`n", " ") } else { "" }
            $def = if ($null -ne $val.default -and "" -ne $val.default) { $val.default } else { "none" }
            $aliases = @()
            if ($val.version_aliases) { $aliases += $val.version_aliases }
            if ($val.examples) { $aliases += $val.examples }
            $aliasStr = $aliases -join ", "
            $varsLines += "| ``$key`` | $desc | ``$def`` | $aliasStr |"
        }
    }

    $platLines = @(
        "- Linux",
        "- macOS",
        "- Windows"
    )

    $varsBlock = ($varsLines -join "`n") + "`n"
    $platBlock = ($platLines -join "`n") + "`n"

    $oldContent = Get-Content $readme.FullName -Raw
    $content = $oldContent -replace '(?is)(<!-- BEGIN_VARS -->).*?(<!-- END_VARS -->)', "`$1`n$varsBlock`$2"
    $content = $content -replace '(?is)(<!-- BEGIN_PLATFORMS -->).*?(<!-- END_PLATFORMS -->)', "`$1`n$platBlock`$2"

    if ($content -ne $oldContent) {
        [IO.File]::WriteAllText($readme.FullName, $content, $utf8NoBom)
        $modifiedReadmes += $readme.FullName
    }
}

if ($modifiedReadmes.Count -gt 0 -and (Get-Command npx -ErrorAction SilentlyContinue)) {
    & npx --yes prettier --write $modifiedReadmes >$null 2>&1
}

Write-Host "Done."
