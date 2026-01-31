import SpriteKit

class SpawnEffect: SKSpriteNode {
    var onComplete: (() -> Void)?

    init(at position: CGPoint, completion: @escaping () -> Void) {
        self.onComplete = completion
        let tex = SpriteManager.shared.spawnTexture(frame: 0)
        super.init(texture: tex, color: .clear, size: CGSize(width: Constants.tileSize, height: Constants.tileSize))
        self.position = position
        self.zPosition = 20
        self.name = "spawnEffect"

        let frames = (0..<4).map { SpriteManager.shared.spawnTexture(frame: $0) }

        // Sparkle animation: cycle through frames 3-4 times
        var actions: [SKAction] = []
        for _ in 0..<4 {
            for f in frames {
                actions.append(SKAction.setTexture(f))
                actions.append(SKAction.wait(forDuration: 0.06))
            }
        }
        actions.append(SKAction.run { [weak self] in
            self?.onComplete?()
        })
        actions.append(SKAction.removeFromParent())

        self.run(SKAction.sequence(actions))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
