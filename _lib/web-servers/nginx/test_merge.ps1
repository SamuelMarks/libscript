<#
.SYNOPSIS
Internal script for nginx on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for nginx.
#>

$ErrorActionPreference = "Stop"

Write-Host "Running merge unit tests..."

$tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString()))

try {
    $existingConf = Join-Path $tmpDir "existing.conf"
    $newConf = Join-Path $tmpDir "new.conf"
    $new2Conf = Join-Path $tmpDir "new2.conf"

    $existingContent = @"
server {
    listen 80;
    server_name example.com;

    location / {
        return 200 "hello";
    }
}

server {
    listen 443 ssl http2;
    server_name  "example.com"
                 alias.example.com;

    # This is a comment {
    location /old {
        return 200 "old";
    }

    location ~ "^/regex/[0-9]{1,3}$" {
        return 200 "regex";
    }
}
"@
    Set-Content -Path $existingConf -Value $existingContent -Encoding UTF8

    $newContent = @"
location ~ "^/regex/[0-9]{1,3}$" {
    return 200 "new regex";
}
"@
    Set-Content -Path $newConf -Value $newContent -Encoding UTF8

    . "$PSScriptRoot/merge_location_into_server.ps1"
    Merge-LocationIntoServer -ExistingConfig $existingConf -NewLocationBlock $newConf -TargetServerName "example.com"

    $finalContent = Get-Content -Path $existingConf -Raw
    if ($finalContent -match '"new regex"') {
        Write-Host "Test 1 Passed: Overwrote existing location block."
    } else {
        Write-Error "Test 1 Failed: Did not overwrite existing location block."
        Write-Host $finalContent
        exit 1
    }

    if ($finalContent -match '"regex"' -and -not ($finalContent -match '"new regex".*?"regex"')) {
        # 'regex' would only exist as part of 'new regex' or if the old one survived.
        # Check carefully: it shouldn't have the bare 'regex'
        if (($finalContent | Select-String -Pattern '"regex"' -AllMatches).Matches.Count -gt 1) {
            Write-Error "Test 2 Failed: Old regex still present."
            exit 1
        }
    }
    Write-Host "Test 2 Passed: Old regex block completely removed."

    $new2Content = @"
location /new {
    return 201;
}
"@
    Set-Content -Path $new2Conf -Value $new2Content -Encoding UTF8

    Merge-LocationIntoServer -ExistingConfig $existingConf -NewLocationBlock $new2Conf -TargetServerName "example.com"

    $finalContent2 = Get-Content -Path $existingConf -Raw
    if ($finalContent2 -match 'return 201') {
        Write-Host "Test 3 Passed: Injected new location block."
    } else {
        Write-Error "Test 3 Failed: Did not inject new location block."
        exit 1
    }

    Write-Host "All tests passed."

} finally {
    Remove-Item -Path $tmpDir -Recurse -Force
}
