#!/bin/sh
# Selects Xcode <version> for the rest of a GitHub Actions job and fails unless xcodebuild reports
# exactly that version: the runner images change their default Xcode as new ones come out.
#
#   Scripts/select-xcode.sh 27.2
#
# The runner images install every Xcode as /Applications/Xcode_<version>.app (a link to the release
# candidate while there is no release). The job's later steps get DEVELOPER_DIR, which xcodebuild,
# xcrun, swift and SwiftLint's SourceKit all follow.
set -eu

[ $# -eq 1 ] || { echo "usage: $0 <Xcode version>" >&2; exit 2; }
version=$1
developer_dir=/Applications/Xcode_$version.app/Contents/Developer
if [ ! -d "$developer_dir" ]; then
    echo "Xcode $version is not installed at $developer_dir; installed:" >&2
    ls -d /Applications/Xcode*.app >&2 || true
    exit 1
fi
export DEVELOPER_DIR=$developer_dir
echo "DEVELOPER_DIR=$developer_dir" >> "${GITHUB_ENV:-/dev/null}"

xcodebuild -version
swift --version
reported=$(xcodebuild -version | head -n 1)
if [ "$reported" != "Xcode $version" ]; then
    echo "$developer_dir is $reported, not Xcode $version." >&2
    exit 1
fi
