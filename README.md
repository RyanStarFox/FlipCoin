# FlipCoin 🪙

> A lightweight coin-flipping app for quick decisions. Tap the button, watch the 3D coin spin, and get your answer — with style.

[![macOS](https://img.shields.io/badge/macOS-12.0+-silver?logo=apple)](https://github.com/RyanStarFox/FlipCoin/releases)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Size](https://img.shields.io/badge/size-408KB-lightgrey)](https://github.com/RyanStarFox/FlipCoin/releases)

---

## 🎬 Preview

| Idle | Flipping | Result |
|------|----------|--------|
| *(Silver coin facing camera)* | *(Coin spinning with sparkle trail)* | *(✨ YES / NO display)* |

---

## ⬇️ Download

| Format | Platform | Link |
|--------|----------|------|
| **.dmg** | macOS (Apple Silicon) | [FlipCoin-v1.0.0.dmg](https://github.com/RyanStarFox/FlipCoin/releases/download/v1.0.0/FlipCoin-v1.0.0.dmg) (111 KB) |
| **.zip** | macOS (Apple Silicon) | [FlipCoin-v1.0.0-macOS.zip](https://github.com/RyanStarFox/FlipCoin/releases/download/v1.0.0/FlipCoin-v1.0.0-macOS.zip) (97 KB) |

> **Install:** Open `.dmg` → drag `FlipCoin.app` to `/Applications`. Or unzip `.zip` and run directly.
>
> **Notarization:** This is an unsigned open-source build. On first launch, right-click → **Open** to bypass Gatekeeper.

---

## ✨ Features

- **Photorealistic 3D Silver Coin** — PBR material (metalness 0.95, roughness 0.25) with 4-point studio lighting for natural metallic reflections
- **Three-Phase Flip Animation** — Launch (rapid spin + rise) → Hover (decelerate + micro-bounce) → Land (spring damped bounce)
- **Silver Particle Effects** — Streaming sparkle trail during launch, orbital twinkle during hover, radial burst on landing impact
- **4 Coin Skins** — Yes/No, A/B, 1/2, ☀️/🌙 — persisted across app launches via `@AppStorage`
- **Apple HIG Design** — System fonts (SF Pro), `.ultraThinMaterial` background, SF Symbols, dark/light mode auto-switch
- **Haptic Feedback** — Trackpad haptic vibration on coin landing (Mac only)
- **Keyboard Shortcut** — Press `Space` to flip, `⌘,` for settings
- **408 KB App** — Zero external dependencies, pure SwiftUI + SceneKit

---

## 🛠 Build from Source

### Prerequisites

- macOS 12.0+
- Xcode 15.0+ (for Swift 5.9 compiler)
- Xcode Command Line Tools (`xcode-select --install`)

### Quick Build (macOS)

```bash
git clone https://github.com/RyanStarFox/FlipCoin.git
cd FlipCoin
bash scripts/build.sh
open build/macos/FlipCoin.app
```

The build script also generates `.dmg` and `.zip` artifacts in `dist/`.

### iOS / iPadOS

Source code is fully cross-platform with `#if os(macOS)` guards. To build for iOS:

1. Open the `FlipCoin/` folder in Xcode (File → New → Project → iOS → App, then add existing Swift files)
2. Select an iOS Simulator or connected device
3. Product → Run (`⌘R`)
4. To create a signed `.ipa`: Product → Archive → Distribute App

> ⚠️ `.ipa` requires an Apple Developer account for code signing.

### Build Options

```bash
bash scripts/build.sh [version]   # default: 1.0.0
```

---

## 🏗 Architecture

```
FlipCoin/
├── Model/
│   ├── CoinSkin.swift            # Enum: 4 skins + face text + SF Symbol icons
│   └── FlipAnimator.swift        # State machine: idle → flipping(launch/hover/land) → result
├── Scene/
│   ├── SkinTextureRenderer.swift # CGContext-drawn face/side textures (macOS + iOS)
│   ├── CoinGenerator.swift       # SCNCylinder geometry + PBR metallic material
│   ├── ParticleManager.swift     # 3× SCNParticleSystem (trail / hover / burst)
│   └── CoinScene.swift           # Camera, 4-point lighting, scene graph assembly
├── Views/
│   ├── CoinSceneView.swift       # NSViewRepresentable ↔ UIViewRepresentable bridge
│   ├── ResultLabel.swift         # SwiftUI animated result text
│   └── SettingsPopover.swift     # Skin picker + sound/haptic toggle popover
├── Extensions/
│   └── SCNNode+Flip.swift        # SCNAction sequence: 3-phase coin animation
├── FlipCoinApp.swift             # @main SwiftUI App
├── ContentView.swift             # Shell layout + VisualEffectView
├── Info.plist                    # Bundle metadata
└── Assets.xcassets/              # App icon + accent color
```

**Data flow:**

```
User taps Flip
    → FlipAnimator.flip()               (picks random Face, starts state machine)
    → CoinSceneView.Coordinator         (reads animator.result, triggers SceneKit)
    → SCNNode.flipAnimation()           (SCNAction sequence with particle triggers)
    → ParticleManager                   (birthRate toggling on phase boundaries)
    → Completion callback               (ResultLabel animates in)
```

---

## 🎨 Skins

| Skin | Face A | Face B |
|------|--------|--------|
| Yes / No | YES | NO |
| A / B | A | B |
| 1 / 2 | 1 | 2 |
| ☀️ / 🌙 | ☀️ | 🌙 |

Switch skins anytime via the ⚙ button. Selection is remembered between launches.

---

## 📝 License

MIT — do whatever you want with it. Contributions welcome!
