# FlipCoin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight coin-flipping macOS/iOS app with photorealistic 3D PBR silver coin, three-phase flip animation, silver particle effects, and four interchangeable coin skins.

**Architecture:** SwiftUI for UI chrome, SceneKit for 3D viewport. `FlipAnimator` state machine drives `SCNNode` animations via `SCNAction` sequences. `ParticleManager` controls three `SCNParticleSystem` instances by phase. Platform bridge uses `NSViewRepresentable`/`UIViewRepresentable` with `#if os(macOS)`.

**Tech Stack:** Swift 5.9+, SwiftUI, SceneKit, Xcode 15+

## Global Constraints

- macOS 12+, iOS 16+, iPadOS 16+
- Silver PBR coin: metalness 0.95, roughness 0.25
- Four skins: yesNo, ab, oneTwo, sunMoon — persisted via @AppStorage
- Three-phase animation: launch (0→1.2s), hover (1.2→1.8s), land (1.8→2.5s)
- Three particle systems: trail (launch), hover sparkles, burst (landing)
- Apple HIG: system fonts, .ultraThinMaterial background, SF Symbols, system blue tint
- Space bar hotkey triggers flip
- Window default 350×500, resizable

---

### Task 1: Project Scaffolding & CoinSkin Model

**Files:**
- Create: `FlipCoin/Model/CoinSkin.swift`

**Interfaces:**
- Produces: `CoinSkin` enum — `RawRepresentable` (String), `CaseIterable`, `Codable`
  - `var faceAText: String` — text rendered on coin face A
  - `var faceBText: String` — text rendered on coin face B
  - `var displayName: String` — human-readable name for settings UI
  - `var symbolName: String` — SF Symbol name for settings icon

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p FlipCoin/{Model,Scene,Views,Extensions}
```

- [ ] **Step 2: Write CoinSkin.swift**

```swift
// FlipCoin/Model/CoinSkin.swift
import Foundation

enum CoinSkin: String, CaseIterable, Codable {
    case yesNo
    case ab
    case oneTwo
    case sunMoon

    var displayName: String {
        switch self {
        case .yesNo:   return "Yes / No"
        case .ab:      return "A / B"
        case .oneTwo:  return "1 / 2"
        case .sunMoon: return "☀️ / 🌙"
        }
    }

    var symbolName: String {
        switch self {
        case .yesNo:   return "checkmark.square"
        case .ab:      return "textformat.abc"
        case .oneTwo:  return "textformat.123"
        case .sunMoon: return "moon.stars"
        }
    }

    var faceAText: String {
        switch self {
        case .yesNo:   return "YES"
        case .ab:      return "A"
        case .oneTwo:  return "1"
        case .sunMoon: return "☀️"
        }
    }

    var faceBText: String {
        switch self {
        case .yesNo:   return "NO"
        case .ab:      return "B"
        case .oneTwo:  return "2"
        case .sunMoon: return "🌙"
        }
    }
}
```

- [ ] **Step 3: Verify compilation**

```bash
swiftc -typecheck FlipCoin/Model/CoinSkin.swift -sdk $(xcrun --show-sdk-path --sdk macosx) -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 2: SkinTextureRenderer — Programmatic Face Textures

**Files:**
- Create: `FlipCoin/Scene/SkinTextureRenderer.swift`

**Interfaces:**
- Produces: `SkinTextureRenderer` struct
  - `static func renderFace(_ text: String, size: CGSize) -> UIImage`
  - `static func renderSide(size: CGSize) -> UIImage`
- Consumes: `CoinSkin` from Task 1

- [ ] **Step 1: Write SkinTextureRenderer.swift**

```swift
// FlipCoin/Scene/SkinTextureRenderer.swift
import UIKit

struct SkinTextureRenderer {

    static func renderFace(_ text: String, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Silver coin face background with subtle radial gradient
            let bounds = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(size.width, size.height) / 2
            let colors = [
                UIColor(white: 0.92, alpha: 1.0).cgColor,
                UIColor(white: 0.78, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceGray(),
                colors: colors,
                locations: locations
            ) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: radius * 0.1,
                    endCenter: center, endRadius: radius,
                    options: [.drawsAfterEndLocation]
                )
            }

            // Rim highlight
            ctx.cgContext.setStrokeColor(UIColor(white: 0.95, alpha: 0.6).cgColor)
            ctx.cgContext.setLineWidth(radius * 0.04)
            ctx.cgContext.addArc(center: center, radius: radius * 0.94,
                                  startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.cgContext.strokePath()

            // Inner ring
            ctx.cgContext.setStrokeColor(UIColor(white: 0.7, alpha: 0.4).cgColor)
            ctx.cgContext.setLineWidth(radius * 0.015)
            ctx.cgContext.addArc(center: center, radius: radius * 0.75,
                                  startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.cgContext.strokePath()

            // Text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let fontSize: CGFloat
            if text.count <= 2 {
                fontSize = radius * 0.55
            } else if text.count <= 3 {
                fontSize = radius * 0.4
            } else {
                fontSize = radius * 0.3
            }

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor(white: 0.35, alpha: 0.9),
                .paragraphStyle: paragraphStyle
            ]

            let textRect = CGRect(x: 0, y: bounds.midY - fontSize * 0.45,
                                  width: size.width, height: fontSize * 1.1)
            (text as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }

    static func renderSide(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let bounds = CGRect(origin: .zero, size: size)
            // Reeded edge pattern — thin vertical lines
            ctx.cgContext.setFillColor(UIColor(white: 0.88, alpha: 1.0).cgColor)
            ctx.cgContext.fill(bounds)

            let lineCount = 80
            let lineWidth = size.width / CGFloat(lineCount)
            for i in 0..<lineCount {
                let x = CGFloat(i) * lineWidth
                let shade: CGFloat = i % 3 == 0 ? 0.70 : (i % 5 == 0 ? 0.92 : 0.82)
                ctx.cgContext.setFillColor(UIColor(white: shade, alpha: 0.6).cgColor)
                ctx.cgContext.fill(CGRect(x: x, y: 0, width: lineWidth * 0.55, height: size.height))
            }
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
swiftc -typecheck FlipCoin/Model/CoinSkin.swift FlipCoin/Scene/SkinTextureRenderer.swift -sdk $(xcrun --show-sdk-path --sdk macosx) -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 3: CoinGenerator — Procedural 3D Coin

**Files:**
- Create: `FlipCoin/Scene/CoinGenerator.swift`

**Interfaces:**
- Produces: `CoinGenerator` struct
  - `static func generate(skin: CoinSkin) -> SCNNode`
- Consumes: `CoinSkin` (Task 1), `SkinTextureRenderer` (Task 2)

- [ ] **Step 1: Write CoinGenerator.swift**

```swift
// FlipCoin/Scene/CoinGenerator.swift
import SceneKit

struct CoinGenerator {

    static let coinRadius: CGFloat = 1.0
    static let coinHeight: CGFloat = 0.06
    static let coinSegments: Int = 64

    static func generate(skin: CoinSkin) -> SCNNode {
        let coinNode = SCNNode()
        coinNode.name = "coin"

        // Geometry
        let cylinder = SCNCylinder(radius: coinRadius, height: coinHeight)
        cylinder.radialSegmentCount = coinSegments

        // Texture sizes
        let faceSize = CGSize(width: 512, height: 512)
        let sideSize = CGSize(width: 512, height: 32)

        let faceATex = SkinTextureRenderer.renderFace(skin.faceAText, size: faceSize)
        let faceBTex = SkinTextureRenderer.renderFace(skin.faceBText, size: faceSize)
        let sideTex  = SkinTextureRenderer.renderSide(size: sideSize)

        // --- Top face material (Face A) ---
        let topMat = SCNMaterial()
        topMat.lightingModel = .physicallyBased
        topMat.diffuse.contents = faceATex
        topMat.metalness.contents = 0.95
        topMat.roughness.contents = 0.25
        topMat.name = "faceA"

        // --- Bottom face material (Face B) ---
        let botMat = SCNMaterial()
        botMat.lightingModel = .physicallyBased
        botMat.diffuse.contents = faceBTex
        botMat.metalness.contents = 0.95
        botMat.roughness.contents = 0.25
        botMat.name = "faceB"

        // --- Side / edge material ---
        let sideMat = SCNMaterial()
        sideMat.lightingModel = .physicallyBased
        sideMat.diffuse.contents = sideTex
        sideMat.metalness.contents = 0.95
        sideMat.roughness.contents = 0.20
        sideMat.name = "edge"

        cylinder.materials = [topMat, botMat, sideMat]
        coinNode.geometry = cylinder

        // Initial orientation: face the camera (XY plane faces +Z)
        // SCNCylinder axis is Y by default; rotate so faces point at camera
        coinNode.eulerAngles = SCNVector3(0, 0, 0)

        return coinNode
    }

    static func updateSkin(_ coinNode: SCNNode, skin: CoinSkin) {
        guard let cylinder = coinNode.geometry as? SCNCylinder,
              cylinder.materials.count >= 2 else { return }

        let faceSize = CGSize(width: 512, height: 512)
        let faceATex = SkinTextureRenderer.renderFace(skin.faceAText, size: faceSize)
        let faceBTex = SkinTextureRenderer.renderFace(skin.faceBText, size: faceSize)

        cylinder.materials[0].diffuse.contents = faceATex
        cylinder.materials[1].diffuse.contents = faceBTex
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
swiftc -typecheck FlipCoin/Model/CoinSkin.swift FlipCoin/Scene/SkinTextureRenderer.swift FlipCoin/Scene/CoinGenerator.swift -sdk $(xcrun --show-sdk-path --sdk macosx) -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 4: FlipAnimator — Animation State Machine

**Files:**
- Create: `FlipCoin/Model/FlipAnimator.swift`

**Interfaces:**
- Produces: `FlipAnimator` (ObservableObject), `FlipState`, `FlipPhase`, `Face` enums
  - `class FlipAnimator: ObservableObject`
  - `@Published var state: FlipState = .idle`
  - `func flip()`
  - `var onPhaseChange: ((FlipPhase) -> Void)?`
  - `var onCompletion: ((Face) -> Void)?`

- [ ] **Step 1: Write FlipAnimator.swift**

```swift
// FlipCoin/Model/FlipAnimator.swift
import Foundation

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

class FlipAnimator: ObservableObject {

    @Published var state: FlipState = .idle

    var onPhaseChange: ((FlipPhase) -> Void)?
    var onCompletion: ((Face) -> Void)?

    private let totalDuration: TimeInterval = 2.5

    var isAnimating: Bool {
        if case .flipping = state { return true }
        return false
    }

    func flip() {
        guard case .idle = state else { return }

        let result: Face = Bool.random() ? .a : .b
        advancePhase(.launch, result: result)
    }

    private func advancePhase(_ phase: FlipPhase, result: Face) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .flipping(phase: phase)
            self?.onPhaseChange?(phase)

            if let next = phase.next {
                DispatchQueue.main.asyncAfter(deadline: .now() + phase.duration) { [weak self] in
                    self?.advancePhase(next, result: result)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + phase.duration) { [weak self] in
                    self?.state = .result(result)
                    self?.onCompletion?(result)
                    // Auto-reset to idle after showing result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.state = .idle
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
swiftc -typecheck FlipCoin/Model/FlipAnimator.swift -sdk $(xcrun --show-sdk-path --sdk macosx) -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 5: SCNNode+Flip — Coin Animation Extension

**Files:**
- Create: `FlipCoin/Extensions/SCNNode+Flip.swift`

**Interfaces:**
- Produces: `SCNNode` extension
  - `func flipAnimation(result: Face, particleManager: ParticleManager, completion: @escaping () -> Void)`
- Consumes: `Face`, `FlipPhase` (Task 4), `ParticleManager` (Task 6 — forward declaration)

- [ ] **Step 1: Write SCNNode+Flip.swift**

```swift
// FlipCoin/Extensions/SCNNode+Flip.swift
import SceneKit

extension SCNNode {

    /// Execute the full three-phase coin flip animation.
    /// - Parameters:
    ///   - result: Which face (a or b) should land facing the camera
    ///   - particleManager: ParticleManager to coordinate effects with phases
    ///   - completion: Called when entire animation finishes
    func flipAnimation(result: Face, particleManager: ParticleManager, completion: @escaping () -> Void) {

        let riseHeight: CGFloat = 8.0
        let totalSpins: CGFloat = 8.0
        let spinAxis = SCNVector3(1, 0, 0) // X-axis rotation for face visibility

        // Calculate final angle: Face A = 0 (default), Face B = π (180° flip)
        // After totalSpins full rotations, land on the correct face
        let baseAngle: CGFloat = (result == .a) ? 0 : .pi
        let finalAngle = totalSpins * 2 * .pi + baseAngle

        // --- Phase 1: Launch (0 → 1.2s) ---
        let riseAction = SCNAction.group([
            // Rise on Y-axis with ease-out
            SCNAction.moveBy(x: 0, y: riseHeight, z: 0, duration: 1.2),
            // Fast X-axis spin (ease-out)
            SCNAction.rotateTo(
                x: finalAngle * 0.75, y: 0, z: 0,
                duration: 1.2,
                usesShortestUnitArc: false
            )
        ])
        riseAction.timingMode = .easeOut

        // --- Phase 2: Hover (1.2 → 1.8s) ---
        let hoverAction = SCNAction.group([
            // Micro-bounce at apex
            SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: -0.8, z: 0, duration: 0.15),
                SCNAction.moveBy(x: 0, y: 1.2, z: 0, duration: 0.15),
                SCNAction.moveBy(x: 0, y: -0.4, z: 0, duration: 0.3)
            ]),
            // Continue spinning but slower
            SCNAction.rotateTo(
                x: finalAngle * 0.90, y: 0, z: 0,
                duration: 0.6,
                usesShortestUnitArc: false
            )
        ])

        // --- Phase 3: Land (1.8 → 2.5s) ---
        let landSpin = SCNAction.rotateTo(
            x: finalAngle, y: 0, z: 0,
            duration: 0.7,
            usesShortestUnitArc: false
        )
        landSpin.timingMode = .easeIn

        let landDrop = SCNAction.moveBy(x: 0, y: -(riseHeight - 0.4), z: 0, duration: 0.55)
        landDrop.timingMode = .easeIn

        // Spring bounce on landing
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 1.0, z: 0, duration: 0.08),
            SCNAction.moveBy(x: 0, y: -0.6, z: 0, duration: 0.07),
            SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.05)
        ])

        let landAction = SCNAction.sequence([
            SCNAction.group([landSpin, landDrop]),
            bounce
        ])

        // --- Particle coordination ---
        // Phase callbacks embedded in the action sequence
        let notifyLaunch = SCNAction.run { _ in particleManager.startTrail() }
        let notifyHover  = SCNAction.run { _ in
            particleManager.stopTrail()
            particleManager.startHover()
        }
        let notifyLand   = SCNAction.run { _ in
            particleManager.stopHover()
            particleManager.triggerBurst()
        }

        let fullSequence = SCNAction.sequence([
            notifyLaunch,
            riseAction,
            notifyHover,
            hoverAction,
            notifyLand,
            landAction,
            SCNAction.run { _ in completion() }
        ])

        self.position = SCNVector3(0, 0, 0)
        self.eulerAngles = SCNVector3(0, 0, 0)
        self.runAction(fullSequence)
    }
}
```

- [ ] **Step 2: Verify compilation** (will fail until Task 6, expected)

```bash
swiftc -typecheck FlipCoin/Model/FlipAnimator.swift FlipCoin/Extensions/SCNNode+Flip.swift -sdk $(xcrun --show-sdk-path --sdk macosx) -target $(uname -m)-apple-macos12.0
```
Expected: error about `ParticleManager` not found — resolved in Task 6

---

### Task 6: ParticleManager — Silver Particle Systems

**Files:**
- Create: `FlipCoin/Scene/ParticleManager.swift`

**Interfaces:**
- Produces: `ParticleManager` class
  - `var trailNode: SCNNode` (attached to coin)
  - `var hoverNode: SCNNode` (attached to coin)
  - `var burstNode: SCNNode` (attached to coin)
  - `func startTrail()`, `func stopTrail()`
  - `func startHover()`, `func stopHover()`
  - `func triggerBurst()`

- [ ] **Step 1: Write ParticleManager.swift**

```swift
// FlipCoin/Scene/ParticleManager.swift
import SceneKit

class ParticleManager {

    let trailNode = SCNNode()
    let hoverNode = SCNNode()
    let burstNode = SCNNode()

    private let trailSystem: SCNParticleSystem
    private let hoverSystem: SCNParticleSystem
    private let burstSystem: SCNParticleSystem

    init() {
        trailSystem = ParticleManager.makeTrailSystem()
        hoverSystem = ParticleManager.makeHoverSystem()
        burstSystem = ParticleManager.makeBurstSystem()

        trailSystem.loops = true
        hoverSystem.loops = true
    }

    // MARK: - Control

    func startTrail() {
        trailNode.addParticleSystem(trailSystem)
    }

    func stopTrail() {
        trailNode.removeAllParticleSystems()
    }

    func startHover() {
        hoverNode.addParticleSystem(hoverSystem)
    }

    func stopHover() {
        hoverNode.removeAllParticleSystems()
    }

    func triggerBurst() {
        burstNode.addParticleSystem(burstSystem)
        // Burst is one-shot; auto-removes after its lifetime
    }

    // MARK: - Particle System Builders

    private static func makeTrailSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 200
        ps.birthDirection = .random
        ps.emissionDuration = 0
        ps.particleLifeSpan = 0.4
        ps.particleLifeSpanVariation = 0.15
        ps.loops = true

        // Silver sparkle appearance
        ps.particleColor = NSColor(white: 0.88, alpha: 1.0)
        ps.particleColorVariation = SCNVector4(0.08, 0.08, 0.08, 0.0)
        ps.particleSize = 0.06
        ps.particleSizeVariation = 0.03

        // Physics
        ps.speedFactor = 0.15
        ps.spreadingAngle = 60
        ps.particleVelocity = 1.5
        ps.particleVelocityVariation = 0.8
        let gravity = SCNVector3(0, -0.3, 0)
        ps.acceleration = gravity

        // Blend
        ps.blendMode = .additive
        ps.fresnelExponent = 4
        ps.particleImage = makeSparkImage(size: 8)

        // Emitter shape: ring around coin edge
        ps.emitterShape = SCNTorus(ringRadius: 1.0, pipeRadius: 0.03)

        return ps
    }

    private static func makeHoverSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 30
        ps.birthDirection = .random
        ps.emissionDuration = 0
        ps.particleLifeSpan = 1.2
        ps.particleLifeSpanVariation = 0.5
        ps.loops = true

        ps.particleColor = NSColor(white: 0.9, alpha: 0.7)
        ps.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0.0)
        ps.particleSize = 0.04
        ps.particleSizeVariation = 0.02

        ps.speedFactor = 0.06
        ps.spreadingAngle = 90
        ps.particleVelocity = 0.6
        ps.particleVelocityVariation = 0.4

        ps.blendMode = .additive
        ps.particleImage = makeSparkImage(size: 6)

        // Orbiting emitter
        ps.emitterShape = SCNSphere(radius: 1.1)

        return ps
    }

    private static func makeBurstSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 800
        ps.birthDirection = .random
        ps.emissionDuration = 0.05      // instant burst
        ps.particleLifeSpan = 0.5
        ps.particleLifeSpanVariation = 0.25
        ps.loops = false                // one-shot

        ps.particleColor = NSColor(white: 0.95, alpha: 1.0)
        ps.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.0)
        ps.particleSize = 0.08
        ps.particleSizeVariation = 0.05

        ps.emittingDirection = SCNVector3(0, 0, 1)
        ps.spreadingAngle = 120
        ps.particleVelocity = 4.0
        ps.particleVelocityVariation = 2.0

        ps.blendMode = .additive
        ps.fresnelExponent = 3
        ps.particleImage = makeSparkImage(size: 10)

        ps.emitterShape = SCNTorus(ringRadius: 0.8, pipeRadius: 0.1)

        return ps
    }

    // MARK: - Spark Image

    private static func makeSparkImage(size: Int) -> NSImage {
        let s = CGFloat(size)
        let image = NSImage(size: NSSize(width: s, height: s))
        image.lockFocus()
        let ctx = NSGraphicsContext.current?.cgContext
        let center = CGPoint(x: s / 2, y: s / 2)
        let colors = [
            NSColor(white: 1.0, alpha: 1.0).cgColor,
            NSColor(white: 0.8, alpha: 0.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors,
            locations: locations
        ) {
            ctx?.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: s / 2,
                options: []
            )
        }
        image.unlockFocus()
        return image
    }
}
```

- [ ] **Step 2: Verify all Scene files compile together**

```bash
swiftc -typecheck \
  FlipCoin/Model/CoinSkin.swift \
  FlipCoin/Scene/SkinTextureRenderer.swift \
  FlipCoin/Scene/CoinGenerator.swift \
  FlipCoin/Model/FlipAnimator.swift \
  FlipCoin/Scene/ParticleManager.swift \
  FlipCoin/Extensions/SCNNode+Flip.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 7: CoinScene — Full 3D Scene Assembly

**Files:**
- Create: `FlipCoin/Scene/CoinScene.swift`

**Interfaces:**
- Produces: `CoinScene` class
  - `let scene: SCNScene`
  - `let coinNode: SCNNode`
  - `let particleManager: ParticleManager`
  - `func updateSkin(_ skin: CoinSkin)`
  - `func animateFlip(result: Face, completion: @escaping () -> Void)`
- Consumes: `CoinGenerator` (Task 3), `FlipAnimator` (Task 4), `ParticleManager` (Task 6), `SCNNode+Flip` (Task 5)

- [ ] **Step 1: Write CoinScene.swift**

```swift
// FlipCoin/Scene/CoinScene.swift
import SceneKit

class CoinScene {

    let scene = SCNScene()
    let coinNode: SCNNode
    let particleManager = ParticleManager()

    private(set) var currentSkin: CoinSkin

    init(skin: CoinSkin) {
        self.currentSkin = skin
        self.coinNode = CoinGenerator.generate(skin: skin)

        setupScene()
    }

    private func setupScene() {
        scene.background.contents = NSColor.clear

        // --- Camera ---
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 1.5, 8)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // --- Lighting ---
        // Ambient (fills shadows)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.intensity = 400
        ambientLight.light!.color = NSColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Key light (directional — creates PBR specular highlights)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light!.type = .directional
        keyLight.light!.intensity = 1000
        keyLight.light!.color = NSColor(white: 0.95, alpha: 1.0)
        keyLight.position = SCNVector3(5, 8, 5)
        keyLight.look(at: SCNVector3(0, 0, 0))
        keyLight.light!.castsShadow = false
        scene.rootNode.addChildNode(keyLight)

        // Fill light (softer, from below-left)
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light!.type = .directional
        fillLight.light!.intensity = 300
        fillLight.light!.color = NSColor(white: 0.7, alpha: 1.0)
        fillLight.position = SCNVector3(-4, 2, 3)
        fillLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillLight)

        // Rim light (back-right edge highlight)
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light!.type = .directional
        rimLight.light!.intensity = 500
        rimLight.light!.color = NSColor(white: 0.85, alpha: 1.0)
        rimLight.position = SCNVector3(3, 3, -4)
        rimLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(rimLight)

        // --- Coin ---
        scene.rootNode.addChildNode(coinNode)

        // --- Particle nodes (children of coin, move with it) ---
        coinNode.addChildNode(particleManager.trailNode)
        coinNode.addChildNode(particleManager.hoverNode)
        coinNode.addChildNode(particleManager.burstNode)
    }

    func updateSkin(_ skin: CoinSkin) {
        currentSkin = skin
        CoinGenerator.updateSkin(coinNode, skin: skin)
    }

    func animateFlip(result: Face, completion: @escaping () -> Void) {
        coinNode.flipAnimation(result: result, particleManager: particleManager, completion: completion)
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
swiftc -typecheck \
  FlipCoin/Model/CoinSkin.swift \
  FlipCoin/Scene/SkinTextureRenderer.swift \
  FlipCoin/Scene/CoinGenerator.swift \
  FlipCoin/Model/FlipAnimator.swift \
  FlipCoin/Scene/ParticleManager.swift \
  FlipCoin/Extensions/SCNNode+Flip.swift \
  FlipCoin/Scene/CoinScene.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 8: CoinSceneView — Platform Bridge

**Files:**
- Create: `FlipCoin/Views/CoinSceneView.swift`

**Interfaces:**
- Produces: `CoinSceneView` (SwiftUI View)
  - `init(skin: CoinSkin, animator: FlipAnimator, onResult: @escaping (Face) -> Void)`
- Consumes: `CoinScene` (Task 7), `FlipAnimator` (Task 4)

- [ ] **Step 1: Write CoinSceneView.swift**

```swift
// FlipCoin/Views/CoinSceneView.swift
import SwiftUI
import SceneKit

#if os(macOS)
struct CoinSceneView: NSViewRepresentable {

    let coinScene: CoinScene
    @ObservedObject var animator: FlipAnimator
    let onResult: (Face) -> Void

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        configure(scnView, context: context)
        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        context.coordinator.syncAnimator()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(coinScene: coinScene, animator: animator, onResult: onResult)
    }

    private func configure(_ scnView: SCNView, context: Context) {
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
    let onResult: (Face) -> Void

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
        Coordinator(coinScene: coinScene, animator: animator, onResult: onResult)
    }
}
#endif

// MARK: - Coordinator

extension CoinSceneView {

    class Coordinator: NSObject {
        private let coinScene: CoinScene
        private let animator: FlipAnimator
        private let onResult: (Face) -> Void
        private var lastPhase: FlipPhase?

        init(coinScene: CoinScene, animator: FlipAnimator, onResult: @escaping (Face) -> Void) {
            self.coinScene = coinScene
            self.animator = animator
            self.onResult = onResult
            super.init()
        }

        func syncAnimator() {
            switch animator.state {
            case .idle:
                lastPhase = nil

            case .flipping(let phase):
                guard phase != lastPhase else { return }
                lastPhase = phase
                if phase == .launch {
                    let result: Face = Bool.random() ? .a : .b
                    coinScene.animateFlip(result: result) { [weak self] in
                        DispatchQueue.main.async {
                            self?.onResult(result)
                        }
                    }
                }

            case .result(let face):
                onResult(face)
            }
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
swiftc -typecheck \
  FlipCoin/Model/CoinSkin.swift \
  FlipCoin/Scene/SkinTextureRenderer.swift \
  FlipCoin/Scene/CoinGenerator.swift \
  FlipCoin/Model/FlipAnimator.swift \
  FlipCoin/Scene/ParticleManager.swift \
  FlipCoin/Extensions/SCNNode+Flip.swift \
  FlipCoin/Scene/CoinScene.swift \
  FlipCoin/Views/CoinSceneView.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 9: ResultLabel & SettingsPopover

**Files:**
- Create: `FlipCoin/Views/ResultLabel.swift`
- Create: `FlipCoin/Views/SettingsPopover.swift`

**Interfaces:**
- Produces: `ResultLabel` (View), `SettingsPopover` (View)
- Consumes: `CoinSkin`, `Face` (Task 1, 4)

- [ ] **Step 1: Write ResultLabel.swift**

```swift
// FlipCoin/Views/ResultLabel.swift
import SwiftUI

struct ResultLabel: View {
    let result: Face?
    let skin: CoinSkin

    var body: some View {
        Group {
            if let result = result {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.secondary)
                    Text(result == .a ? skin.faceAText : skin.faceBText)
                        .font(.system(.largeTitle, design: .default, weight: .light))
                        .foregroundColor(.primary)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: result)
            } else {
                Text("Tap below to flip")
                    .font(.system(.body, design: .default, weight: .light))
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

- [ ] **Step 2: Write SettingsPopover.swift**

```swift
// FlipCoin/Views/SettingsPopover.swift
import SwiftUI

struct SettingsPopover: View {
    @Binding var skin: CoinSkin
    @Binding var soundEnabled: Bool
    @Binding var hapticEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coin Skin")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(CoinSkin.allCases, id: \.self) { option in
                Button(action: { skin = option }) {
                    HStack(spacing: 10) {
                        Image(systemName: option.symbolName)
                            .frame(width: 24)
                            .foregroundColor(skin == option ? .accentColor : .secondary)
                        Text(option.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if skin == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()

            Toggle(isOn: $soundEnabled) {
                Label("Sound", systemImage: "speaker.wave.2")
            }
            .toggleStyle(.switch)

            #if os(macOS)
            Toggle(isOn: $hapticEnabled) {
                Label("Haptic Feedback", systemImage: "hand.tap")
            }
            .toggleStyle(.switch)
            #endif
        }
        .padding(20)
        .frame(width: 240)
    }
}
```

- [ ] **Step 3: Verify compilation**

```bash
swiftc -typecheck \
  FlipCoin/Model/CoinSkin.swift \
  FlipCoin/Views/ResultLabel.swift \
  FlipCoin/Views/SettingsPopover.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 10: ContentView — Main Layout & Wiring

**Files:**
- Create: `FlipCoin/ContentView.swift`

**Interfaces:**
- Produces: `ContentView` (View)
- Consumes: All prior tasks

- [ ] **Step 1: Write ContentView.swift**

```swift
// FlipCoin/ContentView.swift
import SwiftUI
import SceneKit

struct ContentView: View {

    @AppStorage("coinSkin") private var skin: CoinSkin = .yesNo
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    @StateObject private var animator = FlipAnimator()
    @State private var displayedResult: Face?
    @State private var showSettings = false

    private let coinScene: CoinScene

    init() {
        let initialSkin = CoinSkin.yesNo // @AppStorage not available in init, use default
        self.coinScene = CoinScene(skin: initialSkin)
    }

    var body: some View {
        ZStack {
            // Background
            VisualEffectView(material: .contentBackground)
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
                    .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // 3D Coin viewport
                CoinSceneView(
                    coinScene: coinScene,
                    animator: animator,
                    onResult: { face in
                        displayedResult = face
                        if hapticEnabled {
                            #if os(macOS)
                            NSHapticFeedbackManager.defaultPerformer
                                .perform(.alignment, performanceTime: .now)
                            #endif
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: 300)

                Spacer()

                // Result
                ResultLabel(result: displayedResult, skin: skin)
                    .padding(.bottom, 20)

                // Flip button
                Button(action: flip) {
                    Label("Flip", systemImage: "dice.fill")
                        .font(.system(.body, design: .default, weight: .semibold))
                        .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(animator.isAnimating)
                .keyboardShortcut(.space, modifiers: [])
                .padding(.bottom, 32)
            }
        }
        .frame(minWidth: 350, idealWidth: 350, maxWidth: .infinity,
               minHeight: 500, idealHeight: 500, maxHeight: .infinity)
        .onAppear {
            coinScene.updateSkin(skin)
        }
    }

    private func flip() {
        guard !animator.isAnimating else { return }
        displayedResult = nil
        animator.flip()
    }
}

// MARK: - Visual Effect Bridge (ultraThinMaterial background)

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}
#else
struct VisualEffectView: UIViewRepresentable {
    let material: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: material))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#endif
```

- [ ] **Step 2: Verify full project compilation**

```bash
swiftc -typecheck \
  FlipCoin/Model/CoinSkin.swift \
  FlipCoin/Scene/SkinTextureRenderer.swift \
  FlipCoin/Scene/CoinGenerator.swift \
  FlipCoin/Model/FlipAnimator.swift \
  FlipCoin/Scene/ParticleManager.swift \
  FlipCoin/Extensions/SCNNode+Flip.swift \
  FlipCoin/Scene/CoinScene.swift \
  FlipCoin/Views/CoinSceneView.swift \
  FlipCoin/Views/ResultLabel.swift \
  FlipCoin/Views/SettingsPopover.swift \
  FlipCoin/ContentView.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 11: App Entry Point & Assets

**Files:**
- Create: `FlipCoin/FlipCoinApp.swift`
- Create: `FlipCoin/Assets.xcassets/Contents.json`
- Create: `FlipCoin/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `FlipCoin/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `FlipCoin/Info.plist`

**Interfaces:**
- Produces: Runnable macOS app
- Consumes: `ContentView` (Task 10)

- [ ] **Step 1: Write FlipCoinApp.swift**

```swift
// FlipCoin/FlipCoinApp.swift
import SwiftUI

@main
struct FlipCoinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 350, height: 500)
    }
}
```

- [ ] **Step 2: Write Assets.xcassets/Contents.json**

```bash
mkdir -p FlipCoin/Assets.xcassets/AppIcon.appiconset
mkdir -p FlipCoin/Assets.xcassets/AccentColor.colorset
```

Create `FlipCoin/Assets.xcassets/Contents.json`:
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Write AccentColor.colorset/Contents.json**

Create `FlipCoin/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.906",
          "green" : "0.800",
          "red" : "0.753"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.980",
          "green" : "0.910",
          "red" : "0.890"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Write AppIcon.appiconset/Contents.json**

Create `FlipCoin/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 5: Write Info.plist**

Create `FlipCoin/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>FlipCoin</string>
    <key>CFBundleExecutable</key>
    <string>FlipCoin</string>
    <key>CFBundleIdentifier</key>
    <string>com.flipcoin.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>FlipCoin</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
</dict>
</plist>
```

- [ ] **Step 6: Verify final compilation**

```bash
swiftc -typecheck \
  FlipCoin/Model/CoinSkin.swift \
  FlipCoin/Scene/SkinTextureRenderer.swift \
  FlipCoin/Scene/CoinGenerator.swift \
  FlipCoin/Model/FlipAnimator.swift \
  FlipCoin/Scene/ParticleManager.swift \
  FlipCoin/Extensions/SCNNode+Flip.swift \
  FlipCoin/Scene/CoinScene.swift \
  FlipCoin/Views/CoinSceneView.swift \
  FlipCoin/Views/ResultLabel.swift \
  FlipCoin/Views/SettingsPopover.swift \
  FlipCoin/ContentView.swift \
  FlipCoin/FlipCoinApp.swift \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macos12.0
```
Expected: no output (no errors)

---

### Task 12: Xcode Project Generation & Build

**Files:**
- Create: `scripts/generate-xcodeproj.sh`

- [ ] **Step 1: Write Xcode project generator script**

```bash
mkdir -p scripts
```

Create `scripts/generate-xcodeproj.sh`:
```bash
#!/bin/bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEPROJ="$PROJ_DIR/FlipCoin.xcodeproj"
PBXPROJ="$XCODEPROJ/project.pbxproj"

echo "Generating FlipCoin.xcodeproj..."

# Build with Swift Package Manager as executable
# Since we can't generate .xcodeproj from SPM anymore,
# we use a direct build approach for validation.

# Actually compile all sources into a macOS app
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
SWIFT_FILES=$(find "$PROJ_DIR/FlipCoin" -name "*.swift" | sort)

echo "Compiling Swift sources..."
swiftc \
  -sdk "$SDK_PATH" \
  -target "$(uname -m)-apple-macos12.0" \
  -framework SwiftUI \
  -framework SceneKit \
  -framework AppKit \
  -o "$PROJ_DIR/build/FlipCoin" \
  $SWIFT_FILES \
  -Xlinker -rpath -Xlinker /System/Library/Frameworks

echo "Binary built: $PROJ_DIR/build/FlipCoin"

# Create minimal .app bundle
APP_DIR="$PROJ_DIR/build/FlipCoin.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$PROJ_DIR/build/FlipCoin" "$APP_DIR/Contents/MacOS/FlipCoin"
cp "$PROJ_DIR/FlipCoin/Info.plist" "$APP_DIR/Contents/Info.plist"

# Copy assets
if [ -d "$PROJ_DIR/FlipCoin/Assets.xcassets" ]; then
    cp -R "$PROJ_DIR/FlipCoin/Assets.xcassets" "$APP_DIR/Contents/Resources/"
fi

echo "App bundle created: $APP_DIR"
echo ""
echo "To run: open $APP_DIR"
```

- [ ] **Step 2: Make script executable and build**

```bash
chmod +x scripts/generate-xcodeproj.sh
bash scripts/generate-xcodeproj.sh
```
Expected: binary built successfully, .app bundle created

- [ ] **Step 3: Run the app**

```bash
open build/FlipCoin.app
```
Expected: app launches, 3D silver coin visible, click "Flip" → animation plays

---

### Task 13: Polish Pass — Verify All Success Criteria

- [ ] **Step 1: Verify PBR silver coin renders with reflections**

Manual check: launch app, observe coin. Metallic sheen visible, light reflects off surface naturally.

- [ ] **Step 2: Verify three-phase animation**

Manual check: tap "Flip", observe: coin rises with trail → hovers with sparkles → lands with burst.

- [ ] **Step 3: Verify four skins**

Manual check: open settings ⚙, switch to each skin, tap flip after each. Verify "YES/NO", "A/B", "1/2", "☀️/🌙" all render.

- [ ] **Step 4: Verify skin persistence**

Manual check: switch skin to "☀️/🌙", quit app (⌘Q), relaunch. Verify settings still show "☀️/🌙".

- [ ] **Step 5: Verify Apple HIG compliance**

Check: system fonts used, `.ultraThinMaterial` background, SF Symbols in UI, system blue tint on button, standard spacing.

- [ ] **Step 6: Verify space bar hotkey**

Manual check: press space bar when app is focused → coin flips. Press again during animation → nothing (disabled).

- [ ] **Step 7: Verify haptic feedback**

Manual check: flip coin, feel trackpad haptic on landing impact (Mac only).

- [ ] **Step 8: Verify resizing**

Manual check: resize window larger and smaller. 3D coin scales correctly, layout maintains proportions.

- [ ] **Step 9: Verify dark mode**

Manual check: switch system to dark mode (System Settings → Appearance → Dark). App background and text adapt automatically.
