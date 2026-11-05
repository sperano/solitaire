# The checks, as CI runs them: lint and the engine tests (brew install swiftlint swiftformat), the
# String Catalog, and the app's build, unit, snapshot and UI tests on the simulators.
.PHONY: lint format strings check-strings coverage check-project build unit snapshot record-snapshots \
	ui ipad app-coverage

# Recipes use pipefail so a test failure is not lost in the pipe to the formatter.
SHELL := /bin/bash

# The destinations, overridable from the environment or the command line (CI passes the newest
# iPhone and iPad it has, by id). The snapshot images are recorded on SNAPSHOT_SIMULATOR; the
# snapshot tests skip on any other.
SIMULATOR ?= platform=iOS Simulator,name=iPhone 17
IPAD_SIMULATOR ?= platform=iOS Simulator,name=iPad Pro 13-inch (M5)
SNAPSHOT_SIMULATOR ?= platform=iOS Simulator,name=iPhone 17,OS=27.2

# Fixed artifact paths: one result bundle per target, and the failed snapshots with their diffs.
# Everything is under build/, which git ignores. One DerivedData for every target, so a target run
# after another builds incrementally.
DERIVED_DATA = build/DerivedData
RESULTS = build/results
TEST_RUNNER_SNAPSHOT_ARTIFACTS ?= $(CURDIR)/build/snapshot-failures
export TEST_RUNNER_SNAPSHOT_ARTIFACTS

# xcodebuild's output goes through xcbeautify when it is installed; CI adds its GitHub renderer.
XCBEAUTIFY ?= $(if $(shell command -v xcbeautify),xcbeautify,cat)

XCODEBUILD = xcodebuild -project Solitaire.xcodeproj -scheme Solitaire -derivedDataPath $(DERIVED_DATA) \
	CODE_SIGNING_ALLOWED=NO
# $(call xcodebuild,<action>,<result bundle name>,<destination>,<options>): runs xcodebuild with a
# fresh result bundle at $(RESULTS)/<name>.xcresult (xcodebuild refuses to overwrite one).
xcodebuild = mkdir -p $(RESULTS) && rm -rf $(RESULTS)/$(2).xcresult && set -o pipefail && \
	$(XCODEBUILD) $(1) -destination '$(3)' $(4) -resultBundlePath $(RESULTS)/$(2).xcresult | $(XCBEAUTIFY)

UI_ON_IPAD = -only-testing:SolitaireUITests/LayoutUITests -only-testing:SolitaireUITests/KeyboardUITests
STRINGS_BUILD = $(XCODEBUILD) build -destination '$(SIMULATOR)' -quiet

# Checks only; fails on any finding. Both tools read their configuration from the repository root.
lint:
	swiftformat --lint .
	swiftlint lint --strict --quiet

# Rewrites the files SwiftFormat can fix, then reports what SwiftLint still finds.
format:
	swiftformat .
	swiftlint lint --strict --quiet

# Adds the strings the code uses to Localizable.xcstrings and marks the unused ones stale, as
# building in Xcode does. Translate what it adds; the catalog tests fail until every key has French.
strings:
	$(STRINGS_BUILD)
	Scripts/string-catalog.sh sync $(DERIVED_DATA)

# Fails when the catalog is behind the code, as CI checks it.
check-strings:
	$(STRINGS_BUILD)
	Scripts/string-catalog.sh check $(DERIVED_DATA)

# Runs the engine tests with coverage and fails below the minimum CI enforces (Scripts/coverage.sh).
coverage:
	cd SolitaireKit && swift test --parallel --enable-code-coverage
	Scripts/coverage.sh engine "$$(cd SolitaireKit && swift test --show-codecov-path)"

# Fails when the committed Solitaire.xcodeproj is not what xcodegen generates from project.yml.
check-project:
	xcodegen generate
	@changes=$$(git status --porcelain --untracked-files=all -- Solitaire.xcodeproj); \
	if [ -n "$$changes" ]; then \
		echo "Solitaire.xcodeproj is out of date; run xcodegen generate and commit:"; \
		echo "$$changes"; \
		exit 1; \
	fi

# Builds the app and every test target, without running a test.
build:
	$(call xcodebuild,build-for-testing,build,$(SIMULATOR))

unit:
	$(call xcodebuild,test,unit,$(SIMULATOR),-only-testing:SolitaireTests)

snapshot:
	$(call xcodebuild,test,snapshot,$(SNAPSHOT_SIMULATOR),-only-testing:SolitaireSnapshotTests)

# Rewrites the reference PNGs in place, then checks them with a normal snapshot run. Recording
# reports every snapshot test as failed ("Record mode is on"), so its status is ignored and the
# second run decides. Review the changed images before committing them.
record-snapshots:
	export TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all && \
	$(call xcodebuild,test,record-snapshots,$(SNAPSHOT_SIMULATOR),-only-testing:SolitaireSnapshotTests) || true
	$(MAKE) snapshot

ui:
	$(call xcodebuild,test,ui,$(SIMULATOR),-only-testing:SolitaireUITests)

# The layout and keyboard UI tests again, on an iPad.
ipad:
	$(call xcodebuild,test,ipad,$(IPAD_SIMULATOR),$(UI_ON_IPAD))

# The app's lines run by the iPhone unit, snapshot and UI tests together: a report, no minimum. Run
# after unit, snapshot and ui.
app-coverage:
	rm -rf $(RESULTS)/iphone.xcresult
	xcrun xcresulttool merge $(RESULTS)/unit.xcresult $(RESULTS)/snapshot.xcresult $(RESULTS)/ui.xcresult \
		--output-path $(RESULTS)/iphone.xcresult
	Scripts/coverage.sh app $(RESULTS)/iphone.xcresult
