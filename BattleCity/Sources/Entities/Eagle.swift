import SpriteKit

class Eagle: SKSpriteNode {
    var isAlive: Bool = true

    init() {
        let tex = SpriteManager.shared.eagleTexture(alive: true)
        super.init(texture: tex, color: .clear, size: CGSize(width: Constants.tileSize, height: Constants.tileSize))
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.zPosition = 5
        self.name = "eagle"

        // No SpriteKit physics - collision handled manually
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func destroy() {
        isAlive = false
        self.texture = SpriteManager.shared.eagleTexture(alive: false)
    }

    func setTilePosition(tileX: Int, tileY: Int) {
        self.position = CGPoint(
            x: Constants.playAreaOriginX + CGFloat(tileX) * Constants.tileSize + Constants.tileSize / 2,
            y: Constants.playAreaOriginY + Constants.playAreaSize - (CGFloat(tileY) * Constants.tileSize + Constants.tileSize / 2)
        )
    }
}
