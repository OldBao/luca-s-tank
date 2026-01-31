import SpriteKit

class Explosion: SKSpriteNode {
    init(at position: CGPoint, size: ExplosionSize) {
        let pixelSize: CGFloat = size == .small ? Constants.tileSize : 32
        let tex = SpriteManager.shared.explosionTexture(size: size, frame: 0)
        super.init(texture: tex, color: .clear, size: CGSize(width: pixelSize, height: pixelSize))
        self.position = position
        self.zPosition = 20
        self.name = "explosion"

        // Animate and remove
        let frame0 = SpriteManager.shared.explosionTexture(size: size, frame: 0)
        let frame1 = SpriteManager.shared.explosionTexture(size: size, frame: 1)

        let anim: SKAction
        if size == .large {
            let frame2 = SpriteManager.shared.explosionTexture(size: size, frame: 2)
            anim = SKAction.sequence([
                SKAction.setTexture(frame0),
                SKAction.wait(forDuration: 0.08),
                SKAction.setTexture(frame1),
                SKAction.wait(forDuration: 0.08),
                SKAction.setTexture(frame2),
                SKAction.resize(toWidth: 32, height: 32, duration: 0),
                SKAction.wait(forDuration: 0.08),
                SKAction.setTexture(frame1),
                SKAction.resize(toWidth: pixelSize, height: pixelSize, duration: 0),
                SKAction.wait(forDuration: 0.08),
                SKAction.removeFromParent()
            ])
        } else {
            anim = SKAction.sequence([
                SKAction.setTexture(frame0),
                SKAction.wait(forDuration: 0.1),
                SKAction.setTexture(frame1),
                SKAction.wait(forDuration: 0.1),
                SKAction.setTexture(frame0),
                SKAction.wait(forDuration: 0.1),
                SKAction.removeFromParent()
            ])
        }
        self.run(anim)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
