import SwiftUI
import SceneKit

#if os(macOS)
struct CoinSceneView: NSViewRepresentable {

    let coinScene: CoinScene
    @ObservedObject var animator: FlipAnimator
    var onFlipStart: (() -> Void)?
    var onResult: ((Face) -> Void)?

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        configure(scnView)
        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        context.coordinator.syncAnimator()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            coinScene: coinScene,
            animator: animator,
            onFlipStart: onFlipStart,
            onResult: onResult
        )
    }

    private func configure(_ scnView: SCNView) {
        scnView.scene = coinScene.scene
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
    }
}
#else
struct CoinSceneView: UIViewRepresentable {

    let coinScene: CoinScene
    @ObservedObject var animator: FlipAnimator
    var onFlipStart: (() -> Void)?
    var onResult: ((Face) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = coinScene.scene
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.syncAnimator()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            coinScene: coinScene,
            animator: animator,
            onFlipStart: onFlipStart,
            onResult: onResult
        )
    }
}
#endif

// MARK: - Coordinator

extension CoinSceneView {

    class Coordinator: NSObject {
        private let coinScene: CoinScene
        private let animator: FlipAnimator
        private let onFlipStart: (() -> Void)?
        private let onResult: ((Face) -> Void)?
        private var hasStartedAnimation = false

        init(
            coinScene: CoinScene,
            animator: FlipAnimator,
            onFlipStart: (() -> Void)?,
            onResult: ((Face) -> Void)?
        ) {
            self.coinScene = coinScene
            self.animator = animator
            self.onFlipStart = onFlipStart
            self.onResult = onResult
            super.init()
        }

        func syncAnimator() {
            switch animator.state {
            case .idle:
                // Reset tracking when back to idle
                hasStartedAnimation = false

            case .flipping(let phase):
                // Trigger the SceneKit animation only once, at the start
                if phase == .launch && !hasStartedAnimation {
                    hasStartedAnimation = true
                    onFlipStart?()

                    // Use animator.result — the single source of truth
                    coinScene.animateFlip(result: animator.result) { [weak self] in
                        DispatchQueue.main.async {
                            self?.onResult?(self?.animator.result ?? .a)
                        }
                    }
                }

            case .result(let face):
                onResult?(face)
            }
        }
    }
}
