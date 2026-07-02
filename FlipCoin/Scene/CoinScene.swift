import SceneKit

class CoinScene {

    let scene = SCNScene()
    let coinNode: SCNNode

    private(set) var currentSkin: CoinSkin

    init(skin: CoinSkin) {
        self.currentSkin = skin
        self.coinNode = CoinGenerator.generate(skin: skin)
        setupScene()
    }

    // MARK: - Scene assembly

    private func setupScene() {
        scene.background.contents = PlatformColor.clear

        setupCamera()
        setupLights()
        setupFloor()
        setupCoin()
    }

    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        // 3/4 angled perspective — like looking down at a coin on a table.
        // Camera is elevated and in front, tilted down toward the scene origin.
        cameraNode.position = SCNVector3(0, 5, 7)
        cameraNode.look(at: SCNVector3(0, -0.8, 0))
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLights() {
        // Ambient — prevents pure-black shadows
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.intensity = 350
        ambient.light!.color = PlatformColor(white: 0.55, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        // Key light — from upper-right, creates metallic specular response
        let key = SCNNode()
        key.light = SCNLight()
        key.light!.type = .directional
        key.light!.intensity = 900
        key.light!.color = PlatformColor(white: 0.95, alpha: 1.0)
        key.position = SCNVector3(5, 10, 4)
        key.look(at: SCNVector3(0, 0, 0))
        key.light!.castsShadow = false
        scene.rootNode.addChildNode(key)

        // Subtle fill — from below-front, softens coin underside
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light!.type = .directional
        fill.light!.intensity = 250
        fill.light!.color = PlatformColor(white: 0.65, alpha: 1.0)
        fill.position = SCNVector3(-3, 3, 5)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)
    }

    // MARK: - Reflective floor ("地平线" with coin reflection)

    private func setupFloor() {
        // SCNFloor is an infinite plane that SceneKit can render with
        // screen-space reflections when paired with a PBR material.
        let floor = SCNFloor()
        floor.reflectivity = 0.35           // subtle mirror — enough to see the coin
        floor.reflectionFalloffEnd = 12.0   // reflections fade into the distance
        floor.reflectionResolutionScaleFactor = 1.0

        let floorMaterial = SCNMaterial()
        floorMaterial.lightingModel = .physicallyBased
        // Dark polished tabletop — the darkness makes the silver reflection pop
        floorMaterial.diffuse.contents = PlatformColor(white: 0.12, alpha: 1.0)
        floorMaterial.metalness.contents = 0.5
        floorMaterial.roughness.contents = 0.15
        floor.materials = [floorMaterial]

        let floorNode = SCNNode(geometry: floor)
        // Position well below the coin so the bounce trajectory is visible
        floorNode.position = SCNVector3(0, -2.5, 0)
        floorNode.name = "floor"
        scene.rootNode.addChildNode(floorNode)
    }

    private func setupCoin() {
        scene.rootNode.addChildNode(coinNode)
    }

    // MARK: - Public API

    func updateSkin(_ skin: CoinSkin) {
        currentSkin = skin
        CoinGenerator.updateSkin(coinNode, skin: skin)
    }

    func animateFlip(result: Face, completion: @escaping () -> Void) {
        coinNode.flipAnimation(result: result, completion: completion)
    }
}
