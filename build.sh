#!/usr/bin/env bash
set -e

PLATFORM="$1"
BUILD_TYPE="${2:-release}"

usage() {
    echo "Usage: ./build.sh <android-apk|android-bundle|windows|linux|macos|ios> [debug|profile|release]"
    exit 1
}

if [ -z "$PLATFORM" ]; then
    usage
fi

case "$PLATFORM" in
    android-apk|apk)
        echo "Building Android APK ($BUILD_TYPE)..."
        flutter build apk "--$BUILD_TYPE"
        echo "Artifact: build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
        ;;
    android-bundle|aab)
        echo "Building Android App Bundle ($BUILD_TYPE)..."
        flutter build appbundle "--$BUILD_TYPE"
        echo "Artifact: build/app/outputs/bundle/${BUILD_TYPE}/app-$BUILD_TYPE.aab"
        ;;
    linux)
        echo "Building Linux ($BUILD_TYPE)..."
        flutter build linux "--$BUILD_TYPE"
        echo "Artifact: build/linux/x64/$BUILD_TYPE/bundle/"
        ;;
    windows)
        echo "Building Windows ($BUILD_TYPE)..."
        flutter build windows "--$BUILD_TYPE"
        echo "Artifact: build/windows/x64/runner/$BUILD_TYPE/"
        ;;
    macos)
        echo "Building macOS ($BUILD_TYPE)..."
        flutter build macos "--$BUILD_TYPE"
        echo "Artifact: build/macos/Build/Products/$BUILD_TYPE/"
        ;;
    ios)
        echo "Building iOS ($BUILD_TYPE)..."
        flutter build ios "--$BUILD_TYPE" --no-codesign
        echo "Artifact: build/ios/iphoneos/Runner.app"
        ;;
    *)
        echo "Unsupported platform: $PLATFORM"
        usage
        ;;
esac
