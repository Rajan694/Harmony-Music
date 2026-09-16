#!/usr/bin/env bash
set -e

DEVICE="$1"

usage() {
    echo "Usage: ./run.sh [device-id|all]"
    echo ""
    echo "  No args    - auto-detects single device, or prompts if multiple"
    echo "  device-id  - target specific device (e.g. linux, chrome, emulator-5554)"
    echo "  all        - build and run on each device one by one, each in its own terminal"
    echo ""
    echo "List devices:  flutter devices"
    exit 1
}

open_terminal() {
    local device="$1"
    if command -v gnome-terminal &>/dev/null; then
        gnome-terminal -- bash -c "flutter run -d '$device'; exec bash"
    elif command -v xterm &>/dev/null; then
        xterm -e "flutter run -d '$device'; exec bash" &
    elif command -v konsole &>/dev/null; then
        konsole -e bash -c "flutter run -d '$device'; exec bash" &
    else
        echo "No supported terminal emulator found. Install gnome-terminal, xterm, or konsole."
        exit 1
    fi
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
fi

if [ "$DEVICE" == "all" ]; then
    DEVICES=$(flutter devices 2>/dev/null | awk -F'•' 'NR>1 && NF>=2 {gsub(/ /,"",$2); print $2}' | grep -v '^$')

    if [ -z "$DEVICES" ]; then
        echo "No devices found. Run: flutter devices"
        exit 1
    fi

    echo "Found devices:"
    echo "$DEVICES"
    echo ""

    FIRST=true
    for DEV in $DEVICES; do
        if [ "$FIRST" == "true" ]; then
            echo "Building and running on: $DEV (waiting for build to finish before next)..."
            flutter build apk --debug 2>/dev/null || flutter build bundle --debug 2>/dev/null || true
            open_terminal "$DEV"
            FIRST=false
            echo "Waiting 15s for first device build to settle..."
            sleep 15
        else
            echo "Now launching on: $DEV..."
            open_terminal "$DEV"
            sleep 10
        fi
    done

    echo "All devices launched."

elif [ -n "$DEVICE" ]; then
    echo "Running on device: $DEVICE..."
    flutter run -d "$DEVICE"
else
    echo "Auto-detecting device..."
    flutter run
fi
