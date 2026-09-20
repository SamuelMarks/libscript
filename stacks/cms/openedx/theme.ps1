# ## Overview
# Theming and branding engine for Open edX on Windows (PowerShell).
# Manages installation, compilation, site binding, listing, and removal of themes.
#
# ## Usage
#   .	heme.ps1 install <name> <git_url> [-Branch <branch>]
#   .	heme.ps1 build <name>
#   .	heme.ps1 apply <name> [-Site <domain>]
#   .	heme.ps1 list
#   .	heme.ps1 remove <name>
#   .	heme.ps1 help

<#
.SYNOPSIS
    Theming and branding engine for Open edX.
.DESCRIPTION
    Installs, builds, applies, lists, and removes Open edX themes.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$ThemeName,

    [Parameter(Position = 2)]
    [string]$GitUrl,

    [Parameter()]
    [string]$Branch = "master",

    [Parameter()]
    [string]$Site = "openedx.local"
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

$ThemesDir = Join-Path $InstallDir "themes"
$ThemeRegistry = Join-Path $ThemesDir "registry.json"
if (-not (Test-Path $ThemesDir)) {
    New-Item -ItemType Directory -Path $ThemesDir -Force | Out-Null
}

# ## Show-Help
# Displays theme CLI command usage.
function Show-Help {
    Write-Host "Open edX Theming & Branding CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .	heme.ps1 install <name> <git_url> [-Branch <branch>]"
    Write-Host "  .	heme.ps1 build <name>"
    Write-Host "  .	heme.ps1 apply <name> [-Site <domain>]"
    Write-Host "  .	heme.ps1 list"
    Write-Host "  .	heme.ps1 remove <name>"
    Write-Host "  .	heme.ps1 help"
}

# ## Get-Registry
# Loads the theme registry hashtable from disk.
function Get-Registry {
    if (Test-Path $ThemeRegistry) {
        try {
            $raw = Get-Content -Path $ThemeRegistry -Raw
            $json = ConvertFrom-Json $raw
            $dict = @{}
            foreach ($prop in $json.PSObject.Properties) {
                $dict[$prop.Name] = @{
                    "url" = $prop.Value.url
                    "branch" = $prop.Value.branch
                    "installed" = $prop.Value.installed
                    "active" = $prop.Value.active
                }
            }
            return $dict
        } catch {
            return @{}
        }
    }
    return @{}
}

# ## Save-Registry
# Writes the theme registry hashtable to disk.
function Save-Registry {
    param([hashtable]$Registry)
    $jsonStr = ConvertTo-Json $Registry -Depth 5
    Set-Content -Path $ThemeRegistry -Value $jsonStr -Encoding Ascii
}

# ## Install-Theme
# Clones or updates a theme git repository.
function Install-Theme {
    param([string]$Name, [string]$Url, [string]$TargetBranch)
    if ([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($Url)) {
        Write-Error "Theme name and git URL are required."
        exit 1
    }
    Write-Host "[INFO] Installing theme '$Name'..."
    $destDir = Join-Path $ThemesDir $Name
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        if (Test-Path (Join-Path $destDir ".git")) {
            Push-Location $destDir
            try { & git pull 2>$null | Out-Null } finally { Pop-Location }
        } else {
            & git clone --depth 1 --branch $TargetBranch $Url $destDir 2>$null
        }
    } else {
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
    }

    $reg = Get-Registry
    $reg[$Name] = @{
        "url" = $Url
        "branch" = $TargetBranch
        "installed" = $true
        "active" = $false
    }
    Save-Registry $reg
    Write-Host "[INFO] Theme '$Name' installed."
}

# ## Build-Theme
# Compiles assets for a custom Open edX theme.
function Build-Theme {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) {
        Write-Error "Theme name required."
        exit 1
    }
    $destDir = Join-Path $ThemesDir $Name
    if (-not (Test-Path $destDir)) {
        Write-Error "Theme '$Name' not found."
        exit 1
    }
    Write-Host "[INFO] Compiling assets for theme '$Name'..."
    $pkgJson = Join-Path $destDir "package.json"
    if (Test-Path $pkgJson) {
        Push-Location $destDir
        try {
            npm install 2>$null | Out-Null
            npm run build 2>$null | Out-Null
        } finally {
            Pop-Location
        }
    }
    Write-Host "[INFO] Theme '$Name' build completed."
}

# ## Apply-Theme
# Activates a theme in the registry for the specified domain.
function Apply-Theme {
    param([string]$Name, [string]$Domain)
    if ([string]::IsNullOrEmpty($Name)) {
        Write-Error "Theme name required."
        exit 1
    }
    $destDir = Join-Path $ThemesDir $Name
    if (-not (Test-Path $destDir)) {
        Write-Error "Theme '$Name' not installed."
        exit 1
    }
    Write-Host "[INFO] Applying theme '$Name' to $Domain..."
    $reg = Get-Registry
    foreach ($k in $reg.Keys) {
        $reg[$k]["active"] = ($k -eq $Name)
    }
    Save-Registry $reg
    Write-Host "[INFO] Theme '$Name' applied."
}

# ## List-Themes
# Displays all registered themes.
function List-Themes {
    Write-Host "============================================================================"
    Write-Host ("{0,-24} {1,-10} {2,-40}" -f "THEME NAME", "ACTIVE", "SOURCE URL")
    Write-Host ("-" * 76)
    $reg = Get-Registry
    foreach ($k in $reg.Keys) {
        $act = if ($reg[$k]["active"]) { "True" } else { "False" }
        $u = if ($reg[$k]["url"]) { $reg[$k]["url"] } else { "local" }
        Write-Host ("{0,-24} {1,-10} {2,-40}" -f $k, $act, $u)
    }
    Write-Host "============================================================================"
}

# ## Remove-Theme
# Deletes a theme from disk and deregisters it.
function Remove-Theme {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) {
        Write-Error "Theme name required."
        exit 1
    }
    Write-Host "[INFO] Removing theme '$Name'..."
    $destDir = Join-Path $ThemesDir $Name
    if (Test-Path $destDir) {
        Remove-Item -Path $destDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $reg = Get-Registry
    if ($reg.ContainsKey($Name)) {
        $reg.Remove($Name)
        Save-Registry $reg
    }
    Write-Host "[INFO] Theme '$Name' removed."
}

switch ($Command.ToLower()) {
    "install" { Install-Theme -Name $ThemeName -Url $GitUrl -TargetBranch $Branch }
    "build"   { Build-Theme -Name $ThemeName }
    "apply"   { Apply-Theme -Name $ThemeName -Domain $Site }
    "list"    { List-Themes }
    "remove"  { Remove-Theme -Name $ThemeName }
    "delete"  { Remove-Theme -Name $ThemeName }
    "help"    { Show-Help }
    default   {
        Write-Error "Unknown theme command: $Command"
        Show-Help
        exit 1
    }
}
