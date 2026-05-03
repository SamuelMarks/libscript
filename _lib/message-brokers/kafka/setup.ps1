[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MinioVersion = $env:KAFKA_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

$InstallMethod = $env:KAFKA_INSTALL_METHOD
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
        winget install Apache.Kafka
    } elseif ($PkgMgr -eq "choco") {
        choco install kafka
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
    } else {
        $Prefix = $env:PREFIX
        if ([string]::IsNullOrEmpty($Prefix)) {
            $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
            $Prefix = "$LibscriptRootDir\installed\kafka"
        }

        if ($KafkaVersion -eq "latest") {
            $KafkaVersion = "3.9.0"
        }
        $ScalaVersion = "2.13"

        $Url = "https://dlcdn.apache.org/kafka/${KafkaVersion}/kafka_${ScalaVersion}-${KafkaVersion}.tgz"
        $TgzPath = "$env:TEMP\kafka.tgz"

        Write-Host "Downloading Kafka from $Url ..."
        Invoke-WebRequest -Uri $Url -OutFile $TgzPath -UseBasicParsing

        # Needs 7z to extract tgz on windows easily if not using tar natively.
        # We will try native tar (Windows 10+)
        if (-not (Test-Path -Path $Prefix)) {
            New-Item -ItemType Directory -Path $Prefix -Force | Out-Null
        }
        tar -xzf $TgzPath -C $Prefix --strip-components=1

        Remove-Item -Path $TgzPath -Force

        Write-Host "Kafka installed to $Prefix"
    }
