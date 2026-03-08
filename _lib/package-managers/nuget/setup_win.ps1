if (-Not (Get-Command nuget -ErrorAction SilentlyContinue)) {
  Write-Host "nuget not found. Please install the .NET SDK, or nuget via chocolatey/winget."
}
