# ## Overview
# Audits all LibScript components in `_lib/<category>/<component>/`, scoped variable packs
# (`schemas/vars/*.schema.json`), `$ref` targets, manifests, and OS profiles across Windows and POSIX.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File .\devtools\audit\audit_schema_vars.ps1 [--all | --staged | <dir>...]

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$baseSchemaPath = Join-Path $repoRoot "engine\schemas\base_vars.schema.json"
$manifestSchemaPath = Join-Path $repoRoot "engine\schemas\manifest.schema.json"
$osConfigSchemaPath = Join-Path $repoRoot "synthesis/schemas/os-config.schema.json"
$freebsdSchemaPath = Join-Path $repoRoot "synthesis/schemas/execution-plan.freebsd.schema.json"
$illumosSchemaPath = Join-Path $repoRoot "synthesis/schemas/execution-plan.illumos.schema.json"
$reactosSchemaPath = Join-Path $repoRoot "synthesis/schemas/execution-plan.reactos.schema.json"
$rtosSchemaPath = Join-Path $repoRoot "synthesis/schemas/execution-plan.rtos.schema.json"
$execCommonSchemaPath = Join-Path $repoRoot "synthesis\schemas\execution-plan-common.schema.json"
$rootLibscriptSchemaPath = Join-Path $repoRoot "libscript.schema.json"
$nestedLibscriptSchemaPath = Join-Path $repoRoot "workloads\schemas\libscript.schema.json"
$tfrcPolicySchemaPath = Join-Path $repoRoot "engine\schemas\tfrc-policy.schema.json"
$varsPackDir = Join-Path $repoRoot "schemas\vars"

$script:errorsCount = 0
$script:auditedCount = 0

# ## Test-InternalRuntimeVar
# Runs Test-InternalRuntimeVar schema audit helper.
function Test-InternalRuntimeVar {
    <#
    .SYNOPSIS
    Returns true for internal runtime, memoization, and test-harness variables excluded from user-facing vars.schema.json.
    #>
    param([string]$VarName)
    return ($VarName -eq "LIBSCRIPT_ROOT_DIR" -or
            $VarName -like "LIBSCRIPT_SERVERS_*" -or
            $VarName -eq "LIBSCRIPT_SERVICE_UNIT_UNCHANGED" -or
            $VarName -like "LIBSCRIPT_INSTALL_MAP_*" -or
            $VarName -like "LIBSCRIPT_ENV_sourced_*" -or
            $VarName -eq "LIBSCRIPT_IS_INSTALLED" -or
            $VarName -eq "LIBSCRIPT_OVERRIDE_CHANGED" -or
            $VarName -like "LIBSCRIPT_RESOLVED_CC_*" -or
            $VarName -eq "LIBSCRIPT_RESOLVED_CXX_BIN" -or
            $VarName -eq "LIBSCRIPT_LAST_PEAK_RSS_KB" -or
            $VarName -eq "LIBSCRIPT_LAST_COMPILE_TIME_MS" -or
            $VarName -eq "LIBSCRIPT_EXTRACTED_SRC_DIR" -or
            $VarName -eq "LIBSCRIPT_BUILD_TARGET_DIR" -or
            $VarName -eq "LIBSCRIPT_BASE_DIR" -or
            $VarName -eq "LIBSCRIPT_HW_CPU_MODEL" -or
            $VarName -eq "LIBSCRIPT_HW_PHYS_CORES" -or
            $VarName -eq "LIBSCRIPT_HW_PERF_CORES" -or
            $VarName -eq "LIBSCRIPT_HW_NUMA_NODES" -or
            $VarName -eq "LIBSCRIPT_RESOLVED_JOBS" -or
            $VarName -eq "LIBSCRIPT_BG_SUPPORTED" -or
            $VarName -eq "LIBSCRIPT_PARALLEL_SUPPORTED" -or
            $VarName -eq "LIBSCRIPT_PARALLEL_PROBED" -or
            $VarName -eq "LIBSCRIPT_MAP_FN" -or
            $VarName -eq "LIBSCRIPT_BENCH_CLOCK_NS_BIN" -or
            $VarName -eq "LIBSCRIPT_BENCH_PROBE_BIN" -or
            $VarName -eq "LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA" -or
            $VarName -eq "LIBSCRIPT_INTERNAL_START" -or
            $VarName -eq "LIBSCRIPT_COMPONENT_CORE_LIB_ONLY" -or
            $VarName -eq "LIBSCRIPT_MOCK_SYSTEMD" -or
            $VarName -eq "LIBSCRIPT_DUMMY_NO_RUN" -or
            $VarName -eq "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB" -or
            $VarName -eq "LIBSCRIPT_DISABLE_CHECKSUM_TXT_UPDATE" -or
            $VarName -eq "LIBSCRIPT_TARGET_OS" -or
            $VarName -eq "LIBSCRIPT_TARGET_ARCH" -or
            $VarName -eq "LIBSCRIPT_FORCE_SYSTEM_PKG_MGR")
}

# ## Get-SchemaKeys
# Runs Get-SchemaKeys schema audit helper.
function Get-SchemaKeys {
    <#
    .SYNOPSIS
    Extracts top-level property keys and deprecated_aliases from a JSON schema file.
    #>
    param([string]$SchemaFile)
    $keys = @()
    if (-not (Test-Path -LiteralPath $SchemaFile)) { return $keys }
    try {
        $json = Get-Content -LiteralPath $SchemaFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -ne $json.properties) {
            foreach ($p in $json.properties.PSObject.Properties) {
                $keys += $p.Name
                if ($null -ne $p.Value -and $null -ne $p.Value.deprecated_aliases) {
                    foreach ($alias in @($p.Value.deprecated_aliases)) {
                        if (-not [string]::IsNullOrWhiteSpace([string]$alias)) {
                            $keys += [string]$alias
                        }
                    }
                }
            }
        }
    } catch {
        return @()
    }
    return $keys
}

# ## Test-ObjectDescriptions
# Runs Test-ObjectDescriptions schema audit helper.
function Test-ObjectDescriptions {
    <#
    .SYNOPSIS
    Recursively checks nested schema property maps for missing or placeholder descriptions.
    #>
    param($PropsObj, [string]$RelPath, [string]$Prefix)
    if ($null -eq $PropsObj) { return }
    foreach ($p in $PropsObj.PSObject.Properties) {
        $fullKey = if ($Prefix) { "$Prefix.$($p.Name)" } else { $p.Name }
        $desc = if ($null -ne $p.Value) { [string]$p.Value.description } else { "" }
        if ([string]::IsNullOrWhiteSpace($desc)) {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MISSING_SCHEMA_DESC] ${RelPath}: Property `"$fullKey`" is missing a non-empty description.")
            $script:errorsCount++
        } elseif ($desc -match '^Variable [A-Za-z0-9_]+\.?$') {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [SCHEMA_PLACEHOLDER_DESC] ${RelPath}: Property `"$fullKey`" uses placeholder description `"$desc`".")
            $script:errorsCount++
        }
        if ($null -ne $p.Value -and $null -ne $p.Value.properties) {
            Test-ObjectDescriptions -PropsObj $p.Value.properties -RelPath $RelPath -Prefix $fullKey
        }
        if ($null -ne $p.Value -and $null -ne $p.Value.items -and $null -ne $p.Value.items.properties) {
            Test-ObjectDescriptions -PropsObj $p.Value.items.properties -RelPath $RelPath -Prefix "${fullKey}[]"
        }
    }
}

# ## Test-SchemaDescriptions
# Runs Test-SchemaDescriptions schema audit helper.
function Test-SchemaDescriptions {
    <#
    .SYNOPSIS
    Validates JSON syntax and non-empty, non-placeholder property descriptions in a schema file.
    #>
    param([string]$SchemaFile)
    $rel = $SchemaFile.Substring($repoRoot.Length + 1) -replace '\\', '/'
    try {
        $json = Get-Content -LiteralPath $SchemaFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [INVALID_JSON] ${rel}: Schema is not valid JSON.")
        $script:errorsCount++
        return $false
    }
    if ($null -ne $json.properties) {
        Test-ObjectDescriptions -PropsObj $json.properties -RelPath $rel -Prefix ""
    }
    if ($null -ne $json.'$defs') {
        Test-ObjectDescriptions -PropsObj $json.'$defs' -RelPath $rel -Prefix '$defs'
    }
    return $true
}

# ## Test-SchemaRefs
# Runs Test-SchemaRefs schema audit helper.
function Test-SchemaRefs {
    <#
    .SYNOPSIS
    Validates that all relative $ref pointers across *.schema.json files resolve to existing files on disk.
    #>
    Get-ChildItem -Path $repoRoot -Filter "*.schema.json" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](node_modules|\.git)[\\/]' } |
        ForEach-Object {
            $sf = $_.FullName
            $rel = $sf.Substring($repoRoot.Length + 1) -replace '\\', '/'
            $raw = Get-Content -LiteralPath $sf -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            foreach ($m in [regex]::Matches($raw, '"[$]ref"\s*:\s*"([^"]+)"')) {
                $refVal = $m.Groups[1].Value
                if ($refVal.StartsWith("#") -or $refVal.StartsWith("http://") -or $refVal.StartsWith("https://")) {
                    continue
                }
                $targetRel = ($refVal -split '#', 2)[0]
                if ([string]::IsNullOrWhiteSpace($targetRel)) { continue }
                $candidate = Join-Path $_.DirectoryName ($targetRel -replace '/', '\')
                if (-not (Test-Path -LiteralPath $candidate)) {
                    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [SCHEMA_BROKEN_REF] ${rel}: `$ref `"$refVal`" does not resolve to an existing file.")
                    $script:errorsCount++
                }
            }
        }
}

# ## Test-ManifestJson
# Runs Test-ManifestJson schema audit helper.
function Test-ManifestJson {
    <#
    .SYNOPSIS
    Validates a component's manifest.json against engine/schemas/manifest.schema.json.
    #>
    param([string]$CompDir, $ManifestSchema)
    $relDir = $CompDir.Substring($repoRoot.Length + 1) -replace '\\', '/'
    $manifestFile = Join-Path $CompDir "manifest.json"
    if (-not (Test-Path -LiteralPath $manifestFile)) {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MISSING_MANIFEST] ${relDir}: Missing manifest.json.")
        $script:errorsCount++
        return
    }
    try {
        $m = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [INVALID_JSON] ${relDir}/manifest.json: File is not valid JSON.")
        $script:errorsCount++
        return
    }
    if ($null -eq $ManifestSchema) { return }
    $props = @($m.PSObject.Properties.Name)
    foreach ($req in @($ManifestSchema.required)) {
        if ($props -notcontains $req) {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: missing required field: $req")
            $script:errorsCount++
        }
    }
    if ([string]$m.name -notmatch '^[a-z0-9_-]+$') {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: name `"$($m.name)`" does not match ^[a-z0-9_-]+$")
        $script:errorsCount++
    }
    if ([string]::IsNullOrWhiteSpace([string]$m.title)) {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: title must be non-empty")
        $script:errorsCount++
    }
    if ([string]::IsNullOrWhiteSpace([string]$m.description)) {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: description must be non-empty")
        $script:errorsCount++
    }
    $allowedCats = @($ManifestSchema.properties.category.enum)
    if ($allowedCats.Count -gt 0 -and $allowedCats -notcontains [string]$m.category) {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: category `"$($m.category)`" not in manifest.schema.json enum")
        $script:errorsCount++
    }
    $allowedCaps = @($ManifestSchema.properties.capabilities.items.enum)
    $capsList = @($m.capabilities)
    if ($capsList.Count -eq 0) {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: capabilities must be a non-empty array")
        $script:errorsCount++
    } else {
        foreach ($capItem in $capsList) {
            if ($allowedCaps.Count -gt 0 -and $allowedCaps -notcontains [string]$capItem) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: capability `"$capItem`" not in manifest.schema.json enum")
                $script:errorsCount++
            }
        }
    }
    $allowedTop = @($ManifestSchema.properties.PSObject.Properties.Name)
    foreach ($k in $props) {
        if ($allowedTop -notcontains $k) {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MANIFEST_SCHEMA] ${relDir}/manifest.json: undeclared top-level property: $k")
            $script:errorsCount++
        }
    }
}

# ## Test-RootSchemasAndProfiles
# Runs Test-RootSchemasAndProfiles schema audit helper.
function Test-RootSchemasAndProfiles {
    <#
    .SYNOPSIS
    Validates root schemas, scoped variable packs, wrapper $ref integrity, and profiles/**/*.json files.
    #>
    foreach ($rs in @($baseSchemaPath, $rtosSchemaPath, $execCommonSchemaPath, $rootLibscriptSchemaPath, $tfrcPolicySchemaPath, (Join-Path $repoRoot "component-scaffold.schema.json"))) {
        if (Test-Path -LiteralPath $rs) {
            [void](Test-SchemaDescriptions -SchemaFile $rs)
        }
    }
    foreach ($sDir in @($varsPackDir, (Join-Path $repoRoot "engine\schemas"), (Join-Path $repoRoot "synthesis\schemas"), (Join-Path $repoRoot "workloads\schemas"), (Join-Path $repoRoot "experiments\schemas"))) {
        if (Test-Path -LiteralPath $sDir) {
            Get-ChildItem -LiteralPath $sDir -Filter "*.schema.json" -File | ForEach-Object {
                [void](Test-SchemaDescriptions -SchemaFile $_.FullName)
            }
        }
    }
    if (Test-Path -LiteralPath $baseSchemaPath) {
        $baseObj = Get-Content -LiteralPath $baseSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $baseProps = @($baseObj.properties.PSObject.Properties.Name)
        foreach ($bk in $baseProps) {
            if (Test-InternalRuntimeVar -VarName $bk) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [INTERNAL_VAR_IN_BASE_SCHEMA] engine/schemas/base_vars.schema.json: Internal variable `"$bk`" must not appear in user-facing base_vars.schema.json.")
                $script:errorsCount++
            }
        }
        if ($baseProps.Count -gt 32) {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [BASE_SCHEMA_BLOAT] engine/schemas/base_vars.schema.json: Contains $($baseProps.Count) properties (maximum allowed core globals is 32).")
            $script:errorsCount++
        }
    }
    if (Test-Path -LiteralPath $nestedLibscriptSchemaPath) {
        try {
            $wrapObj = Get-Content -LiteralPath $nestedLibscriptSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ([string]$wrapObj.'$ref' -ne "../../libscript.schema.json") {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [SCHEMA_SYNC] workloads/schemas/libscript.schema.json must `$ref `"../../libscript.schema.json`" as a thin canonical wrapper.")
                $script:errorsCount++
            }
        } catch {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [INVALID_JSON] workloads/schemas/libscript.schema.json: File is not valid JSON.")
            $script:errorsCount++
        }
    }

    Test-SchemaRefs

    $profilesDir = Join-Path $repoRoot "profiles"
    if (-not (Test-Path -LiteralPath $profilesDir)) { return }
    $osSchema = if (Test-Path -LiteralPath $osConfigSchemaPath) { Get-Content -LiteralPath $osConfigSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $fbSchema = if (Test-Path -LiteralPath $freebsdSchemaPath) { Get-Content -LiteralPath $freebsdSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $ilSchema = if (Test-Path -LiteralPath $illumosSchemaPath) { Get-Content -LiteralPath $illumosSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $roSchema = if (Test-Path -LiteralPath $reactosSchemaPath) { Get-Content -LiteralPath $reactosSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

    Get-ChildItem -LiteralPath $profilesDir -Filter "*.json" -Recurse -File | ForEach-Object {
        $pfPath = $_.FullName
        $relPf = $pfPath.Substring($repoRoot.Length + 1) -replace '\\', '/'
        try {
            $pf = Get-Content -LiteralPath $pfPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [INVALID_JSON] ${relPf}: OS profile is not valid JSON.")
            $script:errorsCount++
            return
        }
        $fam = if ($null -ne $pf.target -and $pf.target.os_family) { [string]$pf.target.os_family } else { "linux" }
        $pfProps = @($pf.PSObject.Properties.Name)
        if ($fam -eq "freebsd" -and $null -ne $fbSchema) {
            foreach ($r in @($fbSchema.required)) {
                if ($pfProps -notcontains $r) {
                    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: missing required FreeBSD field: $r")
                    $script:errorsCount++
                }
            }
        } elseif ($fam -eq "illumos" -and $null -ne $ilSchema) {
            foreach ($r in @($ilSchema.required)) {
                if ($pfProps -notcontains $r) {
                    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: missing required illumos field: $r")
                    $script:errorsCount++
                }
            }
        } elseif ($fam -eq "reactos" -and $null -ne $roSchema) {
            foreach ($r in @($roSchema.required)) {
                if ($pfProps -notcontains $r) {
                    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: missing required ReactOS field: $r")
                    $script:errorsCount++
                }
            }
        } elseif ($fam -eq "rtos" -and $null -ne $osSchema) {
            foreach ($r in @("schema_version", "profile_name", "target", "rtos")) {
                if ($pfProps -notcontains $r) {
                    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: missing required field: $r")
                    $script:errorsCount++
                }
            }
            $archs = @($osSchema.properties.target.properties.arch.enum)
            $libcs = @($osSchema.properties.target.properties.libc.enum)
            $kernels = @($osSchema.properties.rtos.properties.kernel.enum)
            if ($null -ne $pf.target -and $archs -notcontains [string]$pf.target.arch) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: target.arch `"$($pf.target.arch)`" not in synthesis/schemas/os-config.schema.json enum")
                $script:errorsCount++
            }
            if ($null -ne $pf.target -and $libcs -notcontains [string]$pf.target.libc) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: target.libc `"$($pf.target.libc)`" not in synthesis/schemas/os-config.schema.json enum")
                $script:errorsCount++
            }
            if ($null -ne $pf.rtos -and $kernels -notcontains [string]$pf.rtos.kernel) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: rtos.kernel `"$($pf.rtos.kernel)`" not in synthesis/schemas/os-config.schema.json enum")
                $script:errorsCount++
            }
        } elseif ($null -ne $osSchema) {
            foreach ($r in @($osSchema.required)) {
                if ($pfProps -notcontains $r) {
                    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: missing required field: $r")
                    $script:errorsCount++
                }
            }
            $archs = @($osSchema.properties.target.properties.arch.enum)
            $libcs = @($osSchema.properties.target.properties.libc.enum)
            if ($null -ne $pf.target -and $archs -notcontains [string]$pf.target.arch) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: target.arch `"$($pf.target.arch)`" not in synthesis/schemas/os-config.schema.json enum")
                $script:errorsCount++
            }
            if ($null -ne $pf.target -and $libcs -notcontains [string]$pf.target.libc) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [PROFILE_SCHEMA] ${relPf}: target.libc `"$($pf.target.libc)`" not in synthesis/schemas/os-config.schema.json enum")
                $script:errorsCount++
            }
        }
    }
}

$manifestSchemaObj = if (Test-Path -LiteralPath $manifestSchemaPath) { Get-Content -LiteralPath $manifestSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

$globalKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$baseRawKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
if (Test-Path -LiteralPath $baseSchemaPath) {
    $baseJsonObj = Get-Content -LiteralPath $baseSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -ne $baseJsonObj.properties) {
        foreach ($bp in $baseJsonObj.properties.PSObject.Properties) {
            [void]$baseRawKeys.Add($bp.Name)
        }
    }
}
foreach ($gk in (Get-SchemaKeys -SchemaFile $baseSchemaPath)) {
    [void]$globalKeys.Add($gk)
}

# ## Invoke-ComponentVarAudit
# Runs Invoke-ComponentVarAudit schema audit helper.
function Invoke-ComponentVarAudit {
    <#
    .SYNOPSIS
    Audits a single component directory for manifest compliance, duplicate base vars, and undocumented script variables.
    #>
    param([string]$CompDir)
    if (-not (Test-Path -LiteralPath $CompDir -PathType Container)) { return }
    if ($CompDir -match '[\\/]_common([\\/]|$)') { return }
    $hasEntry = (Test-Path (Join-Path $CompDir "manifest.json")) -or
                (Test-Path (Join-Path $CompDir "cli.sh")) -or
                (Test-Path (Join-Path $CompDir "setup.sh"))
    if (-not $hasEntry) { return }

    $script:auditedCount++
    $compName = Split-Path -Leaf $CompDir
    $prefix = ($compName.ToUpperInvariant() -replace '-', '_') + "_"
    $localSchema = Join-Path $CompDir "vars.schema.json"
    $relDir = $CompDir.Substring($repoRoot.Length + 1) -replace '\\', '/'

    Test-ManifestJson -CompDir $CompDir -ManifestSchema $manifestSchemaObj

    if (-not (Test-Path -LiteralPath $localSchema)) {
        [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MISSING_SCHEMA] ${relDir}: Missing vars.schema.json.")
        $script:errorsCount++
        return
    }

    if (-not (Test-SchemaDescriptions -SchemaFile $localSchema)) { return }

    $localJsonObj = Get-Content -LiteralPath $localSchema -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -ne $localJsonObj.properties) {
        foreach ($lp in $localJsonObj.properties.PSObject.Properties) {
            if ($lp.Name -in @("LIBSCRIPT_LISTEN_ADDRESS", "LIBSCRIPT_LISTEN_PORT", "LIBSCRIPT_LISTEN_SOCKET")) {
                continue
            }
            if ($baseRawKeys.Contains($lp.Name)) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [DUPLICATE_BASE_VAR] ${relDir}/vars.schema.json: Property `"$($lp.Name)`" redundantly duplicates engine/schemas/base_vars.schema.json.")
                $script:errorsCount++
            }
        }
    }

    $allowed = [System.Collections.Generic.HashSet[string]]::new($globalKeys, [StringComparer]::Ordinal)
    foreach ($lk in (Get-SchemaKeys -SchemaFile $localSchema)) {
        [void]$allowed.Add($lk)
    }
    if ($null -ne $localJsonObj.'x-libscript-var-packs') {
        foreach ($packName in @($localJsonObj.'x-libscript-var-packs')) {
            $packFile = Join-Path $varsPackDir "$packName.schema.json"
            if (-not (Test-Path -LiteralPath $packFile)) {
                [Console]::Error.WriteLine("[STANDARDS VIOLATION] [UNKNOWN_VAR_PACK] ${relDir}/vars.schema.json: Declared x-libscript-var-packs entry `"$packName`" has no schemas/vars/$packName.schema.json.")
                $script:errorsCount++
                continue
            }
            foreach ($pk in (Get-SchemaKeys -SchemaFile $packFile)) {
                [void]$allowed.Add($pk)
            }
        }
    }

    $scripts = Get-ChildItem -LiteralPath $CompDir -File | Where-Object {
        $_.Extension -in @('.sh', '.cmd', '.bat', '.ps1') -and
        $_.Name -notin @('test.sh', 'test.cmd', 'test.ps1') -and
        $_.Name -notlike 'test_*'
    }

    $rx = [regex]'(\$\{(?<v>[A-Z][A-Z0-9_]*_[A-Z0-9_]+)[:-]|\$env:(?<v>[A-Z][A-Z0-9_]*_[A-Z0-9_]+)|if\s+not\s+defined\s+(?<v>[A-Z][A-Z0-9_]*_[A-Z0-9_]+)|if\s+"%(?<v>[A-Z][A-Z0-9_]*_[A-Z0-9_]+)%"==""|printenv\s+"?(?<v>[A-Z][A-Z0-9_]*_[A-Z0-9_]+))'
    $usedVars = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)

    foreach ($sf in $scripts) {
        foreach ($line in [System.IO.File]::ReadLines($sf.FullName)) {
            if ($line -match '^\s*(#|::|rem\s)') { continue }
            foreach ($m in $rx.Matches($line)) {
                $v = $m.Groups['v'].Value
                if ($v.StartsWith($prefix, [StringComparison]::Ordinal) -or $v.StartsWith("LIBSCRIPT_", [StringComparison]::Ordinal)) {
                    [void]$usedVars.Add($v)
                }
            }
        }
    }

    foreach ($uv in ($usedVars | Sort-Object)) {
        if (Test-InternalRuntimeVar -VarName $uv) { continue }
        if (-not $allowed.Contains($uv)) {
            [Console]::Error.WriteLine("[STANDARDS VIOLATION] [MISSING_JSON_VAR] ${relDir}/vars.schema.json: Variable `"$uv`" is used in component scripts but missing from vars.schema.json (or x-libscript-var-packs / base_vars.schema.json).")
            $script:errorsCount++
        }
    }
}

$mode = if ($args.Count -gt 0) { $args[0] } else { "--all" }
if ($mode -eq "--all") {
    Test-RootSchemasAndProfiles
    Get-ChildItem -LiteralPath (Join-Path $repoRoot "_lib") -Directory | Where-Object { $_.Name -ne "_common" } | ForEach-Object {
        Get-ChildItem -LiteralPath $_.FullName -Directory | ForEach-Object {
            Invoke-ComponentVarAudit -CompDir $_.FullName
        }
    }
} elseif ($mode -eq "--staged") {
    Test-RootSchemasAndProfiles
    $staged = & git -C $repoRoot diff --cached --name-only --diff-filter=ACMR
    $dirs = $staged | ForEach-Object {
        $p = $_ -split '/'
        if ($p.Length -ge 3 -and $p[0] -eq "_lib" -and $p[1] -ne "_common") {
            Join-Path $repoRoot (Join-Path $p[0] (Join-Path $p[1] $p[2]))
        }
    } | Select-Object -Unique
    foreach ($d in $dirs) {
        if ($d) { Invoke-ComponentVarAudit -CompDir $d }
    }
} else {
    foreach ($a in $args) {
        $resolved = Resolve-Path -LiteralPath $a -ErrorAction SilentlyContinue
        if ($resolved) { Invoke-ComponentVarAudit -CompDir $resolved.Path }
    }
}

if ($script:errorsCount -gt 0) {
    [Console]::Error.WriteLine("[FAIL] Schema & Manifest Audit failed with $($script:errorsCount) violation(s) across $($script:auditedCount) component(s).")
    exit 1
}

Write-Host "[PASS] All $($script:auditedCount) audited component(s), scoped variable packs, manifests, and OS profiles conform to JSON schemas."
exit 0
