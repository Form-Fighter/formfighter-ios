import SceneKit
import ModelIO

class AnimationController: NSObject {
    private var sceneView: SCNView
    private var currentFrameIndex = 0
    private var frameNodes: [SCNNode] = []
    private var displayLink: CADisplayLink?

    init(sceneView: SCNView) {
        self.sceneView = sceneView
        super.init()
    }

    func setupScene(with url: URL) {
        do {
            let scene = try SCNScene(url: url, options: nil)
            sceneView.scene = scene

            if let armatureNode = scene.rootNode.childNode(withName: "Armature", recursively: true) {
                frameNodes = armatureNode.childNodes
                startAnimation()
            }
        } catch {
            print("Failed to load scene: \(error.localizedDescription)")
        }
    }

    func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateAnimation() {
        guard !frameNodes.isEmpty else { return }
        frameNodes.forEach { $0.isHidden = true }
        frameNodes[currentFrameIndex].isHidden = false
        currentFrameIndex = (currentFrameIndex + 1) % frameNodes.count
    }

    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
}
