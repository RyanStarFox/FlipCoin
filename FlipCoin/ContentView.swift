import SwiftUI
import SceneKit

struct ContentView: View {

    @AppStorage("coinSkin") private var skin: CoinSkin = .yesNo
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    @StateObject private var animator = FlipAnimator()
    @State private var displayedResult: Face?
    @State private var showSettings = false

    @StateObject private var coinSceneHolder: CoinSceneHolder

    init() {
        // @AppStorage not available during init — create scene with a default,
        // then sync in onAppear.
        let holder = CoinSceneHolder(skin: .yesNo)
        _coinSceneHolder = StateObject(wrappedValue: holder)
    }

    private var coinScene: CoinScene { coinSceneHolder.scene }

    var body: some View {
        ZStack {
            // System-native material background (auto light/dark)
            VisualEffectView()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Settings gear (top-right)
                HStack {
                    Spacer()
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSettings, arrowEdge: .top) {
                        SettingsPopover(
                            skin: $skin,
                            soundEnabled: $soundEnabled,
                            hapticEnabled: $hapticEnabled
                        )
                        .onChange(of: skin) { newSkin in
                            coinScene.updateSkin(newSkin)
                        }
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer(minLength: 20)

                // 3D coin viewport
                CoinSceneView(
                    coinScene: coinScene,
                    animator: animator,
                    onFlipStart: {
                        displayedResult = nil
                    },
                    onResult: { face in
                        displayedResult = face
                        triggerHapticIfEnabled()
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: 380)

                Spacer(minLength: 12)

                // Result text
                ResultLabel(result: displayedResult, skin: skin)
                    .padding(.bottom, 20)

                // Flip button
                Button(action: flip) {
                    Label("Flip", systemImage: "dice.fill")
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(animator.isAnimating)
                .keyboardShortcut(.space, modifiers: [])
                .padding(.bottom, 32)
            }
        }
        .frame(minWidth: 400, idealWidth: 400, maxWidth: .infinity,
               minHeight: 550, idealHeight: 550, maxHeight: .infinity)
        .onAppear {
            coinScene.updateSkin(skin)
        }
    }

    // MARK: - Actions

    private func flip() {
        guard !animator.isAnimating else { return }
        animator.flip()
    }

    private func triggerHapticIfEnabled() {
        guard hapticEnabled else { return }
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )
        #endif
    }
}

// MARK: - CoinScene lifecycle holder

/// Holds the CoinScene as an ObservableObject so it survives view rebuilds.
/// CoinScene is expensive to recreate (geometry, textures, particles).
private class CoinSceneHolder: ObservableObject {
    let scene: CoinScene

    init(skin: CoinSkin) {
        self.scene = CoinScene(skin: skin)
    }
}

// MARK: - Visual Effect background

#if os(macOS)
private struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .contentBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#else
private struct VisualEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#endif
