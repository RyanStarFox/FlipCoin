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

    // MARK: - Scene assembly

    private func setupScene() {
        // Transparent background — SwiftUI provides the backdrop
        scene.background.contents = PlatformColor.clear

        setupCamera()
        setupLights()
        setupCoin()
        setupParticles()
    }

    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 1.5, 8)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLights() {
        // Ambient — fills shadows so no part is pure black
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.intensity = 400
        ambient.light!.color = PlatformColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        // Key light — directional from top-right, creates PBR specular highlights
        let key = SCNNode()
        key.light = SCNLight()
        key.light!.type = .directional
        key.light!.intensity = 1000
        key.light!.color = PlatformColor(white: 0.95, alpha: 1.0)
        key.position = SCNVector3(5, 8, 5)
        key.look(at: SCNVector3(0, 0, 0))
        key.light!.castsShadow = false
        scene.rootNode.addChildNode(key)

        // Fill light — softer, from below-left, reduces harsh shadows
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light!.type = .directional
        fill.light!.intensity = 300
        fill.light!.color = PlatformColor(white: 0.7, alpha: 1.0)
        fill.position = SCNVector3(-4, 2, 3)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)

        // Rim light — from behind-right, creates edge highlight on the coin
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light!.type = .directional
        rim.light!.intensity = 500
        rim.light!.color = PlatformColor(white: 0.85, alpha: 1.0)
        rim.position = SCNVector3(3, 3, -4)
        rim.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(rim)
    }

    private func setupCoin() {
        scene.rootNode.addChildNode(coinNode)
    }

    private func setupParticles() {
        // Particle nodes are children of the coin so they move with it
        coinNode.addChildNode(particleManager.trailNode)
        coinNode.addChildNode(particleManager.hoverNode)
        coinNode.addChildNode(particleManager.burstNode)
    }

    // MARK: - Public API

    func updateSkin(_ skin: CoinSkin) {
        currentSkin = skin
        CoinGenerator.updateSkin(coinNode, skin: skin)
    }

    func animateFlip(result: Face, completion: @escaping () -> Void) {
        coinNode.flipAnimation(
            result: result,
            particleManager: particleManager,
            completion: completion
        )
    }
}
