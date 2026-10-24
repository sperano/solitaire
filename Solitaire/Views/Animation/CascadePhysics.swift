import CoreGraphics

/// The classic win celebration: cards leave the foundations one after another, fall, bounce off
/// the bottom of the screen and roll off the side. Trajectories are worked out once, ahead of time.
struct CascadePhysics {
    static let launchInterval = 0.15
    static let timeStep = 1.0 / 60
    /// Points per second squared.
    static let gravity = 1_600.0
    /// Share of the vertical speed kept by each bounce.
    static let restitution = 0.75
    static let minimumHorizontalSpeed = 120.0
    static let horizontalSpeedSpread = 180
    static let maximumUpwardSpeed = 320
    /// Primes that spread the speeds of successive cards without a random generator.
    private static let horizontalStride = 37
    private static let upwardStride = 53

    /// Where the cards' centres can go: off either side ends a trajectory, the bottom bounces.
    let bounds: CGRect
    let cardSize: CGSize

    /// The centre of the card every `timeStep`, from its launch until it is off the screen.
    func trajectory(launchNumber: Int, from start: CGPoint) -> [CGPoint] {
        let direction: Double = launchNumber.isMultiple(of: 2) ? -1 : 1
        let horizontalSpeed = direction
            * (Self.minimumHorizontalSpeed + Double(launchNumber * Self.horizontalStride % Self.horizontalSpeedSpread))
        var verticalSpeed = -Double(launchNumber * Self.upwardStride % Self.maximumUpwardSpeed)
        let floor = bounds.maxY - cardSize.height / 2
        let halfWidth = cardSize.width / 2
        var position = start
        var points: [CGPoint] = []
        while position.x + halfWidth > bounds.minX, position.x - halfWidth < bounds.maxX {
            points.append(position)
            verticalSpeed += Self.gravity * Self.timeStep
            position.x += horizontalSpeed * Self.timeStep
            position.y += verticalSpeed * Self.timeStep
            if position.y > floor {
                position.y = floor
                verticalSpeed = -verticalSpeed * Self.restitution
            }
        }
        return points
    }

    /// When the card launched `launchNumber`-th leaves its foundation, in seconds from the start.
    static func launchTime(of launchNumber: Int) -> Double {
        Double(launchNumber) * launchInterval
    }
}
