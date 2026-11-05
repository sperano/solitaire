#!/bin/sh
# Makes sure the selected Xcode's iOS simulator runtime and the test devices exist, then gives the
# Makefile their ids. The runner images ship an Xcode before its simulator runtime (the xcode-27
# image has Xcode 27.2 with iOS 27.0 and 27.1 simulators only), so a missing runtime is downloaded
# and a missing device created.
#
#   Scripts/ci-simulators.sh <iOS version> <iPhone> <iPad>
#   Scripts/ci-simulators.sh 27.2 "iPhone 17" "iPad Pro 13-inch (M5)"
#
# Writes SIMULATOR=id=<iPhone udid> and IPAD_SIMULATOR=id=<iPad udid> to $GITHUB_ENV; the snapshot
# tests find the iPhone by name and version (SNAPSHOT_SIMULATOR in the Makefile).
set -eu

[ $# -eq 3 ] || { echo "usage: $0 <iOS version> <iPhone> <iPad>" >&2; exit 2; }
os=$1
iphone=$2
ipad=$3
runtime=com.apple.CoreSimulator.SimRuntime.iOS-$(echo "$os" | tr . -)

has_runtime() {
    xcrun simctl list runtimes available -j | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["runtimes"]
sys.exit(0 if any(r["identifier"] == sys.argv[1] for r in runtimes) else 1)' "$runtime"
}

# Prints the udid of the available device named $1 on the runtime, or nothing.
udid_of() {
    xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"].get(sys.argv[2], [])
print(next((d["udid"] for d in devices if d["name"] == sys.argv[1]), ""))' "$1" "$runtime"
}

# Prints the udid of the device named $1 on the runtime, creating it first when it is missing.
device() {
    udid=$(udid_of "$1")
    if [ -z "$udid" ]; then
        echo "Creating $1 on iOS $os" >&2
        udid=$(xcrun simctl create "$1" "$1" "$runtime")
    fi
    echo "$udid"
}

if ! has_runtime; then
    echo "Downloading the iOS simulator runtime of $(xcodebuild -version | head -n 1)"
    xcodebuild -downloadPlatform iOS
    has_runtime || { echo "No iOS $os simulator runtime after the download." >&2; exit 1; }
fi
iphone_udid=$(device "$iphone")
ipad_udid=$(device "$ipad")
echo "$iphone: $iphone_udid, $ipad: $ipad_udid"
{
    echo "SIMULATOR=id=$iphone_udid"
    echo "IPAD_SIMULATOR=id=$ipad_udid"
} >> "${GITHUB_ENV:-/dev/null}"
