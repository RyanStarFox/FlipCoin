import SceneKit

extension SCNNode {

    /// Execute the full three-phase coin flip animation.
    /// - Parameters:
    ///   - result: Which face (a or b) should land facing the camera.
    ///   - particleManager: Coordinates particle effects with animation phases.
    ///   - completion: Called when the entire animation sequence finishes.
    func flipAnimation(
        result: Face,
        particleManager: ParticleManager,
        completion: @escaping () -> Void
    ) {
        let riseHeight: CGFloat = 8.0
        let totalSpins: CGFloat = 8.0

        // X-axis rotation determines which face shows.
        // Face A at 0 (or 2π), Face B at π.
        let baseAngle: CGFloat = (result == .a) ? 0 : .pi
        let finalAngle = totalSpins * 2 * .pi + baseAngle

        // ---- Phase 1: Launch (0 → 1.2s) ----
        // Coin rises while spinning rapidly, particles trail from edge.
        let riseMove = SCNAction.moveBy(x: 0, y: riseHeight, z: 0, duration: 1.2)
        riseMove.timingMode = .easeOut

        let riseSpin = SCNAction.rotateTo(
            x: finalAngle * 0.75, y: 0, z: 0,
            duration: 1.2,
            usesShortestUnitArc: false
        )
        riseSpin.timingMode = .easeOut

        // ---- Phase 2: Hover (1.2 → 1.8s) ----
        // Coin floats at apex with micro-bounce, spin decelerates.
        let hoverBounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: -0.8, z: 0, duration: 0.15),
            SCNAction.moveBy(x: 0, y:  1.2, z: 0, duration: 0.15),
            SCNAction.moveBy(x: 0, y: -0.4, z: 0, duration: 0.30)
        ])

        let hoverSpin = SCNAction.rotateTo(
            x: finalAngle * 0.90, y: 0, z: 0,
            duration: 0.6,
            usesShortestUnitArc: false
        )

        // ---- Phase 3: Land (1.8 → 2.5s) ----
        // Coin drops back to origin with spring bounce.
        let landDrop = SCNAction.moveBy(x: 0, y: -(riseHeight - 0.4), z: 0, duration: 0.55)
        landDrop.timingMode = .easeIn

        let landSpin = SCNAction.rotateTo(
            x: finalAngle, y: 0, z: 0,
            duration: 0.7,
            usesShortestUnitArc: false
        )
        landSpin.timingMode = .easeIn

        // Spring settle (overshoot → bounce → settle)
        let settle = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 1.0, z: 0, duration: 0.08),
            SCNAction.moveBy(x: 0, y: -0.6, z: 0, duration: 0.07),
            SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.05)
        ])

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
            fireTrail,
            SCNAction.group([riseMove, riseSpin]),
            switchToHover,
            SCNAction.group([hoverBounce, hoverSpin]),
            fireBurst,
            SCNAction.group([landDrop, landSpin]),
            settle,
            SCNAction.run { _ in completion() }
        ])

        // Reset position before animating
        self.position = SCNVector3(0, 0, 0)
        self.eulerAngles = SCNVector3(0, 0, 0)
        self.runAction(fullSequence)
    }
}
