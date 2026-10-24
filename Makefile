# Lint and format, as CI runs them (brew install swiftlint swiftformat).
.PHONY: lint format

# Checks only; fails on any finding. Both tools read their configuration from the repository root.
lint:
	swiftformat --lint .
	swiftlint lint --strict --quiet

# Rewrites the files SwiftFormat can fix, then reports what SwiftLint still finds.
format:
	swiftformat .
	swiftlint lint --strict --quiet
