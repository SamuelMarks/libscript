# ## Overview
# PowerShell script for merge_location_into_server.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles operations related to the component 'nginx'.

.DESCRIPTION
Execute this script to perform actions for nginx.
#>

$ErrorActionPreference = "Stop"

function Parse-Tokens {
    param([string[]]$Lines)
    $dirs = @()
    $state = "NORMAL"
    $tok = ""
    $brace_level = 0
    $current_dir = @{ line = 0; brace_level = 0; tokens = @() }

    for ($l = 0; $l -lt $Lines.Length; $l++) {
        $line = $Lines[$l]
        $len = $line.Length
        $c = 0
        while ($c -lt $len) {
            $ch = $line[$c]
            if ($state -eq "NORMAL") {
                if ($ch -eq '\') {
                    $tok += $ch; $c++
                    if ($c -lt $len) { $tok += $line[$c] }
                } elseif ($ch -eq '"') {
                    $state = "DQUOTE"; $tok += $ch
                } elseif ($ch -eq "'") {
                    $state = "SQUOTE"; $tok += $ch
                } elseif ($ch -eq '#') {
                    break
                } elseif ($ch -eq '{' -or $ch -eq '}' -or $ch -eq ';') {
                    if ($tok -ne "") { $current_dir.tokens += $tok; $tok = "" }
                    $current_dir.tokens += $ch
                    $current_dir.line = $l + 1
                    $current_dir.brace_level = $brace_level
                    if ($ch -eq '{') { $brace_level++ }
                    if ($ch -eq '}') { $brace_level-- }
                    $new_dir = @{ line = $current_dir.line; brace_level = $current_dir.brace_level; tokens = @($current_dir.tokens) }
                    $dirs += $new_dir
                    $current_dir.tokens = @()
                } elseif ([char]::IsWhiteSpace($ch)) {
                    if ($tok -ne "") { $current_dir.tokens += $tok; $tok = "" }
                } else {
                    $tok += $ch
                }
            } elseif ($state -eq "DQUOTE") {
                $tok += $ch
                if ($ch -eq '\') {
                    $c++
                    if ($c -lt $len) { $tok += $line[$c] }
                } elseif ($ch -eq '"') {
                    $state = "NORMAL"
                }
            } elseif ($state -eq "SQUOTE") {
                $tok += $ch
                if ($ch -eq '\') {
                    $c++
                    if ($c -lt $len) { $tok += $line[$c] }
                } elseif ($ch -eq "'") {
                    $state = "NORMAL"
                }
            }
            $c++
        }
        if ($tok -ne "" -and $state -eq "NORMAL") {
            $current_dir.tokens += $tok; $tok = ""
        }
    }
    return $dirs
}

function Merge-LocationIntoServer {
    param (
        [string]$ExistingConfig,
        [string]$NewLocationBlock,
        [string]$TargetServerName,
        [string]$TargetListenRegex = "443.*ssl"
    )

    if (-not (Test-Path -Path $ExistingConfig)) {
        Write-Error "Existing config file not found: $ExistingConfig"
        return
    }

    $lockFile = "$ExistingConfig.lock.dir"
    while ($true) {
        try {
            New-Item -ItemType Directory -Path $lockFile -ErrorAction Stop | Out-Null
            break
        } catch {
            Start-Sleep -Milliseconds 100
        }
    }

    try {
        if (Test-Path -Path $NewLocationBlock -PathType Leaf) {
            $newLines = Get-Content -Path $NewLocationBlock
        } else {
            $newLines = $NewLocationBlock -split "`r?`n"
        }
        
        $targetLines = Get-Content -Path $ExistingConfig

        $newDirs = Parse-Tokens -Lines $newLines
        $targetDirs = Parse-Tokens -Lines $targetLines

        $newSig = ""
        foreach ($dir in $newDirs) {
            if ($dir.tokens[0] -eq "location" -and $dir.brace_level -eq 0) {
                $sigTokens = $dir.tokens[0..($dir.tokens.Count - 2)]
                $newSig = $sigTokens -join " "
                break
            }
        }

        $targetServerEndLine = 0
        $inServer = $false
        $serverMatchName = $false
        $serverMatchListen = $false
        $serverStartIdx = 0

        for ($i = 0; $i -lt $targetDirs.Count; $i++) {
            $dir = $targetDirs[$i]
            $level = $dir.brace_level
            $cmd = $dir.tokens[0]

            if ($level -eq 0 -and $cmd -eq "server" -and $dir.tokens[$dir.tokens.Count - 1] -eq "{") {
                $inServer = $true
                $serverMatchName = $false
                $serverMatchListen = $false
                $serverStartIdx = $i
            } elseif ($inServer -and $level -eq 1) {
                if ($cmd -eq "}") {
                    $inServer = $false
                    if ($serverMatchName -and $serverMatchListen) {
                        $targetServerEndLine = $dir.line
                        break
                    }
                } elseif ($cmd -eq "server_name") {
                    for ($j = 1; $j -lt $dir.tokens.Count - 1; $j++) {
                        $name = $dir.tokens[$j].Trim('"', "'")
                        if ($name -eq $TargetServerName) {
                            $serverMatchName = $true
                        }
                    }
                } elseif ($cmd -eq "listen") {
                    $lstr = ($dir.tokens[1..($dir.tokens.Count - 2)]) -join " "
                    if ($lstr -match $TargetListenRegex) {
                        $serverMatchListen = $true
                    }
                }
            }
        }

        if ($targetServerEndLine -eq 0) {
            Write-Error "Target server block not found."
            return
        }

        $replaceStart = 0
        $replaceEnd = 0
        for ($i = $serverStartIdx + 1; $i -lt $targetDirs.Count; $i++) {
            $dir = $targetDirs[$i]
            if ($dir.line -gt $targetServerEndLine) { break }
            if ($dir.brace_level -eq 1 -and $dir.tokens[0] -eq "location") {
                $locSig = ($dir.tokens[0..($dir.tokens.Count - 2)]) -join " "
                if ($locSig -eq $newSig) {
                    $replaceStart = $dir.line
                    for ($k = $i + 1; $k -lt $targetDirs.Count; $k++) {
                        $endDir = $targetDirs[$k]
                        if ($endDir.tokens[0] -eq "}" -and $endDir.brace_level -eq 2) {
                            $replaceEnd = $endDir.line
                            break
                        }
                    }
                    break
                }
            }
        }

        $tmpConfig = [System.IO.Path]::GetTempFileName()
        $outLines = @()

        for ($l = 1; $l -le $targetLines.Length; $l++) {
            if ($replaceStart -ne 0 -and $l -ge $replaceStart -and $l -le $replaceEnd) {
                if ($l -eq $replaceStart) {
                    foreach ($nl in $newLines) { $outLines += $nl }
                }
                continue
            }
            if ($replaceStart -eq 0 -and $l -eq $targetServerEndLine) {
                $outLines += ""
                foreach ($nl in $newLines) {
                    if ($nl -ne "") {
                        $outLines += "    $nl"
                    } else {
                        $outLines += ""
                    }
                }
            }
            $outLines += $targetLines[$l - 1]
        }

        Set-Content -Path $tmpConfig -Value $outLines -Encoding UTF8

        if (Get-Command nginx -ErrorAction SilentlyContinue) {
            $tmpNginxConf = [System.IO.Path]::GetTempFileName() + ".conf"
            $escapedTmpConfig = $tmpConfig -replace '\\', '/'
            Set-Content -Path $tmpNginxConf -Value "events {}`nhttp {`n    include $escapedTmpConfig;`n}"
            $proc = Start-Process nginx -ArgumentList "-t", "-c", $tmpNginxConf, "-q" -Wait -NoNewWindow -PassThru
            if ($proc.ExitCode -ne 0) {
                Write-Error "Nginx syntax check failed for the modified configuration."
                Remove-Item -Path $tmpNginxConf -Force -ErrorAction SilentlyContinue
                return
            }
            Remove-Item -Path $tmpNginxConf -Force -ErrorAction SilentlyContinue
        }

        # Atomic replace
        $tmpDest = "$ExistingConfig.tmp"
        Copy-Item -Path $tmpConfig -Destination $tmpDest -Force
        Move-Item -Path $tmpDest -Destination $ExistingConfig -Force

        Remove-Item -Path $tmpConfig -Force
    } finally {
        Remove-Item -Path $lockFile -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Export the function if loaded as a module, or allow invocation
if ($MyInvocation.InvocationName -ne '.') {
    # If run directly as a script
}
