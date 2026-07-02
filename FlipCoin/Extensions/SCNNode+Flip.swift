import SceneKit

extension SCNNode {

    /// Execute the full coin flip animation with realistic physics.
    /// - Parameters:
    ///   - result: Which face (a or b) should land facing the camera.
    ///   - completion: Called when the entire animation sequence finishes.
    func flipAnimation(
        result: Face,
        completion: @escaping () -> Void
    ) {
        // The coin's rest orientation has face A pointing toward +Z (camera).
        // eulerAngles.x = π/2 means top face (material[0]) faces the camera.
        let restAngle: CGFloat = .pi / 2
        let totalSpins: CGFloat = 8.0
        let riseHeight: CGFloat = 5.0

        // Face A = restAngle, Face B = restAngle + π
        let baseAngle: CGFloat = (result == .a) ? 0 : .pi
        let finalAngle = restAngle + totalSpins * 2 * .pi + baseAngle

        // ---- Phase 1: Launch (0 → 0.8s) ----
        // Coin shoots upward with easeOut — fast start, decelerating near apex.
        let launchDuration: TimeInterval = 0.8

        let riseMove = SCNAction.moveBy(x: 0, y: riseHeight, z: 0, duration: launchDuration)
        riseMove.timingMode = .easeOut

        let riseSpin = SCNAction.rotateTo(
            x: finalAngle * 0.70, y: 0, z: 0,
            duration: launchDuration,
            usesShortestUnitArc: false
        )
        riseSpin.timingMode = .easeOut

        // ---- Phase 2: Apex float (0.8 → 1.2s) ----
        let apexDuration: TimeInterval = 0.4

        let apexFloat = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: apexDuration)
        apexFloat.timingMode = .easeInEaseOut

        let apexSpin = SCNAction.rotateTo(
            x: finalAngle * 0.88, y: 0, z: 0,
            duration: apexDuration,
            usesShortestUnitArc: false
        )
        apexSpin.timingMode = .easeInEaseOut

        // ---- Phase 3: Fall (1.2 → 1.9s) ----
        // Gravity accelerates coin downward.
        let fallDuration: TimeInterval = 0.7

        let fallMove = SCNAction.moveBy(
            x: 0, y: -(riseHeight - 0.7), z: 0,
            duration: fallDuration
        )
        fallMove.timingMode = .easeIn

        let fallSpin = SCNAction.rotateTo(
            x: finalAngle, y: 0, z: 0,
            duration: fallDuration + 0.35,
            usesShortestUnitArc: false
        )
        fallSpin.timingMode = .easeIn

        // ---- Phase 4: Damped bounce settle (1.9 → 3.0s) ----
        // Three bounces with decaying amplitude — realistic coin-on-table feel.
        let bounce1 = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 1.8, z: 0, duration: 0.14),
            SCNAction.moveBy(x: 0, y: -1.8, z: 0, duration: 0.18)
        ])

        let bounce2 = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.7, z: 0, duration: 0.10),
            SCNAction.moveBy(x: 0, y: -0.7, z: 0, duration: 0.13)
        ])

        let bounce3 = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.20, z: 0, duration: 0.06),
            SCNAction.moveBy(x: 0, y: -0.20, z: 0, duration: 0.09)
        ])

        let settle = SCNAction.moveBy(x: 0, y: 0, z: 0, duration: 0.05)

        // ---- Compose full sequence ----
        let fullSequence = SCNAction.sequence([
            SCNAction.group([riseMove, riseSpin]),
            SCNAction.group([apexFloat, apexSpin]),
            SCNAction.group([fallMove, fallSpin]),
            bounce1,
            bounce2,
            bounce3,
            settle,
            SCNAction.run { _ in completion() }
        ])

        // Reset position and orientation before animating.
        self.position = SCNVector3(0, 0, 0)
        self.eulerAngles = SCNVector3(Float(restAngle), 0, 0)
        self.runAction(fullSequence)
    }
}
