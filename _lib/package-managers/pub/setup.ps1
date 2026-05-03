$ErrorActionPreference = "Stop"

if (-Not (Get-Command pub -ErrorAction SilentlyContinue) -and -Not (Get-Command dart -ErrorAction SilentlyContinue)) {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing Dart via Chocolatey..."
        choco install dart-sdk -y
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "Installing Dart via Scoop..."
        scoop install dart
    } else {
        Write-Host "Neither choco nor scoop found. Cannot automatically install dart/pub."
        exit 1
    }
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "Dart/pub is already installed."
}
