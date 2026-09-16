param (
    [string]$Action = "get"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Getting Flutter dependencies..."
flutter pub get

if ($Action -eq "upgrade") {
    Write-Host "==> Updating dependencies..."
    flutter pub upgrade
}

Write-Host "==> Dependencies setup complete."
