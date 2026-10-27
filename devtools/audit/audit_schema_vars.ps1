# ## Overview
# Audits all LibScript components in `_lib/<category>/<component>/` to ensure that
# every component-scoped (`<COMP>_*`) and global (`LIBSCRIPT_*`) configuration
# variable referenced in `.sh`, `.cmd`, `.bat`, and `.ps1` scripts is declared and
# documented in either the component's local `vars.schema.json` or the global
# `_lib/_common/base_vars.schema.json`.
#
# ## Usage
# powershell.exe -File devtools\audit\audit_schema_vars.ps1 [--all | --staged | <component_dir>...]

<#
.SYNOPSIS
Audits component scripts for undocumented environment variables missing from JSON schemas.
#>

$ErrorActionPreference = "Stop"

# ## Show-Help
# Displays command-line usage information for the schema variable auditor.
function Show-Help {
    Write-Host "Usage: audit_schema_vars.ps1 [--all | --staged | <component_dir>...]"
    Write-Host "Audits component scripts for undocumented environment variables missing from JSON schemas."
}

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Show-Help
    exit 0
}

$rootDir = if ($env:LIBSCRIPT_ROOT_DIR) { (Resolve-Path $env:LIBSCRIPT_ROOT_DIR).Path } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
$baseSchemaPath = Join-Path $rootDir "_lib\_common\base_vars.schema.json"

$errorsCount = 0
$auditedCount = 0

# ## Get-SchemaKeys
# Extracts top-level property keys from a JSON schema file.
function Get-SchemaKeys {
    param([string]$SchemaPath)
    $keys = @{}
    if (Test-Path $SchemaPath) {
        $json = Get-Content -LiteralPath $SchemaPath -Raw | ConvertFrom-Json
        if ($json.properties) {
            foreach ($p in $json.properties.PSObject.Properties) {
                $keys[$p.Name] = $true
            }
        }
    }
    return $keys
}

$globalKeys = Get-SchemaKeys -SchemaPath $baseSchemaPath

# ## Test-InternalRuntimeVar
# Checks whether a variable name is an internal LibScript runtime variable.
function Test-InternalRuntimeVar {
    param([string]$VarName)
    if ($VarName -match '^(LIBSCRIPT_ROOT_DIR|LIBSCRIPT_SERVERS_.*|LIBSCRIPT_SERVICE_UNIT_UNCHANGED|LIBSCRIPT_INSTALL_MAP_.*|LIBSCRIPT_ENV_sourced_.*|LIBSCRIPT_IS_INSTALLED)$') {
        return $true
    }
    return $false
}

# ## Audit-ComponentVars
# Audits a single component directory for undocumented configuration variables.
function Audit-ComponentVars {
    param([string]$CompDir)
    if (-not (Test-Path $CompDir -PathType Container)) { return }
    $varsSchema = Join-Path $CompDir "vars.schema.json"
    if (-not (Test-Path $varsSchema)) { return }

    $script:auditedCount++
    $compName = Split-Path -Leaf $CompDir
    $compPrefix = $compName.ToUpperInvariant().Replace('-', '_')
    if ($compName -eq "7zip") { $compPrefix = "SEVENZIP" }

    $localKeys = Get-SchemaKeys -SchemaPath $varsSchema
    $scripts = Get-ChildItem -Path $CompDir -File | Where-Object { $_.Extension -in @('.sh', '.cmd', '.ps1') }

    $foundVars = @{}
    foreach ($s in $scripts) {
        foreach ($line in (Get-Content -LiteralPath $s.FullName -ErrorAction SilentlyContinue)) {
            if ($line -match '^\s*(#|::|rem\s)') { continue }
            $matchesList = [regex]::Matches($line, '\b([A-Z][A-Z0-9_]*_[A-Z0-9_]+)\b')
            foreach ($m in $matchesList) {
                $tok = $m.Groups[1].Value
                if ($tok.StartsWith("${compPrefix}_") -or $tok.StartsWith("LIBSCRIPT_")) {
                    if ($line -match "(\$\{${tok}[:-]|\$\{${tok}\}|\$${tok}\b|%${tok}%|!${tok}!|\$env:${tok}\b)") {
                        $foundVars[$tok] = $true
                    }
                }
            }
        }
    }

    foreach ($v in ($foundVars.Keys | Sort-Object)) {
        if (Test-InternalRuntimeVar -VarName $v) { continue }
        if ($globalKeys.ContainsKey($v) -or $localKeys.ContainsKey($v)) { continue }
        $relDir = $CompDir.Substring($rootDir.Length).TrimStart('', '/').Replace('', '/')
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MISSING_JSON_VAR] $relDir/vars.schema.json: Variable `"$v`" is used in component scripts but missing from vars.schema.json (or base_vars.schema.json).")
        $script:errorsCount++
    }
}

if ($args.Count -eq 0 -or $args -contains "--all") {
    $cats = Get-ChildItem -Path (Join-Path $rootDir "_lib") -Directory | Where-Object { $_.Name -ne "_common" }
    foreach ($cat in $cats) {
        foreach ($comp in (Get-ChildItem -Path $cat.FullName -Directory)) {
            Audit-ComponentVars -CompDir $comp.FullName
        }
    }
} else {
    foreach ($arg in $args) {
        $resolved = Join-Path $rootDir $arg
        if (Test-Path $resolved -PathType Container) {
            Audit-ComponentVars -CompDir $resolved
        }
    }
}

if ($errorsCount -gt 0) {
    [Console]::Error.WriteLine("[FAIL] Schema Variable Audit failed with $errorsCount undocumented variable(s) across $auditedCount component(s).")
    exit 1
}

Write-Host "[PASS] All $auditedCount audited component(s) have 100% of their configuration variables documented in JSON schemas."
exit 0
