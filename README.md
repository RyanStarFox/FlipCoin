# FlipCoin 🪙

A lightweight, beautiful coin-flipping app for quick decisions. Silver PBR coin with 3D animation, particle effects, and four interchangeable skins. Built with SwiftUI + SceneKit.

## Features

- **Photorealistic 3D coin** — PBR material (silver, metalness 0.95) with procedural face textures
- **Three-phase flip animation** — Launch (spin + rise) → Hover (decelerate) → Land (spring bounce)
- **Particle effects** — Silver sparkle trail, orbital hover particles, and impact burst
- **4 coin skins** — Yes/No, A/B, 1/2, ☀️/🌙 — persisted across launches
- **Apple HIG design** — System fonts, UltraThinMaterial background, SF Symbols, dark mode support
- **Haptic feedback** — Trackpad haptic on coin landing
- **Keyboard shortcut** — Press Space to flip

## Requirements

- macOS 12.0+
- Xcode 15.0+ (for Swift 5.9)

## Build

```bash
bash scripts/build.sh
open build/FlipCoin.app
```

## Project Structure

```
FlipCoin/
├── Model/
│   ├── CoinSkin.swift          # 4 skin definitions (persisted via @AppStorage)
│   └── FlipAnimator.swift      # Animation state machine (idle → flipping → result)
├── Scene/
│   ├── SkinTextureRenderer.swift  # Programmatic texture generation
│   ├── CoinGenerator.swift        # Procedural 3D coin + PBR materials
│   ├── ParticleManager.swift      # Trail / hover / burst particle systems
│   └── CoinScene.swift            # Scene assembly (camera, 4-point lighting)
├── Views/
│   ├── CoinSceneView.swift     # SceneKit ↔ SwiftUI bridge (macOS + iOS)
│   ├── ResultLabel.swift       # Animated result display
│   └── SettingsPopover.swift   # Skin picker + sound/haptic toggles
├── Extensions/
│   └── SCNNode+Flip.swift      # Three-phase flip animation sequence
├── FlipCoinApp.swift           # @main entry point
├── ContentView.swift           # Main layout + VisualEffectView
├── Info.plist
└── Assets.xcassets/
```

## License

MIT
