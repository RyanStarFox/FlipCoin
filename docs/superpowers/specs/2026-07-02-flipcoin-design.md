# FlipCoin Design Spec

**Date**: 2026-07-02
**Target**: macOS 12+, iOS 16+, iPadOS 16+
**Framework**: SwiftUI + SceneKit

---

## Overview

A lightweight coin-flipping decision app with photorealistic 3D animation and particle effects. Silver coin with PBR materials, four interchangeable skins, system-native Apple HIG aesthetics.

## Architecture

```
FlipCoin/
├── FlipCoinApp.swift              App entry point
├── ContentView.swift              Main view layout
├── Views/
│   ├── CoinSceneView.swift        SceneKit ↔ SwiftUI bridge
│   ├── SettingsPopover.swift      Skin picker popover
│   └── ResultLabel.swift          Result text display
├── Scene/
│   ├── CoinScene.swift            SCNScene assembly (lights, camera)
│   ├── CoinGenerator.swift        Procedural coin geometry + PBR material
│   ├── SkinTextureRenderer.swift  Face texture rendering per skin
│   └── ParticleManager.swift      Particle system management
├── Model/
│   ├── CoinSkin.swift             Skin enum definition
│   └── FlipAnimator.swift         Animation state machine
├── Extensions/
│   └── SCNNode+Flip.swift         Coin flip animation extensions
└── Assets.xcassets                Icons, colors
```

- **SwiftUI** manages all UI chrome (buttons, result text, settings popover)
- **SceneKit** manages the 3D viewport (coin model, particles, lights, camera)
- **FlipAnimator** is a decoupled state machine driving SCNNode animations
- Platform bridges: `NSViewRepresentable` on macOS, `UIViewRepresentable` on iOS/iPadOS

## Coin Model

- Procedural `SCNCylinder` — no external 3D model files
  - Radius: 1.0, Height: 0.06, Radial segments: 64
- PBR material with `physicallyBased` lighting model:
  - `metalness`: 0.95 (silver)
  - `roughness`: 0.25 (soft reflections)
  - Diffuse color: silver-white (#E0E0E0)
- Three material surfaces:
  - **Top face**: skin-specific face A texture
  - **Bottom face**: skin-specific face B texture
  - **Side/edge**: silver metallic with subtle reeded edge detail

## Coin Skins

```swift
enum CoinSkin: String, CaseIterable, Codable {
    case yesNo     // "YES" · "NO"
    case ab        // "A" · "B"
    case oneTwo    // "1" · "2"
    case sunMoon   // "☀️" · "🌙"
}
```

- Each skin generates face textures programmatically (text + SF Symbol rendered to image)
- Skin stored via `@AppStorage` for automatic persistence across launches
- Settings accessible via gear icon (top-right) → popover with instant preview

## Animation State Machine

```
idle → flipping (2.5s total) → result → idle
```

### Phase 1: Launch (0 → 1.2s)
- Coin rises on Y-axis by 8 units
- X-axis spins 6–8 full rotations (rapid blur)
- Silver sparkle trail particles emit from coin edge

### Phase 2: Hover (1.2 → 1.8s)
- Y-axis micro-bounce at apex
- X-axis rotation decelerates to 1–2 rotations
- Particles switch to sparse orbiting sparkles

### Phase 3: Land (1.8 → 2.5s)
- Y-axis drops to origin with spring damping (overshoot → bounce → settle)
- X-axis rotation aligns to show final face
- Impact burst particles on landing
- Subtle camera shake on impact

### Easing
- Launch: ease-out (fast start, slow at apex)
- Land: ease-in + spring (fast fall, bouncy settle)
- Spin: linear → decelerating

## Particle Effects

Three particle systems, active by phase:

| System | Phase | Behavior |
|--------|-------|----------|
| Trail | Launch | Silver sparkles (#C0C0C0 → #E8E8E8) streaming from coin edge, fade over 0.4s |
| Hover | Hover | Sparse twinkling stars orbiting slowly around coin center |
| Burst | Landing | Radial burst of silver sparks + glow ring, duration 0.5s |

All particles are cold-tone silver to match the coin material.

## UI Layout (Apple HIG)

```
┌──────────────────────────┐
│                     [⚙]  │  ← Settings (SF Symbol gear, top-right)
│                          │
│      3D Coin View        │  ← 75% of window height
│                          │
│       ✨ YES             │  ← Result in SF Pro Display Light
│                          │
│  ┌──────────────────┐    │
│  │   🎲 再来一次      │    │  ← System blue tint, cornerRadius 14
│  └──────────────────┘    │
└──────────────────────────┘
```

- Default window: 350×500, resizable
- Background: `.ultraThinMaterial` + system background (auto light/dark)
- Button: prominent filled style, SF Symbol "dice.fill" icon
- Result text: SF Pro Display, Light weight, large size
- Settings popover: skin radio selection + sound/haptic toggles

## Audio & Haptics (Optional)

- **Sound**: Metallic coin rotation sound during flip (toggle in settings, default on)
- **Haptics**: `NSHapticFeedbackManager` on impact (toggle in settings, default on)
  - Only triggers on Mac trackpads; silent on mouse-only setups
- **Keyboard**: Space bar triggers flip

## Cross-Platform Notes

- macOS: `NSViewRepresentable` bridge for SCNView
- iOS/iPadOS: `UIViewRepresentable` bridge for SCNView
- Shared: ~95% code reuse across Apple platforms
- Windows/Linux: Not supported (SceneKit is Apple-only)

## Success Criteria

- [ ] Silver PBR coin renders with realistic metallic reflections
- [ ] Three-phase flip animation plays smoothly at 60+ fps
- [ ] Silver particle effects trigger at correct animation phases
- [ ] Four skins switchable in settings, persists across restarts
- [ ] Apple HIG-compliant UI (system fonts, materials, colors)
- [ ] Space bar hotkey triggers flip
- [ ] Runs on macOS 12+; iOS/iPadOS builds compile

