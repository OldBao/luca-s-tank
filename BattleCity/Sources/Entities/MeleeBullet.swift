import SpriteKit

class MeleeBullet: SKSpriteNode {
    let direction: Direction
    let moveSpeed: CGFloat
    let teamIndex: Int
    let canDestroySteel: Bool
    let ownerID: ObjectIdentifier

    init(direction: Direction, speed: CGFloat, teamIndex: Int,
         canDestroySteel: Bool = false, owner: MeleeTank) {
        self.direction = direction
        self.moveSpeed = speed
        self.teamIndex = teamIndex
        self.canDestroySteel = canDestroySteel
        self.ownerID = ObjectIdentifier(owner)

        let tex = SpriteManager.shared.bulletTexture(direction: direction)
        super.init(texture: tex, color: .clear, size: CGSize(width: 4, height: 4))
        self.zPosition = 11
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
