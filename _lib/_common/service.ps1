# LibScript Unified Service Management Utility (PowerShell)

# Source dependencies if not already available
if (-not (Get-Command log_info -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot "log.ps1")
}

function libscript_service {
    param (
        [string]$Action,
        [string]$ServiceName,
        [hashtable]$Options = @{}
    )

    if ([string]::IsNullOrEmpty($Action) -or [string]::IsNullOrEmpty($ServiceName)) {
        log_error "Usage: libscript_service [ACTION] [SERVICE_NAME]"
        return
    }

    # Support action aliases
    switch ($Action) {
        "up" { $Action = "start" }
        "down" { $Action = "stop" }
        "query" { $Action = "status" }
    }

    $svc = Get-Service $ServiceName -ErrorAction SilentlyContinue

    switch ($Action) {
        "start" {
            if ($svc.Status -ne "Running") {
                log_info "Starting service $ServiceName..."
                Start-Service $ServiceName
            }
        }
        "stop" {
            if ($svc.Status -eq "Running") {
                log_info "Stopping service $ServiceName..."
                Stop-Service $ServiceName
            }
        }
        "restart" {
            log_info "Restarting service $ServiceName..."
            Restart-Service $ServiceName
        }
        "status" {
            if ($svc) {
                log_info "Service $ServiceName is $($svc.Status)"
                return $svc.Status
            } else {
                log_error "Service $ServiceName not found."
                exit 1
            }
        }
        "enable" {
            log_info "Enabling service $ServiceName (Automatic start)..."
            Set-Service $ServiceName -StartupType Automatic
        }
        "disable" {
            log_info "Disabling service $ServiceName..."
            Set-Service $ServiceName -StartupType Disabled
        }
        "health" {
            return libscript_check_health $ServiceName
        }
        "logs" {
            log_warn "Tail-style logs not natively supported via Windows Services. Use Event Viewer or service-specific log files."
            # Fallback: if we can find a log file in a standard location
            if ($env:LOGS_DIR) {
                $logFile = Join-Path $env:LOGS_DIR "$ServiceName.log"
                if (Test-Path $logFile) {
                    Get-Content $logFile -Tail 20 -Wait
                }
            }
        }
        Default {
            log_error "Unknown action: $Action"
            exit 1
        }
    }
}

function libscript_check_health {
    param (
        [string]$ServiceName
    )

    # 1. Check for component-specific health.ps1 in the caller's directory
    # (Note: This depends on how the caller is invoked)
    $callerDir = Split-Path $MyInvocation.ScriptName
    $healthScript = Join-Path $callerDir "health.ps1"
    if (Test-Path $healthScript) {
        & $healthScript
        return $LASTEXITCODE -eq 0
    }

    # 2. Check for healthcheck command in vars.schema.json
    $schemaFile = Join-Path $callerDir "vars.schema.json"
    if (Test-Path $schemaFile) {
        try {
            $schema = Get-Content $schemaFile | ConvertFrom-Json
            if ($schema.healthcheck) {
                log_info "Running custom healthcheck for $ServiceName..."
                Invoke-Expression $schema.healthcheck
                if ($LASTEXITCODE -eq 0) {
                    log_success "$ServiceName is healthy"
                    return $true
                } else {
                    log_error "$ServiceName is unhealthy"
                    return $false
                }
            }
        } catch {}
    }

    # 3. Default: Check if service is running
    $svc = Get-Service $ServiceName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        log_info "$ServiceName is healthy (Running)"
        return $true
    }

    log_error "$ServiceName is NOT healthy"
    return $false
}

# Export functions
Export-ModuleMember -Function libscript_service, libscript_check_health
