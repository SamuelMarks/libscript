<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'ruby' stack.

.DESCRIPTION
Execute this script to install and configure ruby on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:RUBY_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript-native"
}

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) {
    $Action = "install"
}

$RubyVersion = $env:RUBY_VERSION
if ([string]::IsNullOrEmpty($RubyVersion)) {
    $RubyVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($RubyVersion -eq "latest" -or $RubyVersion -eq "stable") {
        $ExactVersion = "3.3.0"
        try {
            $Resp = Invoke-RestMethod -Uri "https://cache.ruby-lang.org/pub/ruby/index.txt"
            $Lines = $Resp -split "`n"
            foreach ($Line in $Lines) {
                if ($Line -match "^ruby-(\d+\.\d+\.\d+).*") {
                    $ExactVersion = $matches[1]
                }
            }
        } catch {}
    } else {
        $ExactVersion = $RubyVersion
    }
    
    $Arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
        $Arch = "x86"
    }

    return @{ ExactVersion = $ExactVersion; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls ruby
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            ruby --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $RubyDir = Join-Path $LibscriptHome "ruby"
            if (Test-Path $RubyDir) {
                Get-ChildItem -Path $RubyDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote ruby
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://cache.ruby-lang.org/pub/ruby/index.txt"
            $Resp -split "`n" | Where-Object { $_ -match "^ruby-(\d+\.\d+\.\d+)" } | ForEach-Object { $matches[1] } | Sort-Object -Unique
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "ruby@${RubyVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "ruby" -AliasName $RubyVersion -ExactVersion $Info.ExactVersion
        }
        break
    }
    default {
        # download and install
        if ($InstallMethod -eq "system") {
            $WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
            if ([string]::IsNullOrEmpty($WinPkgMgr)) {
                $WinPkgMgr = "winget"
            }
            if ($WinPkgMgr -eq "winget") {
                winget install --silent --force --id=RubyInstallerTeam.Ruby -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y ruby
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "ruby@${RubyVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $Arch = $Info.Arch

            $RubyDir = Get-LibscriptVersionDir -Component "ruby" -Version $ExactVersion
            $RubyExe = Join-Path $RubyDir "bin\ruby.exe"

            if (Test-Path $RubyExe) {
                $InstalledVersion = & $RubyExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Ruby $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "ruby" -AliasName $RubyVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $ExeName = "rubyinstaller-$ExactVersion-1-$Arch.exe"
            $DownloadUrl = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$ExactVersion-1/$ExeName"

            if (-not (Test-Path $RubyDir)) {
                New-Item -ItemType Directory -Force -Path $RubyDir | Out-Null
            }

            $TempExe = Join-Path [System.IO.Path]::GetTempPath() $ExeName
            Write-Host "Downloading $DownloadUrl"
            try {
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempExe
            } catch {
                Write-Host "Failed to download RubyInstaller. You may need to specify an exact sub-version available on github."
                throw
            }

            Write-Host "Installing $TempExe to $RubyDir"
            Start-Process -FilePath $TempExe -ArgumentList "/verysilent /dir=`"$RubyDir`" /tasks=nomodpath" -Wait -NoNewWindow
            Remove-Item -Force $TempExe

            Set-LibscriptAlias -Component "ruby" -AliasName $RubyVersion -ExactVersion $ExactVersion
        }
        break
    }
}
