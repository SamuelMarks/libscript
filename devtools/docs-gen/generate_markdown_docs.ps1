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

# ## Normalize-MarkdownSection
# Normalizes a Markdown table or list block so Prettier column-padding and blank-line differences are ignored when checking if semantic content changed.
function Normalize-MarkdownSection {
    param([string]$Block)
    $out = @()
    $prose = ""
    foreach ($rawLine in ($Block -split "`r?`n")) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrEmpty($line)) {
            if ($prose -ne "") { $out += $prose; $prose = "" }
            continue
        }
        if ($line -match '^\|[\s\-:|]+\|$') {
            if ($prose -ne "") { $out += $prose; $prose = "" }
            $out += '|---|---|---|---|'
        } elseif ($line.StartsWith('|') -and $line.EndsWith('|')) {
            if ($prose -ne "") { $out += $prose; $prose = "" }
            $inner = $line.Substring(1, $line.Length - 2)
            $cells = ($inner -split '\|') | ForEach-Object { $_.Trim() }
            $out += ('| ' + ($cells -join ' | ') + ' |')
        } elseif ($line -match '^[-*#><]') {
            if ($prose -ne "") { $out += $prose; $prose = "" }
            $out += $line
        } else {
            $prose = if ($prose -eq "") { $line } else { "$prose $line" }
        }
    }
    if ($prose -ne "") { $out += $prose }
    return ($out -join "`n")
}

# ## Convert-SchemaPropertiesToRows
# Extracts Markdown table rows from a parsed JSON schema's properties object.
function Convert-SchemaPropertiesToRows {
    param($SchemaObj)
    $rows = @()
    if ($null -ne $SchemaObj -and $null -ne $SchemaObj.properties) {
        foreach ($p in $SchemaObj.properties.psobject.properties) {
            $key = $p.Name
            $val = $p.Value
            $desc = if ($val.description) { ($val.description -replace "`r?`n", " ") } else { "" }
            $def = if ($null -ne $val.default -and ($val.default -isnot [bool] -or $val.default -eq $true)) {
                if ($val.default -is [bool]) { "true" }
                elseif ($val.default -is [array]) { if ($val.default.Count -eq 0) { "none" } else { ConvertTo-Json -InputObject $val.default -Compress } }
                elseif ($val.default -is [System.Management.Automation.PSCustomObject]) { ConvertTo-Json -InputObject $val.default -Compress }
                else { [string]$val.default }
            } else { "none" }
            $aliases = @()
            if ($val.deprecated_aliases) { $aliases += $val.deprecated_aliases }
            if ($val.version_aliases) { $aliases += $val.version_aliases }
            if ($val.examples) { $aliases += $val.examples }
            $aliasStr = $aliases -join ", "
            $rows += "| ``$key`` | $desc | ``$def`` | $aliasStr |"
        }
    }
    return $rows
}

$rootDir = if ($env:ROOT_DIR) { (Resolve-Path $env:ROOT_DIR).Path } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }

# Ensure markers exist
$injectScript = Join-Path $PSScriptRoot 'inject_markers.ps1'
if (Test-Path -LiteralPath $injectScript) {
    & $injectScript
}

Write-Host "Generating markdown docs..."

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$libDir = Join-Path $rootDir '_lib'
$topologiesDir = Join-Path $rootDir 'topologies'
$payloadsDir = Join-Path $rootDir 'payloads'
$libReadmes = if (Test-Path -LiteralPath $libDir) {
    Get-ChildItem -Path $libDir -Filter 'README.md' -Recurse -Depth 2 | Where-Object {
        ($_.DirectoryName -notmatch '[/\\]_lib[/\\]_common([/\\]|$)') -and (Test-Path -LiteralPath (Join-Path $_.DirectoryName 'vars.schema.json'))
    }
} else { @() }
$topoReadmes = if (Test-Path -LiteralPath $topologiesDir) {
    Get-ChildItem -Path $topologiesDir -Filter 'README.md' -Recurse -Depth 2 | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.DirectoryName 'vars.schema.json')
    }
} else { @() }
$payloadReadmes = if (Test-Path -LiteralPath $payloadsDir) {
    Get-ChildItem -Path $payloadsDir -Filter 'README.md' -Recurse -Depth 2 | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.DirectoryName 'vars.schema.json')
    }
} else { @() }
$readmes = @($libReadmes) + @($topoReadmes) + @($payloadReadmes)

$baseSchema = Join-Path $rootDir '_lib\_common\base_vars.schema.json'
$baseVarRows = @()
if (Test-Path -LiteralPath $baseSchema) {
    $baseJson = [System.IO.File]::ReadAllText($baseSchema, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $baseVarRows = Convert-SchemaPropertiesToRows -SchemaObj $baseJson
}

$platLines = @(
    "- Linux",
    "- macOS",
    "- Windows"
)
$platBlock = ($platLines -join "`n") + "`n"
$platNorm = Normalize-MarkdownSection -Block $platBlock
$varsRegex = [regex]'(?is)(<!-- BEGIN_VARS -->)(.*?)(<!-- END_VARS -->)'
$platRegex = [regex]'(?is)(<!-- BEGIN_PLATFORMS -->)(.*?)(<!-- END_PLATFORMS -->)'

$modifiedReadmes = @()
foreach ($readme in $readmes) {
    $dir = $readme.DirectoryName
    $schema = Join-Path $dir 'vars.schema.json'

    $varsLines = @(
        "| Variable | Description | Default | Aliases/Examples |",
        "|---|---|---|---|"
    )

    $json = [System.IO.File]::ReadAllText($schema, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($null -ne $json.'x-libscript-var-packs') {
        foreach ($pk in @($json.'x-libscript-var-packs')) {
            $pkFile = Join-Path $rootDir "schemas\vars\$pk.schema.json"
            if (Test-Path -LiteralPath $pkFile) {
                $pkJson = [System.IO.File]::ReadAllText($pkFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
                $pkRows = Convert-SchemaPropertiesToRows -SchemaObj $pkJson
                if ($pkRows.Count -gt 0) {
                    $varsLines += $pkRows
                }
            }
        }
    }

    $compRows = Convert-SchemaPropertiesToRows -SchemaObj $json
    if ($compRows.Count -gt 0) {
        $varsLines += $compRows
    }

    if ($dir.Contains('_lib')) {
        $varsLines += ""
        $varsLines += "Global framework variables (such as ``LIBSCRIPT_HOME``, ``LIBSCRIPT_CACHE_DIR``, ``LIBSCRIPT_OFFLINE``, and ``LIBSCRIPT_DEFAULT_INSTALL_METHOD``) are documented in ``_lib/_common/README.md``."
    }

    $varsBlock = ($varsLines -join "`n") + "`n"
    $varsNorm = Normalize-MarkdownSection -Block $varsBlock

    $oldContent = [System.IO.File]::ReadAllText($readme.FullName, [System.Text.Encoding]::UTF8)
    $content = $oldContent
    $needsUpdate = $false

    $varsMatch = $varsRegex.Match($content)
    if ($varsMatch.Success) {
        $existingVarsNorm = Normalize-MarkdownSection -Block $varsMatch.Groups[2].Value
        if ($existingVarsNorm -ne $varsNorm) {
            $content = $varsRegex.Replace($content, { param($m) "$($m.Groups[1].Value)`n$varsBlock$($m.Groups[3].Value)" }, 1)
            $needsUpdate = $true
        }
    }

    $platMatch = $platRegex.Match($content)
    if ($platMatch.Success) {
        $existingPlatNorm = Normalize-MarkdownSection -Block $platMatch.Groups[2].Value
        if ($existingPlatNorm -ne $platNorm) {
            $content = $platRegex.Replace($content, { param($m) "$($m.Groups[1].Value)`n$platBlock$($m.Groups[3].Value)" }, 1)
            $needsUpdate = $true
        }
    }

    if ($needsUpdate -and ($content -ne $oldContent)) {
        $lfContent = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($readme.FullName, $lfContent, $utf8NoBom)
        $modifiedReadmes += $readme.FullName
    }
}

if ($modifiedReadmes.Count -gt 0) {
    $localPrettier = Join-Path $rootDir 'node_modules\.bin\prettier.cmd'
    $hasPrettierCmd = $null -ne (Get-Command prettier -ErrorAction SilentlyContinue)
    $hasNpxCmd = $null -ne (Get-Command npx -ErrorAction SilentlyContinue)

    $prevErrPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        for ($i = 0; $i -lt $modifiedReadmes.Count; $i += 40) {
            $end = [Math]::Min($i + 39, $modifiedReadmes.Count - 1)
            $batch = [string[]]$modifiedReadmes[$i..$end]
            if ($hasPrettierCmd) {
                & prettier --write @batch >$null 2>&1
            } elseif (Test-Path -LiteralPath $localPrettier) {
                & $localPrettier --write @batch >$null 2>&1
            } elseif ($hasNpxCmd) {
                & npx --yes prettier --write @batch >$null 2>&1
            }
        }
    } finally {
        $ErrorActionPreference = $prevErrPref
    }

    foreach ($modFile in $modifiedReadmes) {
        if (Test-Path -LiteralPath $modFile) {
            $formatted = [System.IO.File]::ReadAllText($modFile, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n"
            [System.IO.File]::WriteAllText($modFile, $formatted, $utf8NoBom)
        }
    }
}

Write-Host "Done."
