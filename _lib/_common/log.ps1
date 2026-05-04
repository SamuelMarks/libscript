$ErrorActionPreference = "Stop"

# LibScript Unified Logging Utility (PowerShell)

# Levels: 0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR
if (-not $env:LIBSCRIPT_LOG_LEVEL) { $env:LIBSCRIPT_LOG_LEVEL = 1 }
if (-not $env:LIBSCRIPT_LOG_FORMAT) { $env:LIBSCRIPT_LOG_FORMAT = "text" }
if (-not $env:LIBSCRIPT_LOG_FILE) { $env:LIBSCRIPT_LOG_FILE = "" }

function write_libscript_log {
    param (
        [string]$LevelName,
        [int]$LevelNum,
        [string]$Message
    )

    if ($LevelNum -lt [int]$env:LIBSCRIPT_LOG_LEVEL) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

    if ($env:LIBSCRIPT_LOG_FORMAT -eq "json") {
        $logObj = [PSCustomObject]@{
            timestamp = $timestamp
            level     = $LevelName
            message   = $Message
        }
        $jsonOut = $logObj | ConvertTo-Json -Compress

        if ($env:LIBSCRIPT_LOG_FILE) {
            $jsonOut | Out-File -FilePath $env:LIBSCRIPT_LOG_FILE -Append -Encoding utf8
        }
        Write-Output $jsonOut
    }
    else {
        # Text format: [LEVEL] Message
        $textOut = "[$LevelName] $Message"

        if ($env:LIBSCRIPT_LOG_FILE) {
            "$timestamp $textOut" | Out-File -FilePath $env:LIBSCRIPT_LOG_FILE -Append -Encoding utf8
        }

        # Use host for logs to keep stdout clean for data/piping
        if ($LevelName -eq "ERROR") {
            Write-Error $textOut
        } elseif ($LevelName -eq "WARN") {
            Write-Warning $textOut
        } else {
            Write-Host $textOut
        }
    }
}

function log_debug($msg)   { write_libscript_log "DEBUG"   0 $msg }
function log_info($msg)    { write_libscript_log "INFO"    1 $msg }
function log_success($msg) { write_libscript_log "SUCCESS" 2 $msg }
function log_warn($msg)    { write_libscript_log "WARN"    3 $msg }
function log_error($msg)   { write_libscript_log "ERROR"   4 $msg }

# Export functions
Export-ModuleMember -Function log_debug, log_info, log_success, log_warn, log_error
