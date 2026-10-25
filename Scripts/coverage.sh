#!/bin/sh
# Line coverage as a Markdown table, on standard output and, on GitHub Actions, in the job summary.
#
#   Scripts/coverage.sh engine <codecov.json>   SolitaireKit's sources, from `swift test
#                                               --enable-code-coverage`; fails below engine_minimum
#   Scripts/coverage.sh app <result.xcresult>   the app, from one or merged xcodebuild test runs
#
# The engine's <codecov.json> is the llvm-cov export `swift test --show-codecov-path` names. Only
# the engine has a minimum: the app's coverage comes from the simulator tests, which CI runs on main
# only, so a minimum there would fail after the merge instead of on the pull request.
set -eu

# Percent of SolitaireKit's lines its own tests must run.
engine_minimum=90

usage() { echo "usage: $0 engine <codecov.json> | app <result.xcresult>" >&2; exit 2; }
[ $# -ge 2 ] || usage
summary=${GITHUB_STEP_SUMMARY:-/dev/null}
report=$(mktemp)
trap 'rm -f "$report" "$report.md"' EXIT
status=0

case $1 in
engine)
    [ $# -eq 2 ] || usage
    python3 - "$2" "$engine_minimum" > "$report" <<'PY' || status=$?
import json, os, sys

SOURCES = "/Sources/SolitaireKit/"
path, minimum = sys.argv[1], float(sys.argv[2])
files = [f for f in json.load(open(path))["data"][0]["files"] if SOURCES in f["filename"]]
covered = sum(f["summary"]["lines"]["covered"] for f in files)
count = sum(f["summary"]["lines"]["count"] for f in files)
total = 100 * covered / count if count else 0
print("### SolitaireKit coverage\n\n| File | Lines | Coverage |\n| --- | ---: | ---: |")
for f in sorted(files, key=lambda f: f["filename"]):
    lines = f["summary"]["lines"]
    print(f"| {os.path.basename(f['filename'])} | {lines['covered']}/{lines['count']} | {lines['percent']:.1f}% |")
print(f"| **Total** | **{covered}/{count}** | **{total:.2f}%** |\n")
if total < minimum:
    print(f"**Below the {minimum:g}% minimum.**\n")
    sys.exit(1)
print(f"Minimum: {minimum:g}%.\n")
PY
    ;;
app)
    [ $# -eq 2 ] || usage
    xcrun xccov view --report --only-targets --json "$2" > "$report"
    python3 - "$report" <<'PY' > "$report.md"
import json, sys

print("### App test coverage\n\n| Target | Lines | Coverage |\n| --- | ---: | ---: |")
for target in sorted(json.load(open(sys.argv[1])), key=lambda t: t["name"]):
    lines = f"{target['coveredLines']}/{target['executableLines']}"
    print(f"| {target['name']} | {lines} | {100 * target['lineCoverage']:.1f}% |")
print()
PY
    mv "$report.md" "$report"
    ;;
*) usage ;;
esac

tee -a "$summary" < "$report"
exit "$status"
