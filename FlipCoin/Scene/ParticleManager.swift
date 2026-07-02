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

        // Trail and hover are continuous (looping); burst is one-shot.
        // Attach emitter shapes to nodes so particles move with the coin.
        trailNode.addParticleSystem(trailSystem)
        hoverNode.addParticleSystem(hoverSystem)
    }

    // MARK: - Control methods

    func startTrail() {
        trailSystem.birthRate = 200
    }

    func stopTrail() {
        trailSystem.birthRate = 0
    }

    func startHover() {
        hoverSystem.birthRate = 30
    }

    func stopHover() {
        hoverSystem.birthRate = 0
    }

    func triggerBurst() {
        // One-shot burst: attach a fresh copy each time
        let burstCopy = ParticleManager.makeBurstSystem()
        burstNode.addParticleSystem(burstCopy)
    }

    // MARK: - Particle system factories

    private static func makeTrailSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 0 // start inactive, enabled by startTrail()
        ps.birthDirection = .random
        ps.emissionDuration = 0      // continuous
        ps.particleLifeSpan = 0.4
        ps.particleLifeSpanVariation = 0.15

        // Silver sparkle appearance
        ps.particleColor = PlatformColor(white: 0.88, alpha: 1.0)
        ps.particleColorVariation = SCNVector4(0.08, 0.08, 0.08, 0.0)
        ps.particleSize = 0.06
        ps.particleSizeVariation = 0.03

        // Physics: spray outward, drift down gently
        ps.speedFactor = 0.15
        ps.spreadingAngle = 60
        ps.particleVelocity = 1.5
        ps.particleVelocityVariation = 0.8
        ps.acceleration = SCNVector3(0, -0.3, 0)

        // Additive blend for glowing sparkles
        ps.blendMode = .additive
        ps.fresnelExponent = 4
        ps.particleImage = makeSparkImage(size: 8, color: .silver)

        // Emitter shape: ring around coin edge
        ps.emitterShape = SCNTorus(ringRadius: 1.0, pipeRadius: 0.03)

        return ps
    }

    private static func makeHoverSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 0 // start inactive
        ps.birthDirection = .random
        ps.emissionDuration = 0
        ps.particleLifeSpan = 1.2
        ps.particleLifeSpanVariation = 0.5

        // Softer, sparser sparkles
        ps.particleColor = PlatformColor(white: 0.9, alpha: 0.7)
        ps.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0.0)
        ps.particleSize = 0.04
        ps.particleSizeVariation = 0.02

        // Slow drift outward
        ps.speedFactor = 0.06
        ps.spreadingAngle = 90
        ps.particleVelocity = 0.6
        ps.particleVelocityVariation = 0.4

        ps.blendMode = .additive
        ps.particleImage = makeSparkImage(size: 6, color: .silver)

        // Spherical emitter — particles surround the coin
        ps.emitterShape = SCNSphere(radius: 1.1)

        return ps
    }

    private static func makeBurstSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 800
        ps.birthDirection = .random
        ps.emissionDuration = 0.05       // instant burst
        ps.particleLifeSpan = 0.5
        ps.particleLifeSpanVariation = 0.25
        ps.loops = false                 // one-shot

        // Bright silver burst
        ps.particleColor = PlatformColor(white: 0.95, alpha: 1.0)
        ps.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.0)
        ps.particleSize = 0.08
        ps.particleSizeVariation = 0.05

        // Explosive outward spread
        ps.emittingDirection = SCNVector3(0, 0, 1)
        ps.spreadingAngle = 120
        ps.particleVelocity = 4.0
        ps.particleVelocityVariation = 2.0

        ps.blendMode = .additive
        ps.fresnelExponent = 3
        ps.particleImage = makeSparkImage(size: 10, color: .silver)

        ps.emitterShape = SCNTorus(ringRadius: 0.8, pipeRadius: 0.1)

        return ps
    }

    // MARK: - Spark image generator

    private enum SparkColor {
        case silver

        var cgColor: CGColor {
            switch self {
            case .silver: return CGColor(gray: 1.0, alpha: 1.0)
            }
        }
    }

    private static func makeSparkImage(size: Int, color: SparkColor) -> PlatformImage {
        let s = CGFloat(size)

        #if os(macOS)
        let image = NSImage(size: NSSize(width: s, height: s))
        image.lockFocus()
        defer { image.unlockFocus() }
        guard let ctx = NSGraphicsContext.current?.cgContext else { return image }
        drawSpark(ctx: ctx, size: s, color: color)
        return image
        #else
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: s, height: s))
        return renderer.image { ctx in
            drawSpark(ctx: ctx.cgContext, size: s, color: color)
        }
        #endif
    }

    private static func drawSpark(ctx: CGContext, size: CGFloat, color: SparkColor) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let colors = [
            color.cgColor,
            CGColor(gray: 0.8, alpha: 0.0)
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors,
            locations: locations
        ) {
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: size / 2,
                options: []
            )
        }
    }
}
