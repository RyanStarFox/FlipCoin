import Foundation

// MARK: - Types

enum Face: String {
    case a, b
}

enum FlipPhase: TimeInterval {
    case launch = 0
    case hover  = 1.2
    case land   = 1.8

    var duration: TimeInterval {
        switch self {
        case .launch: return 1.2
        case .hover:  return 0.6
        case .land:   return 0.7
        }
    }

    var next: FlipPhase? {
        switch self {
        case .launch: return .hover
        case .hover:  return .land
        case .land:   return nil
        }
    }
}

enum FlipState {
    case idle
    case flipping(phase: FlipPhase)
    case result(Face)
}

// MARK: - Animator

class FlipAnimator: ObservableObject {

    @Published var state: FlipState = .idle

    /// The result chosen at flip() time — single source of truth.
    /// The SceneKit animation reads this so the visual matches the logic.
    private(set) var result: Face = .a

    /// Called when a new phase begins (so particles can switch).
    var onPhaseChange: ((FlipPhase) -> Void)?

    /// Called when the full animation (including result display) completes.
    var onCompletion: ((Face) -> Void)?

    var isAnimating: Bool {
        if case .flipping = state { return true }
        return false
    }

    func flip() {
        guard case .idle = state else { return }

        // Single source of truth for the random outcome
        result = Bool.random() ? .a : .b
        advancePhase(.launch)
    }

    private func advancePhase(_ phase: FlipPhase) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.state = .flipping(phase: phase)
            self.onPhaseChange?(phase)

            if let next = phase.next {
                DispatchQueue.main.asyncAfter(deadline: .now() + phase.duration) { [weak self] in
                    self?.advancePhase(next)
                }
            } else {
                // Land phase just completed — show result
                DispatchQueue.main.asyncAfter(deadline: .now() + phase.duration) { [weak self] in
                    guard let self = self else { return }
                    self.state = .result(self.result)
                    self.onCompletion?(self.result)

                    // Auto-reset to idle after showing result briefly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.state = .idle
                    }
                }
            }
        }
    }
}
