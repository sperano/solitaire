# Solitaire

A free Klondike solitaire game for iPhone. No ads, no in-app purchases, no
account, no tracking. It exists because every solitaire in the App Store
interrupts the game with something.

## Features

- Klondike with draw 1 or draw 3 (Settings)
- Tap a card to send it to the best legal spot, or drag it where you want
- Unlimited undo, and redo of what was undone until the next move
- Move counter and timer; the clock pauses in the background and while
  Settings are open, and can be turned off for untimed games (no time bonus,
  no best time)
- Scoring: none, standard (Windows-style points with a time bonus) or Vegas
  ($52 per game, $5 per card on a foundation, limited passes through the
  stock, optional balance carried between games)
- Statistics per draw mode and overall: games played and won, win rate, best
  time, fewest moves, current and longest win streak (Settings → Statistics);
  abandoning a started game counts as a loss
- Cards fly between piles, turn over and are dealt from the stock; a bouncing
  cascade celebrates the win; haptic feedback on moves, refused moves and the
  win (Settings → Play → Haptics)
- Left-handed layout: stock and waste on the right of the top row, under the
  left thumb (Settings → Play)
- Accessibility: full VoiceOver play (every card and pile is described, and
  each card offers its legal moves as actions, so no drag is needed), Dynamic
  Type on the toolbar and settings, Reduce Motion, a high-contrast card style
  with Increase Contrast, a four-colour deck and large print (Settings → Cards)
- Three card-back designs and four table colours (Settings → Cards)
- The current game resumes when you reopen the app
- "Finish" button once every card is face up, or finish automatically
  (Settings → Finish automatically)
- Hint button: highlights a useful move (a card to a foundation, a run that
  uncovers a face-down card, a waste card to the tableau, then the draw), or
  says that no useful move is left
- Deal numbers: every deal has a number (Settings → Deal) to share or type
  in to play that deal; "Replay This Deal" in the new-game dialog starts the
  same deal over
- Winnable deals only (Settings → Rules): new games are dealt until a solver
  finds a way to win them
- English and French (Canada), following the language set on the device

## Devices

iPhone in portrait and landscape, iPad in every orientation, including Split
View and Stage Manager windows: the cards take the width of the board unless
its height is the tighter limit, as in landscape, and then the board is
centred. With a hardware keyboard, ⌘Z undoes, ⇧⌘Z redoes, ⌘N starts a new
game (asking first when a started game would be lost) and the space bar
draws; hold ⌘ on an iPad to see them.

## Requirements

- iOS 17 or later
- Xcode 26 or later to build
- [xcodegen](https://github.com/yonaskolb/XcodeGen) to regenerate the project
  (`brew install xcodegen`)
- [SwiftLint](https://github.com/realm/SwiftLint) and
  [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for `make lint`
  (`brew install swiftlint swiftformat`)

## Building

```sh
xcodegen generate            # only after changing project.yml or adding files
open Solitaire.xcodeproj     # then run the Solitaire scheme on a simulator
```

From the command line:

```sh
xcodebuild build -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## App icon and launch screen

The icon is two cards on the felt: the stock face down and a heart turned
over. `Design/AppIcon.svg` is the artwork; its colours are CSS variables at
the top of the file, and `Design/render_icons.swift` renders the light icon
and, with the background left clear for the system's own gradient, the dark
and the grey tinted icons into the asset catalog:

```sh
swift Design/render_icons.swift     # after editing Design/AppIcon.svg; commit the PNGs
```

The launch screen is the felt alone, from the same `Felt` colour asset the
board paints, so the game appears without a flash. `AppIconTests` and
`LaunchScreenTests` check the icon set and that the three greens agree.

## Languages

The app is in English and French (Canada). Every string the player reads or
VoiceOver speaks is in the String Catalog `Solitaire/Resources/Localizable.xcstrings`:
SwiftUI looks up the literals in `Text`, `Button`, `Toggle` and the like by
themselves, and text built in code goes through `String(localized:)`. The
compiler records every such string as it builds (`SWIFT_EMIT_LOC_STRINGS`), and
building in Xcode adds new ones to the catalog. From the command line:

```sh
make strings          # add the strings the code uses to the catalog, mark unused ones stale
make check-strings    # fail if the catalog is behind the code, as CI checks it
```

`LocalizableCatalogTests` fails until every key has a French translation, with
every plural form and the same arguments as the English, and no key is stale.
Card, suit and mode names live in the app (`DisplayNames.swift`), not in the
engine. Ranks have a second form for use inside a sentence, because French
says "le sept de cœur" where English says "seven of hearts".

The App Store text is under `AppStore/metadata/<locale>/`, one file per App
Store Connect field (the layout fastlane deliver reads); `AppStoreMetadataTests`
checks both languages have every field within the store's length limits.
`LocalizationUITests` launches the app in French.

## Releasing

A release is a tag. Pushing `v<MARKETING_VERSION>` (the version in
`project.yml`, three numbers, such as `v1.0.0`) on a commit of `main` whose CI
passed runs `.github/workflows/release.yml`: it archives the app in Release,
signs it with the App Store Connect API key and uploads it, and the build
appears in TestFlight. The build number is the workflow's run number, so it
grows with every upload; upload only through the workflow, or a build made in
Xcode can take a number the workflow will reach later.

```sh
# after bumping MARKETING_VERSION in project.yml (xcodegen generate) and merging it
git tag v1.0.0 origin/main && git push origin v1.0.0
```

The workflow needs four repository secrets:

| Secret | What it is |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY` | The `.p8` key file's contents (App Store Connect, Users and Access, Integrations; role Admin, which cloud-managed signing needs). |
| `APP_STORE_CONNECT_KEY_ID` | The key's ID. |
| `APP_STORE_CONNECT_ISSUER_ID` | The issuer ID shown above the keys. |
| `APPLE_TEAM_ID` | The team ID (Membership details in the developer account). |

Before the first upload, the app record must exist in App Store Connect, with
the bundle ID `quebec.spe.Solitaire`.

The store listing is under `AppStore/metadata/`: name, subtitle, description,
keywords, promotional text, privacy policy and support URLs per language, and
the copyright and category (fastlane deliver reads this layout, or copy the
fields into App Store Connect). From the second version on, each language gets
a `release_notes.txt` for the version; the first version takes none.
`AppStoreMetadataTests` checks the fields and their length limits. The privacy
policy is `PRIVACY.md` (`PRIVACY.fr-CA.md` in French).

Privacy: `Solitaire/Resources/PrivacyInfo.xcprivacy` declares no tracking and
no data collected, and the one API Apple asks a reason for, `UserDefaults`
(settings the app keeps for itself). In App Store Connect the App Privacy
answer is "Data Not Collected". `PrivacyManifestTests` fails if the code starts
using another API that needs a reason before the manifest declares it.

Screenshots: `Scripts/screenshots.sh` runs `ScreenshotUITests` on the 6.9-inch
iPhone and the 13-inch iPad simulators (iOS 26.5), the two sizes App Store
Connect requires, in English and French, with the status bar at 9:41, and
writes `AppStore/screenshots/<locale>/`. Run it before a release; the images
are not committed. The test skips in normal runs.

## Layout

| Path | What it is |
| --- | --- |
| `SolitaireKit/` | Swift package with the game engine: cards, deal, rules, moves, undo, win detection. No UI, no Apple frameworks. |
| `Solitaire/` | The SwiftUI app: views, view model, settings, persistence. |
| `SolitaireTests/` | Unit tests for the app layer (view model, settings, stores, layout metrics). |
| `SolitaireUITests/` | XCUITests that play the game through the accessibility tree. |
| `SolitaireSnapshotTests/` | Image comparisons of the cards, the board (also at three screen sizes in both orientations), the win panel and Settings against the PNGs in `__Snapshots__`. |
| `Design/` | The app icon's source artwork (`AppIcon.svg`) and the script that renders the icon variants from it. |
| `AppStore/metadata/` | App Store name, subtitle, description, keywords, promotional text and URLs, in English and French, plus copyright and category. |
| `AppStore/ExportOptions.plist` | How the release workflow signs and uploads the archive. |
| `PRIVACY.md`, `PRIVACY.fr-CA.md` | The privacy policy the App Store listing links to. |
| `Scripts/string-catalog.sh` | Syncs or checks the String Catalog against the strings the compiler extracted (`make strings`, `make check-strings`). |
| `Scripts/coverage.sh` | Line coverage as a table: the engine's, with its minimum (`make coverage`), or the app's from a test result bundle. CI puts both in the job summary. |
| `Scripts/screenshots.sh` | Takes the App Store screenshots (see Releasing). |
| `project.yml` | xcodegen definition of the Xcode project. |
| `.swiftformat`, `.swiftlint.yml`, `Makefile` | Formatting and lint rules; `make lint` checks, `make format` rewrites. |
| `.github/workflows/ci.yml` | Lints and runs the package tests, with their coverage minimum, on every PR and push to `main`; on pushes to `main` only, for now, it also runs the simulator and snapshot tests, checks the String Catalog and reports the app's coverage. |
| `.github/workflows/release.yml` | On a version tag, archives the app and uploads it to TestFlight. |

## Testing

```sh
# Formatting and lint, as CI checks them; `make format` rewrites what SwiftFormat can fix
make lint

# Engine, fast, no simulator needed
cd SolitaireKit && swift test

# Engine line coverage per file; fails below the minimum CI enforces (Scripts/coverage.sh)
make coverage

# App unit tests
xcodebuild test -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SolitaireTests

# UI tests
xcodebuild test -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SolitaireUITests

# Layout and keyboard UI tests on an iPad (CI runs these on an iPad as well as an iPhone)
xcodebuild test -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:SolitaireUITests/LayoutUITests -only-testing:SolitaireUITests/KeyboardUITests

# Snapshot tests, on the simulator the images were recorded on
xcodebuild test -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:SolitaireSnapshotTests
```

For deterministic runs, launch with `--ui-testing` (in-memory storage, fresh
settings). Together with it, `-seed <number>` fixes the deal,
`-drawMode 1|3` sets the draw mode, `-scoringMode 0|1|2` sets the scoring
(none, standard, Vegas), `-winnableDealsOnly 1` turns the solver check on
and `-position completable|oneMoveFromCompletable|deadlocked`
starts from a fixed board instead of a deal (see `FixturePosition`); a normal
launch ignores them all.

### Snapshot tests

`SolitaireSnapshotTests` renders the views with
[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
and compares them pixel for pixel (within a small tolerance) with the PNGs
committed under `SolitaireSnapshotTests/__Snapshots__`: every card face and
the back in each card style (large print too), every card back on every
table colour, the board at the deal, mid-game with a lifted run, mid-game in
large print and left-handed with a fanned waste, the win panel and the
Settings screen, in light and dark mode, and the board at the iPhone SE, iPhone Pro Max and iPad Pro sizes in both
orientations (`LayoutSnapshotTests`, light mode, drawn at those sizes on the
same simulator). The images are recorded on the iPhone 17 simulator running
iOS 26.5, the one CI uses; on any other simulator the tests skip, since the
screen size would not match.

After a deliberate change to how something looks, re-record and commit the
new images:

```sh
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test \
  -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:SolitaireSnapshotTests
```

A recording run reports every snapshot test as failed ("Record mode is on");
that is expected. Review the changed PNGs before committing them. When a
snapshot fails on CI, the failed image and a diff are uploaded as the
`snapshot-failures` artifact of the run.

## Licence

GPL-3.0, see `LICENSE`.
