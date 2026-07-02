import SceneKit

struct CoinGenerator {

    static let coinRadius: CGFloat = 1.3
    static let coinHeight: CGFloat = 0.13
    static let coinSegments: Int = 96

    static func generate(skin: CoinSkin) -> SCNNode {
        let coinNode = SCNNode()
        coinNode.name = "coin"

        // Geometry
        let cylinder = SCNCylinder(radius: coinRadius, height: coinHeight)
        cylinder.radialSegmentCount = coinSegments

        // Rotate so the flat face points toward the camera (+Z).
        // SCNCylinder's top face is at +Y by default; rotating π/2 around X
        // makes the top face point toward +Z (the camera axis).
        coinNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)

        // Texture sizes
        let faceSize = CGSize(width: 512, height: 512)
        let sideSize = CGSize(width: 512, height: 64)

        let faceATex = SkinTextureRenderer.renderFace(skin.faceAText, size: faceSize)
        let faceBTex = SkinTextureRenderer.renderFace(skin.faceBText, size: faceSize)
        let sideTex  = SkinTextureRenderer.renderSide(size: sideSize)

        // --- Top face (Face A) ---
        let topMat = SCNMaterial()
        topMat.lightingModel = .physicallyBased
        topMat.diffuse.contents = faceATex
        topMat.metalness.contents = 0.95
        topMat.roughness.contents = 0.25
        topMat.name = "faceA"

        // --- Bottom face (Face B) ---
        let botMat = SCNMaterial()
        botMat.lightingModel = .physicallyBased
        botMat.diffuse.contents = faceBTex
        botMat.metalness.contents = 0.95
        botMat.roughness.contents = 0.25
        botMat.name = "faceB"

        // --- Side / edge ---
        let sideMat = SCNMaterial()
        sideMat.lightingModel = .physicallyBased
        sideMat.diffuse.contents = sideTex
        sideMat.metalness.contents = 0.95
        sideMat.roughness.contents = 0.20
        sideMat.name = "edge"

        cylinder.materials = [topMat, botMat, sideMat]
        coinNode.geometry = cylinder

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
