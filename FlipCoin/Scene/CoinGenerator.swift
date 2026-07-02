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
