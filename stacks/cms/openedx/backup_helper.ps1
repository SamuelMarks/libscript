# ## Overview
# Backup and disaster recovery helper utility for Open edX on Windows.
# Creates consolidated compressed archives and applies restoration snapshots.
#
# ## Usage
# powershell stacks/cms/openedx/backup_helper.ps1 backup <backup_dir> <install_dir> [out_path]
# powershell stacks/cms/openedx/backup_helper.ps1 restore <archive> <install_dir> [force]

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Arg1,
    [Parameter(Position = 2)]
    [string]$Arg2,
    [Parameter(Position = 3)]
    [string]$Arg3
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

# ## Show-Help
# Displays usage instructions.
function Show-Help {
    Write-Host "Usage: backup_helper.ps1 backup <backup_dir> <install_dir> [out_path]"
    Write-Host "       backup_helper.ps1 restore <archive> <install_dir> [force]"
    exit 0
}

# ## Do-Backup
# Compresses state, config, media, and data into a backup archive.
function Do-Backup {
    param(
        [string]$BackupDir,
        [string]$InstallDir,
        [string]$OutPath
    )

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    if ([string]::IsNullOrEmpty($OutPath)) {
        $archive = Join-Path $BackupDir "openedx_backup_$ts.zip"
    } elseif (Test-Path -PathType Container $OutPath) {
        $archive = Join-Path $OutPath "openedx_backup_$ts.zip"
    } else {
        $archive = $OutPath
    }

    $stage = Join-Path $BackupDir "stage_$ts"
    if (-not (Test-Path $stage)) {
        New-Item -ItemType Directory -Path $stage -Force | Out-Null
    }

    foreach ($d in @("media", "config", "data")) {
        $src = Join-Path $InstallDir $d
        if (Test-Path $src) {
            $dest = Join-Path $stage $d
            Copy-Item -Path $src -Destination $dest -Recurse -Force
        }
    }

    $usersJson = Join-Path $InstallDir "users.json"
    if (Test-Path $usersJson) {
        Copy-Item -Path $usersJson -Destination $stage -Force
    }

    $sqlPath = Join-Path $stage "mysql_dump.sql"
    Set-Content -Path $sqlPath -Value "-- Open edX Windows snapshot`r`n" -Encoding Ascii

    $archiveParent = Split-Path -Parent $archive
    if (-not (Test-Path $archiveParent)) {
        New-Item -ItemType Directory -Path $archiveParent -Force | Out-Null
    }
    if (Test-Path $archive) {
        Remove-Item -Path $archive -Force
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $archive, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    Remove-Item -Path $stage -Recurse -Force

    $hash = (Get-FileHash -Path $archive -Algorithm SHA256).Hash.ToLower()
    $archiveName = Split-Path -Leaf $archive
    Set-Content -Path "$archive.sha256" -Value "$hash  $archiveName`r`n" -Encoding Ascii

    Write-Host "Backup created: $archive"
    Write-Host "SHA-256 Checksum: $hash"
}

# ## Do-Restore
# Unpacks archive into install directory.
function Do-Restore {
    param(
        [string]$Archive,
        [string]$InstallDir,
        [string]$ForceFlag
    )

    if (-not (Test-Path $Archive)) {
        Write-Error "Error: Archive not found: $Archive"
        exit 1
    }

    $stage = Join-Path $InstallDir "restore_staging"
    if (Test-Path $stage) {
        Remove-Item -Path $stage -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    [System.IO.Compression.ZipFile]::ExtractToDirectory($Archive, $stage)

    Get-ChildItem -Path $stage | ForEach-Object {
        $dest = Join-Path $InstallDir $_.Name
        if ($_.PSIsContainer) {
            Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
        } elseif ($_.Name -ne "mysql_dump.sql") {
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }
    }

    Remove-Item -Path $stage -Recurse -Force
    Write-Host "Restore applied successfully."
}

if ([string]::IsNullOrEmpty($Action) -or $Action -in @("help", "--help", "-h")) {
    Show-Help
}

switch ($Action.ToLower()) {
    "backup" {
        Do-Backup -BackupDir $Arg1 -InstallDir $Arg2 -OutPath $Arg3
    }
    "restore" {
        Do-Restore -Archive $Arg1 -InstallDir $Arg2 -ForceFlag $Arg3
    }
    Default {
        Write-Error "Error: Unknown action $Action"
        exit 1
    }
}
