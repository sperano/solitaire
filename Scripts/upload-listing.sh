#!/bin/sh
# Uploads the App Store listing with fastlane deliver (AppStore/Deliverfile): the text of every
# locale in AppStore/metadata, the category, copyright, age rating, review information and the
# screenshots in AppStore/screenshots (run Scripts/screenshots.sh first). It edits the version in
# project.yml's MARKETING_VERSION, creating it when App Store Connect has none. Run on a Mac with the
# release API key:
#
#   Scripts/upload-listing.sh <AuthKey_<KEYID>.p8> <issuer id> [--submit]
#
# deliver shows an HTML preview and asks before uploading. --submit then submits the version for
# review; that needs a build chosen (the release workflow's upload). The review contact details
# come from REVIEW_FIRST_NAME, REVIEW_LAST_NAME, REVIEW_PHONE (+<country code> <number>) and
# REVIEW_EMAIL: a version's first upload needs all four, later an unset one keeps what App Store
# Connect has. fastlane's usage reporting and update check are turned off.
set -eu

usage() { echo "usage: $0 <AuthKey_<KEYID>.p8> <issuer id> [--submit]" >&2; exit 2; }
[ $# -eq 2 ] || [ $# -eq 3 ] || usage
key_file=$1
issuer_id=$2
submit=false
if [ $# -eq 3 ]; then
    [ "$3" = --submit ] || usage
    submit=true
fi
[ -f "$key_file" ] || { echo "No key file at $key_file." >&2; exit 1; }
key_id=$(basename "$key_file" .p8 | sed -n 's/^AuthKey_//p')
[ -n "$key_id" ] || { echo "The key file must be named AuthKey_<KEYID>.p8, as Apple names it." >&2; exit 1; }

root=$(cd "$(dirname "$0")/.." && pwd)
store=$root/AppStore
version=$(sed -n 's/^ *MARKETING_VERSION: *"*\([0-9.]*\)"*$/\1/p' "$root/project.yml")
[ -n "$version" ] || { echo "No MARKETING_VERSION in project.yml." >&2; exit 1; }

# Every locale needs its screenshots: deliver would otherwise upload a listing without them.
for locale in $(find "$store/metadata" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort); do
    if ! ls "$store/screenshots/$locale/"*.png >/dev/null 2>&1; then
        echo "No screenshots for $locale: run Scripts/screenshots.sh first." >&2
        exit 1
    fi
done

# The key file deliver reads holds the private key: only this user can read it, and it is deleted
# on exit.
work=$(umask 077 && mktemp -d)
trap 'rm -rf "$work"' EXIT
python3 - "$key_id" "$issuer_id" "$key_file" "$work/api_key.json" <<'PY'
import json, sys
key_id, issuer_id, key_file, output = sys.argv[1:]
with open(key_file) as key, open(output, "w") as out:
    json.dump({"key_id": key_id, "issuer_id": issuer_id, "key": key.read(), "in_house": False}, out)
PY

export FASTLANE_OPT_OUT_USAGE=YES FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_HIDE_CHANGELOG=1
export BUNDLE_GEMFILE="$store/Gemfile" BUNDLE_PATH="$root/build/bundle"
bundle install --quiet
cd "$store"
bundle exec fastlane deliver --api_key_path "$work/api_key.json" --app_version "$version" \
    --submit_for_review "$submit"
