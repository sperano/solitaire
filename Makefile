# Lint and format, as CI runs them (brew install swiftlint swiftformat), and the String Catalog.
.PHONY: lint format strings check-strings coverage

STRINGS_DERIVED_DATA = build/strings
STRINGS_BUILD = xcodebuild build -project Solitaire.xcodeproj -scheme Solitaire \
	-destination 'platform=iOS Simulator,name=iPhone 17' \
	-derivedDataPath $(STRINGS_DERIVED_DATA) CODE_SIGNING_ALLOWED=NO -quiet

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
	Scripts/string-catalog.sh sync $(STRINGS_DERIVED_DATA)

# Fails when the catalog is behind the code, as CI checks it.
check-strings:
	$(STRINGS_BUILD)
	Scripts/string-catalog.sh check $(STRINGS_DERIVED_DATA)

# Runs the engine tests with coverage and fails below the minimum CI enforces (Scripts/coverage.sh).
coverage:
	cd SolitaireKit && swift test --parallel --enable-code-coverage
	Scripts/coverage.sh engine "$$(cd SolitaireKit && swift test --show-codecov-path)"
