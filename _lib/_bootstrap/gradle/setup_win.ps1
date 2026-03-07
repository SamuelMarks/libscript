$ErrorActionPreference = "Stop"

if (-Not (Get-Command gradle -ErrorAction SilentlyContinue)) {
    if (-Not (Get-Command java -ErrorAction SilentlyContinue)) {
        Write-Host "Java not found. Please install Java first."
        exit 1
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing gradle via Chocolatey..."
        choco install gradle -y
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "Installing gradle via Scoop..."
        scoop install gradle
    } else {
        Write-Host "Neither choco nor scoop found. Cannot automatically install gradle."
        exit 1
    }
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "gradle is already installed."
}
