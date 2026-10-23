# Solitaire

A free Klondike solitaire game for iPhone. No ads, no in-app purchases, no
account, no tracking. It exists because every solitaire in the App Store
interrupts the game with something.

## Features

- Klondike with draw 1 or draw 3 (Settings)
- Tap a card to send it to the best legal spot, or drag it where you want
- Unlimited undo
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
- Accessibility: full VoiceOver play (every card and pile is described, and
  each card offers its legal moves as actions, so no drag is needed), Dynamic
  Type on the toolbar and settings, Reduce Motion, a high-contrast card style
  with Increase Contrast, and a four-colour deck (Settings → Cards)
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
`-drawMode 1|3` sets the draw mode, `-scoringMode 0|1|2` sets the scoring
(none, standard, Vegas), `-winnableDealsOnly 1` turns the solver check on
and `-position completable|oneMoveFromCompletable|deadlocked`
starts from a fixed board instead of a deal (see `FixturePosition`); a normal
launch ignores them all.

## Licence

GPL-3.0, see `LICENSE`.
