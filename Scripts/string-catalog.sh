#!/bin/sh
# Keeps Solitaire/Resources/Localizable.xcstrings in step with the strings the compiler extracts
# from the app's sources (SWIFT_EMIT_LOC_STRINGS in project.yml writes a .stringsdata per file).
#
#   Scripts/string-catalog.sh sync  <derived-data>   add new strings, mark unused ones stale
#   Scripts/string-catalog.sh check <derived-data>   fail if a sync would change the catalog
#
# <derived-data> is the DerivedData directory of a build of the Solitaire scheme. Translations are
# never touched: a new string arrives untranslated and the catalog tests then ask for its French.
set -eu

usage() { echo "usage: $0 sync|check <derived-data>" >&2; exit 2; }
[ $# -eq 2 ] || usage
mode=$1
derived=$2
catalog=Solitaire/Resources/Localizable.xcstrings

list=$(mktemp)
trap 'rm -f "$list"' EXIT
# The app target's files only; the App Intents metadata file is not a source of strings.
find "$derived" -path '*/Solitaire.build/Objects-normal/*/*.stringsdata' \
    ! -name ExtractedAppShortcutsMetadata.stringsdata > "$list"
if [ ! -s "$list" ]; then
    echo "No .stringsdata for the Solitaire target under $derived; build the app first." >&2
    exit 1
fi

case $mode in
sync) target=$catalog ;;
check)
    target=$(mktemp -d)/Localizable.xcstrings
    cp "$catalog" "$target"
    ;;
*) usage ;;
esac

tr '\n' '\0' < "$list" | xargs -0 xcrun xcstringstool sync "$target" --stringsdata

if [ "$mode" = check ] && ! cmp -s "$catalog" "$target"; then
    echo "$catalog does not match the strings in the code; run make strings and commit it:" >&2
    diff -u "$catalog" "$target" | head -80 >&2
    exit 1
fi
