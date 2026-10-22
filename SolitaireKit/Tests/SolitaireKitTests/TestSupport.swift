import XCTest
@testable import SolitaireKit

/// Shorthand card constructor; cards are face up unless stated otherwise.
func card(_ rank: Rank, _ suit: Suit, up: Bool = true) -> Card {
    Card(suit: suit, rank: rank, isFaceUp: up)
}

/// A position in the initial deal: `row` is the index within `column`.
struct TableauSlot: Hashable {
    let column: Int
    let row: Int
}

let stockCardCount = Deck.cardCount - GameState.tableauCardCount

/// Slots in the order the dealer consumes cards (first dealt = last array element).
private let dealOrder: [TableauSlot] = (0 ..< GameState.tableauColumnCount).flatMap { row in
    (row ..< GameState.tableauColumnCount).map { TableauSlot(column: $0, row: row) }
}

/// A full deck where the given cards land in known tableau slots and on top of the stock
/// (`stockTop[0]` is the top). All other cards fill the remaining positions in standard order.
func orderedDeck(tableau: [TableauSlot: Card] = [:], stockTop: [Card] = []) -> [Card] {
    var placed = [Int: Card]()
    for (dealt, slot) in dealOrder.enumerated() {
        if let c = tableau[slot] { placed[Deck.cardCount - 1 - dealt] = c.faceDown() }
    }
    for (offset, c) in stockTop.enumerated() { placed[stockCardCount - 1 - offset] = c.faceDown() }
    precondition(placed.count == tableau.count + stockTop.count, "slots overlap")
    let used = Set(placed.values.map(\.id))
    precondition(used.count == placed.count, "duplicate card requested")
    var filler = Deck.standard().filter { !used.contains($0.id) }.makeIterator()
    return (0 ..< Deck.cardCount).map { placed[$0] ?? filler.next()! }
}

/// A state with exactly the piles given (all others empty). Cards are taken as written.
func blankState(
    drawMode: DrawMode = .one,
    tableau: [[Card]] = [],
    stock: [Card] = [],
    waste: [Card] = [],
    foundations: [[Card]] = []
) -> GameState {
    var state = GameState.deal(seed: 0, drawMode: drawMode)
    state.stock = stock
    state.waste = waste
    state.foundations = foundations + Array(repeating: [], count: GameState.foundationCount - foundations.count)
    state.tableau = tableau + Array(repeating: [], count: GameState.tableauColumnCount - tableau.count)
    return state
}

func fullSuit(_ suit: Suit) -> [Card] {
    Rank.allCases.map { card($0, suit) }
}

func assertThrows(
    _ expected: MoveError, _ state: GameState, _ move: Move,
    file: StaticString = #filePath, line: UInt = #line
) {
    var copy = state
    XCTAssertThrowsError(try copy.apply(move), file: file, line: line) {
        XCTAssertEqual($0 as? MoveError, expected, file: file, line: line)
    }
    XCTAssertEqual(copy, state, "failed move must not change state", file: file, line: line)
}
