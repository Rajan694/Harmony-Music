param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("android-apk", "android-bundle", "windows", "linux", "macos", "ios")]
    [string]$Platform,

    [ValidateSet("debug", "profile", "release")]
    [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

switch ($Platform) {
    "android-apk" {
        Write-Host "Building Android APK ($BuildType)..."
        flutter build apk --$BuildType
        Write-Host "Artifact: build/app/outputs/flutter-apk/app-$BuildType.apk"
    }
    "android-bundle" {
        Write-Host "Building Android App Bundle ($BuildType)..."
        flutter build appbundle --$BuildType
        Write-Host "Artifact: build/app/outputs/bundle/$BuildType/app-$BuildType.aab"
    }
    "windows" {
        Write-Host "Building Windows ($BuildType)..."
        flutter build windows --$BuildType
        Write-Host "Artifact: build/windows/x64/runner/$BuildType/"
    }
    "linux" {
        Write-Host "Building Linux ($BuildType)..."
        flutter build linux --$BuildType
        Write-Host "Artifact: build/linux/x64/$BuildType/bundle/"
    }
    "macos" {
        Write-Host "Building macOS ($BuildType)..."
        flutter build macos --$BuildType
        Write-Host "Artifact: build/macos/Build/Products/$BuildType/"
    }
    "ios" {
        Write-Host "Building iOS ($BuildType)..."
        flutter build ios --$BuildType --no-codesign
        Write-Host "Artifact: build/ios/iphoneos/Runner.app"
    }
}
