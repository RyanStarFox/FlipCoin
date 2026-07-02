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
        cameraNode.camera?.fieldOfView = 42
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        // ~45° downward — looking at a flat coin on the table from your seat.
        // Height ≈ forward distance gives a clean 3/4 perspective.
        cameraNode.position = SCNVector3(0, 5.5, 5.5)
        cameraNode.look(at: SCNVector3(0, 0.2, 0))
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLights() {
        // Ambient — soft fill so nothing goes pure black
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.intensity = 350
        ambient.light!.color = PlatformColor(white: 0.55, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        // Key — from upper-right, drives PBR specular on the silver coin
        let key = SCNNode()
        key.light = SCNLight()
        key.light!.type = .directional
        key.light!.intensity = 800
        key.light!.color = PlatformColor(white: 0.95, alpha: 1.0)
        key.position = SCNVector3(5, 10, 4)
        key.look(at: SCNVector3(0, 0, 0))
        key.light!.castsShadow = false
        scene.rootNode.addChildNode(key)

        // Soft fill from front-left
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light!.type = .directional
        fill.light!.intensity = 250
        fill.light!.color = PlatformColor(white: 0.65, alpha: 1.0)
        fill.position = SCNVector3(-3, 3, 5)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)
    }

    // MARK: - Reflective floor (light tabletop)

    private func setupFloor() {
        let floor = SCNFloor()
        floor.reflectivity = 0.22           // subtle — clear enough to see the coin mirrored
        floor.reflectionFalloffEnd = 10.0
        floor.reflectionResolutionScaleFactor = 1.0

        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        // Pure white desk surface
        mat.diffuse.contents = PlatformColor(white: 1.0, alpha: 1.0)
        mat.metalness.contents = 0.15
        mat.roughness.contents = 0.35
        floor.materials = [mat]

        let floorNode = SCNNode(geometry: floor)
        // Floor just below coin bottom — coin sits ON the visible surface.
        // Coin center is at y=0, coin bottom at y=-0.065. Floor at y=-0.07.
        floorNode.position = SCNVector3(0, -0.07, 0)
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
