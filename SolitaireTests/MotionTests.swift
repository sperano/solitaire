import SwiftUI
import XCTest
@testable import Solitaire

final class MotionTests: XCTestCase {
    func testReduceMotionDropsTheAnimation() {
        XCTAssertNil(Motion.animation(.easeInOut, reduceMotion: true))
        XCTAssertEqual(Motion.animation(.easeInOut, reduceMotion: false), .easeInOut)
    }
}
