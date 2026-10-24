#!/bin/sh
# Takes the App Store screenshots: ScreenshotUITests on the two sizes App Store Connect requires
# (6.9-inch iPhone, 13-inch iPad; it scales them for the smaller ones), in every language, with
# the status bar at 9:41 and full bars. Writes AppStore/screenshots/<locale>/<device>-<name>.png,
# the layout fastlane deliver reads. The PNGs are not committed: run this before a release.
set -eu

os=26.5
devices="iPhone 17 Pro Max
iPad Pro 13-inch (M5)"
locales="en-US fr-CA"
root=$(cd "$(dirname "$0")/.." && pwd)
output=$root/AppStore/screenshots
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

udid_of() {
    xcrun simctl list devices available -j | python3 -c '
import json, sys
name, os = sys.argv[1], sys.argv[2]
devices = json.load(sys.stdin)["devices"]
runtime = "com.apple.CoreSimulator.SimRuntime.iOS-" + os.replace(".", "-")
print(next(d["udid"] for d in devices.get(runtime, []) if d["name"] == name))' "$1" "$os"
}

# Renames the exported attachments "<device>-<attachment name>.png" into the locale's folder.
collect() {
    python3 - "$1" "$2" "$3" <<'PY'
import json, os, shutil, sys
exported, destination, device = sys.argv[1:]
with open(os.path.join(exported, "manifest.json")) as manifest:
    tests = json.load(manifest)
for test in tests:
    for attachment in test["attachments"]:
        name = attachment["suggestedHumanReadableName"]
        stem = name.split("_")[0]  # Xcode appends "_<index>_<uuid>.png" to the name given
        shutil.copy(os.path.join(exported, attachment["exportedFileName"]),
                    os.path.join(destination, f"{device}-{stem}.png"))
PY
}

cd "$root"
rm -rf "$output"
echo "$devices" | while IFS= read -r device; do
    udid=$(udid_of "$device")
    # A simulator this script boots is shut down after: left running, it dropped the keystrokes
    # of the next KeyboardUITests run.
    booted_here=false
    if xcrun simctl boot "$udid" 2>/dev/null; then booted_here=true; fi
    xcrun simctl bootstatus "$udid" -b >/dev/null
    xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    slug=$(echo "$device" | tr -cd '[:alnum:]')
    for locale in $locales; do
        result=$work/$slug-$locale.xcresult
        TEST_RUNNER_SCREENSHOT_LOCALE=$locale xcodebuild test -project Solitaire.xcodeproj \
            -scheme Solitaire -destination "id=$udid" -only-testing:SolitaireUITests/ScreenshotUITests \
            -resultBundlePath "$result" CODE_SIGNING_ALLOWED=NO -quiet
        mkdir -p "$work/$slug-$locale" "$output/$locale"
        xcrun xcresulttool export attachments --path "$result" --output-path "$work/$slug-$locale" >/dev/null
        collect "$work/$slug-$locale" "$output/$locale" "$slug"
    done
    xcrun simctl status_bar "$udid" clear
    if $booted_here; then xcrun simctl shutdown "$udid"; fi
done
ls -R "$output"
