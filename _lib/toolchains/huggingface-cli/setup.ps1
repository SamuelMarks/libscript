$ErrorActionPreference = "Stop"

$HuggingFaceCliVersion = $env:HUGGINGFACE_CLI_VERSION
if ([string]::IsNullOrEmpty($HuggingFaceCliVersion)) {
    $HuggingFaceCliVersion = "latest"
}

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
    $Prefix = "$LibscriptRootDir\installed\huggingface_hub"
}

$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\huggingface-cli.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Installing huggingface-cli into a virtual environment at $Prefix ..."
    
    if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Please install Python."
        exit 1
    }

    & python -m venv "$Prefix\venv"
    
    if ($HuggingFaceCliVersion -eq "latest") {
        & "$Prefix\venv\Scripts\pip.exe" install "huggingface_hub[cli]"
    } else {
        & "$Prefix\venv\Scripts\pip.exe" install "huggingface_hub[cli]==$HuggingFaceCliVersion"
    }

    $CmdContent = @"
@echo off
set "VENV_DIR=%~dp0..\venv"
"%VENV_DIR%\Scripts\huggingface-cli.exe" %*
"@
    Set-Content -Path $ExePath -Value $CmdContent

    Write-Host "huggingface-cli installed to $ExePath"
} else {
    Write-Host "huggingface-cli already installed at $ExePath"
}
