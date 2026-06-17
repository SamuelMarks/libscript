$ErrorActionPreference = "Stop"

$GcpCliVersion = $env:GCP_CLI_VERSION
if ([string]::IsNullOrEmpty($GcpCliVersion)) {
    $GcpCliVersion = "latest"
}

$InstallMethod = $env:GCP_CLI_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "source"
}

if ($InstallMethod -eq "system") {
    $PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
    if ([string]::IsNullOrEmpty($PkgMgr)) {
        $PkgMgr = "winget"
    }
    if ($PkgMgr -eq "winget") {
        winget install Google.CloudSDK
    } elseif ($PkgMgr -eq "choco") {
        choco install gcloudsdk
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\gcp-cli"
    }

    if ($GcpCliVersion -eq "latest") {
        $GcpCliVersion = "476.0.0"
    }

    if (-not (Test-Path -Path "$Prefix\bin\gcloud.cmd")) {
        $Url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GcpCliVersion}-windows-x86_64.zip"

        Write-Host "Downloading GCP CLI from $Url ..."
        $ZipPath = "$Prefix\google-cloud-cli.zip"
        
        if (-not (Test-Path -Path $Prefix)) {
            New-Item -ItemType Directory -Path $Prefix -Force | Out-Null
        }

        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
        Write-Host "Extracting archive..."
        Expand-Archive -Path $ZipPath -DestinationPath $Prefix -Force
        Remove-Item -Path $ZipPath

        $ExtractedFolder = "$Prefix\google-cloud-sdk"
        if (Test-Path -Path $ExtractedFolder) {
            Move-Item -Path "$ExtractedFolder\*" -Destination $Prefix -Force
            Remove-Item -Path $ExtractedFolder -Recurse
        }

        & "$Prefix\install.bat" --quiet
        & "$Prefix\bin\gcloud.cmd" components install alpha beta compute --quiet

        Write-Host "GCP CLI installed to $Prefix"
    } else {
        Write-Host "GCP CLI already installed at $Prefix\bin\gcloud.cmd"
    }

    $AuthOutput = & "$Prefix\bin\gcloud.cmd" auth print-access-token 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "No valid auth found. Running gcloud auth login..."
        & "$Prefix\bin\gcloud.cmd" auth login
    }
}
