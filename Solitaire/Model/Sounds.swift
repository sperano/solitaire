import AVFoundation
import SolitaireKit

/// What the player hears. Each one is a bundled recording (`Resources/Sounds`, credited in `Design/Sounds`).
enum SoundEffect: CaseIterable, Equatable {
    /// Cards turned from the stock, or the waste turned back into the stock.
    case draw
    /// Cards put on a pile.
    case place
    /// A tableau card turned face up by the move that uncovered it.
    case flip
    case undo
    case win

    static let fileExtension = "m4a"

    var resourceName: String {
        switch self {
        case .draw: "draw"
        case .place: "place"
        case .flip: "flip"
        case .undo: "undo"
        case .win: "win"
        }
    }

    /// The sounds of the move or redo that took the board from `old` to `new`.
    static func effects(from old: GameState, to new: GameState) -> [SoundEffect] {
        var effects: [SoundEffect] = old.pile(.stock).count == new.pile(.stock).count ? [.place] : [.draw]
        if faceDownCount(new) < faceDownCount(old) { effects.append(.flip) }
        if new.isWon { effects.append(.win) }
        return effects
    }

    private static func faceDownCount(_ state: GameState) -> Int {
        PileID.allTableau.reduce(0) { count, pile in count + state.pile(pile).count(where: { !$0.isFaceUp }) }
    }
}

@MainActor
protocol SoundPlayer {
    func play(_ effect: SoundEffect)
}

/// Plays the bundled sounds in the ambient audio session: the silent switch mutes them and they
/// mix with music from other apps instead of stopping it. The session is set up on the first sound,
/// so with sound effects off the app never touches it.
@MainActor
final class SystemSounds: SoundPlayer {
    private let bundle: Bundle
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var isSessionReady = false

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func play(_ effect: SoundEffect) {
        prepareSession()
        guard let player = player(for: effect) else { return }
        player.currentTime = 0
        player.play()
    }

    private func prepareSession() {
        guard !isSessionReady else { return }
        isSessionReady = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)
        try? session.setActive(true)
    }

    private func player(for effect: SoundEffect) -> AVAudioPlayer? {
        if let player = players[effect] { return player }
        guard let url = bundle.url(forResource: effect.resourceName, withExtension: SoundEffect.fileExtension),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        player.prepareToPlay()
        players[effect] = player
        return player
    }
}

/// Plays nothing; for previews and tests that don't check sounds.
@MainActor
final class SilentSounds: SoundPlayer {
    func play(_ effect: SoundEffect) {}
}
