# ## Overview
# Configuration helper utility for Open edX configuration management on Windows.
# Provides key inspection, mutation, default generation, and syntax validation.
#
# ## Usage
# powershell stacks/cms/openedx/config_helper.ps1 get <conf_file> <key>
# powershell stacks/cms/openedx/config_helper.ps1 set <conf_file1> <conf_file2> <key> <val>
# powershell stacks/cms/openedx/config_helper.ps1 generate <conf_file1> <conf_file2>
# powershell stacks/cms/openedx/config_helper.ps1 validate <conf_file> <schema_file>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Arg1,
    [Parameter(Position = 2)]
    [string]$Arg2,
    [Parameter(Position = 3)]
    [string]$Arg3,
    [Parameter(Position = 4)]
    [string]$Arg4
)

# ## Show-Help
# Displays usage instructions.
function Show-Help {
    Write-Host "Usage: config_helper.ps1 get <conf_file> <key>"
    Write-Host "       config_helper.ps1 set <conf_file1> <conf_file2> <key> <val>"
    Write-Host "       config_helper.ps1 generate <conf_file1> <conf_file2>"
    Write-Host "       config_helper.ps1 validate <conf_file> <schema_file>"
    exit 0
}

# ## Do-Get
# Retrieves a dot-separated property value from a JSON file.
function Do-Get {
    param(
        [string]$ConfFile,
        [string]$Key
    )

    if (-not (Test-Path $ConfFile)) {
        exit 1
    }

    try {
        $raw = Get-Content -Path $ConfFile -Raw
        $json = ConvertFrom-Json $raw
        $parts = $Key.Split('.')
        $curr = $json
        foreach ($p in $parts) {
            if ($null -ne $curr -and $curr.PSObject.Properties[$p]) {
                $curr = $curr.$p
            } else {
                Write-Output "null"
                return
            }
        }
        if ($curr -is [PSCustomObject] -or $curr -is [System.Collections.IDictionary] -or $curr -is [System.Collections.IList]) {
            Write-Output (ConvertTo-Json $curr -Depth 10)
        } elseif ($null -eq $curr) {
            Write-Output "null"
        } else {
            Write-Output $curr
        }
    } catch {
        Write-Output "null"
    }
}

# ## Do-Set
# Sets a dot-separated property value across target JSON configuration files.
function Do-Set {
    param(
        [string[]]$ConfFiles,
        [string]$Key,
        [string]$Val
    )

    $parsedVal = $Val
    try {
        $parsedVal = ConvertFrom-Json $Val
    } catch {
        $parsedVal = $Val
    }

    foreach ($cf in $ConfFiles) {
        $parent = Split-Path -Parent $cf
        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $dict = @{}
        if (Test-Path $cf) {
            try {
                $raw = Get-Content -Path $cf -Raw
                $obj = ConvertFrom-Json $raw
                # Convert object to hashtable
                $dict = [System.Web.Script.Serialization.JavaScriptSerializer]::new().Deserialize([string]$raw, [hashtable])
            } catch {
                $dict = @{}
            }
        }
        if (-not ($dict -is [System.Collections.IDictionary])) {
            $dict = @{}
        }

        $parts = $Key.Split('.')
        $curr = $dict
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            $p = $parts[$i]
            if (-not $curr.ContainsKey($p) -or -not ($curr[$p] -is [System.Collections.IDictionary])) {
                $curr[$p] = @{}
            }
            $curr = $curr[$p]
        }
        $curr[$parts[$parts.Length - 1]] = $parsedVal

        $jsonStr = ConvertTo-Json $dict -Depth 10
        Set-Content -Path $cf -Value $jsonStr -Encoding Ascii
    }

    Write-Host "Updated $Key."
}

# ## Do-Generate
# Generates default configuration parameters for LMS and Studio CMS.
function Do-Generate {
    param([string[]]$ConfFiles)

    $secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

    $defaults = @{
        "SITE_NAME" = "openedx.local"
        "LMS_BASE" = "openedx.local"
        "CMS_BASE" = "studio.openedx.local"
        "SECRET_KEY" = $secretKey
        "DATABASES" = @{
            "default" = @{
                "ENGINE" = "django.db.backends.mysql"
                "NAME" = "openedx"
                "USER" = "openedx"
                "PASSWORD" = ""
                "HOST" = "127.0.0.1"
                "PORT" = 3306
            }
        }
        "CACHES" = @{
            "default" = @{
                "BACKEND" = "django_redis.cache.RedisCache"
                "LOCATION" = "redis://127.0.0.1:6379/1"
            }
        }
        "MEILISEARCH_URL" = "http://127.0.0.1:7700"
        "EMAIL_HOST" = "127.0.0.1"
        "EMAIL_PORT" = 25
    }

    foreach ($cf in $ConfFiles) {
        $parent = Split-Path -Parent $cf
        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        if (-not (Test-Path $cf)) {
            $jsonStr = ConvertTo-Json $defaults -Depth 10
            Set-Content -Path $cf -Value $jsonStr -Encoding Ascii
        }
    }

    Write-Host "Configurations generated."
}

# ## Do-Validate
# Validates JSON file syntax.
function Do-Validate {
    param(
        [string]$ConfFile,
        [string]$SchemaFile
    )

    if (-not (Test-Path $ConfFile)) {
        Write-Error "Error: $ConfFile does not exist"
        exit 1
    }

    try {
        $raw = Get-Content -Path $ConfFile -Raw
        $null = ConvertFrom-Json $raw
        Write-Host "Configuration validation PASSED."
    } catch {
        Write-Error "Error: Invalid JSON syntax in $ConfFile"
        exit 1
    }
}

if ([string]::IsNullOrEmpty($Action) -or $Action -in @("help", "--help", "-h")) {
    Show-Help
}

switch ($Action.ToLower()) {
    "get" {
        Do-Get -ConfFile $Arg1 -Key $Arg2
    }
    "set" {
        Do-Set -ConfFiles @($Arg1, $Arg2) -Key $Arg3 -Val $Arg4
    }
    "generate" {
        Do-Generate -ConfFiles @($Arg1, $Arg2)
    }
    "validate" {
        Do-Validate -ConfFile $Arg1 -SchemaFile $Arg2
    }
    Default {
        Write-Error "Error: Unknown action $Action"
        exit 1
    }
}
