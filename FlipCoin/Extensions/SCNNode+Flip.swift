import SceneKit

extension SCNNode {

    /// Execute a physics-driven coin flip with parabolic arcs and damped bouncing.
    /// Uses kinematic equations:  y(t) = v₀·t − ½·g·t²  per bounce segment.
    ///
    /// - Parameters:
    ///   - result: Which face lands facing the camera.
    ///   - completion: Called when the full sequence finishes.
    func flipAnimation(
        result: Face,
        completion: @escaping () -> Void
    ) {
        // ---- Physics constants ----
        let g: CGFloat = 18.0           // gravity (units/s²)
        let v0: CGFloat = 11.0          // initial upward velocity
        let restitution: CGFloat = 0.38 // bounce energy retention

        // ---- Precompute bounce segments ----
        // Each segment is (startTime, startVelocity) where startVelocity is upward.
        struct Bounce {
            let t0: CGFloat    // segment start time
            let v0: CGFloat    // upward velocity at t0
            let t1: CGFloat    // segment end time (when y returns to 0)
        }

        var bounces: [Bounce] = []
        var t = CGFloat(0)
        var v = v0
        for _ in 0..<5 {
            let duration = 2 * v / g
            bounces.append(Bounce(t0: t, v0: v, t1: t + duration))
            t += duration
            v *= restitution
            if v < 0.3 { break }  // bounce too small to matter
        }

        // ---- Spin ----
        // Coin is flat on the table: Face A (top) at eulerAngles.x = 0.
        // After totalSpins rotations, land with either Face A (0) or Face B (π) up.
        let restAngle: CGFloat = 0
        let totalSpins: CGFloat = 8.0
        let baseAngle: CGFloat = (result == .a) ? 0 : .pi
        let finalAngle = restAngle + totalSpins * 2 * .pi + baseAngle

        // Spin linearly over the active bouncing duration
        let spinEndTime = bounces.last?.t1 ?? 2.0

        // ---- Animation ----
        let totalDuration: TimeInterval = TimeInterval(spinEndTime + 0.6)

        let action = SCNAction.customAction(duration: totalDuration) { node, elapsed in
            let ct = CGFloat(elapsed)

            // Vertical position: find which bounce segment we're in
            var y: CGFloat = 0
            for b in bounces {
                if ct >= b.t0 && ct < b.t1 {
                    let dt = ct - b.t0
                    y = b.v0 * dt - 0.5 * g * dt * dt
                    break
                }
            }
            // After all bounces settled: y stays at 0

            // Spin: linear interpolation, clamping at end
            let spinProgress = min(ct / spinEndTime, 1.0)
            let spinX = restAngle + (finalAngle - restAngle) * spinProgress

            node.position = SCNVector3(0, y, 0)
            node.eulerAngles = SCNVector3(Float(spinX), 0, 0)
        }

        // ---- Run ----
        self.position = SCNVector3(0, 0, 0)
        self.eulerAngles = SCNVector3(Float(restAngle), 0, 0)
        self.runAction(SCNAction.sequence([
            action,
            SCNAction.run { _ in completion() }
        ]))
    }
}
