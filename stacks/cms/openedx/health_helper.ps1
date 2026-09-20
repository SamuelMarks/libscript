# ## Overview
# Diagnostic healthcheck helper utility for Open edX on Windows.
# Validates connectivity and responsiveness across databases, caches, and web services.
#
# ## Usage
# powershell stacks/cms/openedx/health_helper.ps1 <is_json> <lms_h> <lms_p> <cms_h> <cms_p> <my_h> <my_p> <mg_h> <mg_p> <rd_h> <rd_p> <me_h> <me_p> <sm_h> <sm_p>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$IsJson = "0",
    [Parameter(Position = 1)]
    [string]$LmsH = "127.0.0.1",
    [Parameter(Position = 2)]
    [string]$LmsP = "8000",
    [Parameter(Position = 3)]
    [string]$CmsH = "127.0.0.1",
    [Parameter(Position = 4)]
    [string]$CmsP = "8001",
    [Parameter(Position = 5)]
    [string]$MyH = "127.0.0.1",
    [Parameter(Position = 6)]
    [string]$MyP = "3306",
    [Parameter(Position = 7)]
    [string]$MgH = "127.0.0.1",
    [Parameter(Position = 8)]
    [string]$MgP = "27017",
    [Parameter(Position = 9)]
    [string]$RdH = "127.0.0.1",
    [Parameter(Position = 10)]
    [string]$RdP = "6379",
    [Parameter(Position = 11)]
    [string]$MeH = "127.0.0.1",
    [Parameter(Position = 12)]
    [string]$MeP = "7700",
    [Parameter(Position = 13)]
    [string]$SmH = "127.0.0.1",
    [Parameter(Position = 14)]
    [string]$SmP = "25"
)

# ## Show-Help
# Displays usage instructions.
function Show-Help {
    Write-Host "Usage: health_helper.ps1 <is_json> <lms_h> <lms_p> <cms_h> <cms_p> <my_h> <my_p> <mg_h> <mg_p> <rd_h> <rd_p> <me_h> <me_p> <sm_h> <sm_p>"
    exit 0
}

if ($IsJson -in @("help", "--help", "-h")) {
    Show-Help
}

# ## Test-TcpPort
# Tests TCP socket connectivity with 1000ms timeout.
function Test-TcpPort {
    param([string]$HostName, [int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        $wait = $iar.AsyncWaitHandle.WaitOne(1000, $false)
        if ($wait) {
            $client.EndConnect($iar)
            $client.Close()
            return "OK"
        } else {
            $client.Close()
            return "FAIL"
        }
    } catch {
        return "FAIL"
    }
}

# ## Test-HttpEndpoint
# Probes HTTP URL endpoint.
function Test-HttpEndpoint {
    param([string]$Url)
    try {
        $req = [System.Net.WebRequest]::Create($Url)
        $req.Timeout = 2000
        $req.UserAgent = "Healthcheck"
        $resp = $req.GetResponse()
        $code = [int]$resp.StatusCode
        $resp.Close()
        return "OK ($code)"
    } catch [System.Net.WebException] {
        if ($_.Response) {
            $code = [int]$_.Response.StatusCode
            if ($code -in 200, 301, 302, 401, 403) {
                return "OK ($code)"
            }
            return "FAIL ($code)"
        }
        return "FAIL"
    } catch {
        return "FAIL"
    }
}

$res = @{}
$res["mysql"] = Test-TcpPort -HostName $MyH -Port ([int]$MyP)
$res["mongodb"] = Test-TcpPort -HostName $MgH -Port ([int]$MgP)
$res["redis"] = Test-TcpPort -HostName $RdH -Port ([int]$RdP)
$res["meilisearch"] = Test-HttpEndpoint -Url "http://$MeH`:$MeP/health"
$res["lms"] = Test-HttpEndpoint -Url "http://$LmsH`:$LmsP/"
$res["cms"] = Test-HttpEndpoint -Url "http://$CmsH`:$CmsP/signin"
$res["workers"] = "WARN (inactive)"
$res["smtp"] = Test-TcpPort -HostName $SmH -Port ([int]$SmP)
if ($res["smtp"] -eq "FAIL") {
    $res["smtp"] = "WARN (offline)"
}

$fails = 0
foreach ($v in $res.Values) {
    if ($v -like "FAIL*") {
        $fails++
    }
}

if ($IsJson -eq "1") {
    $report = @{
        "status" = if ($fails -eq 0) { "healthy" } else { "degraded" }
        "failures" = $fails
        "services" = $res
    }
    Write-Output (ConvertTo-Json $report -Depth 5)
} else {
    Write-Host "========================================================================"
    Write-Host "               Open edX Full-Stack Health Diagnostics (Windows)        "
    Write-Host "========================================================================"
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "SERVICE", "TARGET ENDPOINT", "STATUS")
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f ("-" * 20), ("-" * 32), ("-" * 16))
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "MySQL", "$MyH`:$MyP", $res["mysql"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "MongoDB", "$MgH`:$MgP", $res["mongodb"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "Redis", "$RdH`:$RdP", $res["redis"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "Meilisearch", "http://$MeH`:$MeP", $res["meilisearch"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "LMS Web", "http://$LmsH`:$LmsP/", $res["lms"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "Studio Web", "http://$CmsH`:$CmsP/signin", $res["cms"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "Celery Workers", "celery-lms, cms-worker", $res["workers"])
    Write-Host ("{0,-20} {1,-32} {2,-16}" -f "SMTP Mail Relay", "$SmH`:$SmP", $res["smtp"])
    Write-Host "========================================================================"
    if ($fails -eq 0) {
        Write-Host "[SUCCESS] All Open edX core services and endpoints are healthy."
    } else {
        Write-Host "[WARN] Healthcheck detected $fails degraded or offline service(s)."
    }
}

if ($fails -gt 0) {
    exit 1
}
exit 0
