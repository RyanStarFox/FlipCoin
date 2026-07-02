import SceneKit

extension SCNNode {

    /// Execute the full coin flip animation with realistic physics.
    /// - Parameters:
    ///   - result: Which face (a or b) should land facing the camera.
    ///   - particleManager: Coordinates particle effects with animation phases.
    ///   - completion: Called when the entire animation sequence finishes.
    func flipAnimation(
        result: Face,
        particleManager: ParticleManager,
        completion: @escaping () -> Void
    ) {
        // The coin's rest orientation has face A pointing toward +Z (camera).
        // eulerAngles.x = π/2 means top face (material[0]) faces the camera.
        let restAngle: CGFloat = .pi / 2
        let totalSpins: CGFloat = 8.0

        // Face A = restAngle, Face B = restAngle + π
        let baseAngle: CGFloat = (result == .a) ? 0 : .pi
        let finalAngle = restAngle + totalSpins * 2 * .pi + baseAngle

        // ---- Phase 1: Launch (0 → 0.9s) ----
        // Coin shoots upward with easeOut — fast start, decelerating near apex.
        // This matches real physics: high initial velocity, gravity slows it down.
        let riseHeight: CGFloat = 6.0
        let launchDuration: TimeInterval = 0.9

        let riseMove = SCNAction.moveBy(x: 0, y: riseHeight, z: 0, duration: launchDuration)
        riseMove.timingMode = .easeOut

        let riseSpin = SCNAction.rotateTo(
            x: finalAngle * 0.70, y: 0, z: 0,
            duration: launchDuration,
            usesShortestUnitArc: false
        )
        riseSpin.timingMode = .easeOut

        // ---- Phase 2: Apex float (0.9 → 1.3s) ----
        // Brief near-weightless float at top, spin continues but slowing.
        let apexDuration: TimeInterval = 0.4

        let apexFloat = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: apexDuration)
        apexFloat.timingMode = .easeInEaseOut

        let apexSpin = SCNAction.rotateTo(
            x: finalAngle * 0.85, y: 0, z: 0,
            duration: apexDuration,
            usesShortestUnitArc: false
        )
        apexSpin.timingMode = .easeInEaseOut

        // ---- Phase 3: Fall (1.3 → 2.0s) ----
        // Gravity takes over — accelerating downward with easeIn.
        let fallDuration: TimeInterval = 0.7

        let fallMove = SCNAction.moveBy(x: 0, y: -(riseHeight - 0.8), z: 0, duration: fallDuration)
        fallMove.timingMode = .easeIn

        let fallSpin = SCNAction.rotateTo(
            x: finalAngle, y: 0, z: 0,
            duration: fallDuration + 0.35,  // spin finishes just after impact
            usesShortestUnitArc: false
        )
        fallSpin.timingMode = .easeIn

        // ---- Phase 4: Bounce settle (2.0 → 3.0s) ----
        // Realistic damped bounce chain:
        //   Impact → up 2.0 (fast) → down (gravity) → Impact →
        //   up 0.8 → down → Impact → up 0.25 → down → settle
        let bounce1 = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 2.0, z: 0, duration: 0.13),
            SCNAction.moveBy(x: 0, y: -2.0, z: 0, duration: 0.18)
        ])
        bounce1.timingMode = .easeInEaseOut

        let bounce2 = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.8, z: 0, duration: 0.10),
            SCNAction.moveBy(x: 0, y: -0.8, z: 0, duration: 0.14)
        ])

        let bounce3 = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.25, z: 0, duration: 0.07),
            SCNAction.moveBy(x: 0, y: -0.25, z: 0, duration: 0.10)
        ])

        let settle = SCNAction.moveBy(x: 0, y: 0, z: 0, duration: 0.05)

        // ---- Particle triggers at phase boundaries ----
        let fireTrail = SCNAction.run { _ in particleManager.startTrail() }
        let switchToHover = SCNAction.run { _ in
            particleManager.stopTrail()
            particleManager.startHover()
        }
        let fireBurst = SCNAction.run { _ in
            particleManager.stopHover()
            particleManager.triggerBurst()
        }

        // ---- Compose full sequence ----
        let fullSequence = SCNAction.sequence([
            // Phase 1: Launch
            fireTrail,
            SCNAction.group([riseMove, riseSpin]),
            // Phase 2: Apex
            switchToHover,
            SCNAction.group([apexFloat, apexSpin]),
            // Phase 3: Fall
            SCNAction.group([fallMove, fallSpin]),
            // Phase 4: Impact + bounce
            fireBurst,
            bounce1,
            bounce2,
            bounce3,
            settle,
            SCNAction.run { _ in completion() }
        ])

        // Reset position and orientation before animating.
        // π/2 is the rest orientation — face A pointing at camera.
        self.position = SCNVector3(0, 0, 0)
        self.eulerAngles = SCNVector3(Float(restAngle), 0, 0)
        self.runAction(fullSequence)
    }
}
