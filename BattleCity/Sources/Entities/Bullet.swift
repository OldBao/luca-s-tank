import SpriteKit

class Bullet: SKSpriteNode {
    let direction: Direction
    let moveSpeed: CGFloat
    let isPlayerBullet: Bool
    let canDestroySteel: Bool
    let ownerID: ObjectIdentifier?

    init(direction: Direction, speed: CGFloat, isPlayerBullet: Bool, canDestroySteel: Bool = false, ownerID: ObjectIdentifier? = nil) {
        self.direction = direction
        self.moveSpeed = speed
        self.isPlayerBullet = isPlayerBullet
        self.canDestroySteel = canDestroySteel
        self.ownerID = ownerID

        let tex = SpriteManager.shared.bulletTexture(direction: direction)
        super.init(texture: tex, color: .clear, size: CGSize(width: 4, height: 4))
        self.zPosition = 11
        self.name = isPlayerBullet ? "playerBullet" : "enemyBullet"

        // No SpriteKit physics - all collision handled manually in GameScene
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
