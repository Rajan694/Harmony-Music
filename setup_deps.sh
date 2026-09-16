#!/usr/bin/env bash
set -e

echo "==> Getting Flutter dependencies..."
flutter pub get

echo "==> Updating dependencies (if requested)..."
if [ "$1" == "upgrade" ]; then
    flutter pub upgrade
fi

echo "==> Dependencies setup complete."
