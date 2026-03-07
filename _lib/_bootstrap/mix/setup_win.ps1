$ErrorActionPreference = "Stop"

if (-Not (Get-Command mix -ErrorAction SilentlyContinue)) {
    if (-Not (Get-Command elixir -ErrorAction SilentlyContinue)) {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Installing Elixir (with mix) via Chocolatey..."
            choco install elixir -y
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Host "Installing Elixir via Scoop..."
            scoop install elixir
        } else {
            Write-Host "Neither choco nor scoop found. Cannot automatically install elixir/mix."
            exit 1
        }
        
        # Reload PATH
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $env:PATH = "$userPath;$machinePath"
    } else {
        Write-Host "Elixir is installed, but mix is not found in PATH."
    }
} else {
    Write-Host "mix is already installed."
}

if (Get-Command mix -ErrorAction SilentlyContinue) {
    mix local.hex --force
    mix local.rebar --force
}
