# Solitaire

A free Klondike solitaire game for iPhone. No ads, no in-app purchases, no
account, no tracking. It exists because every solitaire in the App Store
interrupts the game with something.

## Features

- Klondike with draw 1 or draw 3 (Settings)
- Tap a card to send it to the best legal spot, or drag it where you want
- Unlimited undo
- Move counter and timer
- Scoring: none, standard (Windows-style points with a time bonus) or Vegas
  ($52 per game, $5 per card on a foundation, limited passes through the
  stock, optional balance carried between games)
- The current game resumes when you reopen the app
- "Finish" button once every card is face up

## Requirements

- iOS 17 or later
- Xcode 26 or later to build
- [xcodegen](https://github.com/yonaskolb/XcodeGen) to regenerate the project
  (`brew install xcodegen`)

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

## Layout

| Path | What it is |
| --- | --- |
| `SolitaireKit/` | Swift package with the game engine: cards, deal, rules, moves, undo, win detection. No UI, no Apple frameworks. |
| `Solitaire/` | The SwiftUI app: views, view model, settings, persistence. |
| `SolitaireTests/` | Unit tests for the app layer (view model, settings, stores, layout metrics). |
| `SolitaireUITests/` | XCUITests that play the game through the accessibility tree. |
| `project.yml` | xcodegen definition of the Xcode project. |
| `.github/workflows/ci.yml` | Runs the package tests and the simulator tests on every PR. |

## Testing

```sh
# Engine, fast, no simulator needed
cd SolitaireKit && swift test

# App unit tests
xcodebuild test -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SolitaireTests

# UI tests
xcodebuild test -project Solitaire.xcodeproj -scheme Solitaire \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SolitaireUITests
```

For deterministic runs, launch with `--ui-testing` (in-memory storage, fresh
settings). Together with it, `-seed <number>` fixes the deal,
`-drawMode 1|3` sets the draw mode and `-scoringMode 0|1|2` sets the scoring
(none, standard, Vegas); a normal launch ignores all three.

## Licence

GPL-3.0, see `LICENSE`.
