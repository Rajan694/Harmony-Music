param (
    [string]$Device = ""
)

if ($Device -eq "all") {
    Write-Host "Running on ALL connected devices..."
    flutter run --all
} elseif ($Device -ne "") {
    Write-Host "Running on device: $Device..."
    flutter run -d $Device
} else {
    Write-Host "Auto-detecting device..."
    flutter run
}
