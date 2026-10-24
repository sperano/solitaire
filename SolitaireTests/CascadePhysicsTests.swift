import CoreGraphics
import XCTest
@testable import Solitaire

final class CascadePhysicsTests: XCTestCase {
    private static let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
    private static let cardSize = CGSize(width: 50, height: 70)
    private static let start = CGPoint(x: 250, y: 120)
    private static let launches = 0 ..< 52
    private let physics = CascadePhysics(bounds: bounds, cardSize: cardSize)

    private var floor: CGFloat { Self.bounds.maxY - Self.cardSize.height / 2 }

    func testEveryTrajectoryStartsAtTheFoundationAndLeavesTheScreen() throws {
        for number in Self.launches {
            let points = physics.trajectory(launchNumber: number, from: Self.start)
            XCTAssertEqual(points.first, Self.start)
            let last = try XCTUnwrap(points.last)
            let fastest = CascadePhysics.minimumHorizontalSpeed + Double(CascadePhysics.horizontalSpeedSpread)
            let step = CascadePhysics.timeStep * fastest
            let nearEdge = last.x - Self.cardSize.width / 2 <= Self.bounds.minX + step
                || last.x + Self.cardSize.width / 2 >= Self.bounds.maxX - step
            XCTAssertTrue(nearEdge, "launch \(number) ended at \(last)")
        }
    }

    func testCardsNeverGoThroughTheBottomAndDoBounce() {
        let points = physics.trajectory(launchNumber: 1, from: Self.start)
        XCTAssertTrue(points.allSatisfy { $0.y <= floor })
        let bounces = zip(points, points.dropFirst()).filter { $0.y == floor && $1.y < floor }
        XCTAssertFalse(bounces.isEmpty, "the card reaches the bottom and goes back up")
    }

    func testSuccessiveCardsGoOppositeWays() {
        let left = physics.trajectory(launchNumber: 0, from: Self.start)
        let right = physics.trajectory(launchNumber: 1, from: Self.start)
        XCTAssertLessThan(left[1].x, Self.start.x)
        XCTAssertGreaterThan(right[1].x, Self.start.x)
    }

    func testTrajectoriesAreDeterministic() {
        XCTAssertEqual(
            physics.trajectory(launchNumber: 7, from: Self.start),
            physics.trajectory(launchNumber: 7, from: Self.start)
        )
    }

    func testLaunchesAreSpacedEvenly() {
        XCTAssertEqual(CascadePhysics.launchTime(of: 0), 0)
        XCTAssertEqual(CascadePhysics.launchTime(of: 10), 10 * CascadePhysics.launchInterval, accuracy: 1e-9)
    }
}
