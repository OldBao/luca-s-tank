import SpriteKit

class PowerUp: SKSpriteNode {
    let powerUpType: PowerUpType
    private var flashTimer: TimeInterval = 0
    private var isVisible: Bool = true

    init(type: PowerUpType) {
        self.powerUpType = type
        let tex = SpriteManager.shared.powerUpTexture(type: type)
        super.init(texture: tex, color: .clear, size: CGSize(width: Constants.tileSize, height: Constants.tileSize))
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.zPosition = 12
        self.name = "powerUp"

        // No SpriteKit physics - collision handled manually

        // Flashing animation
        let flash = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.2),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2),
        ]))
        self.run(flash, withKey: "flash")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func placeRandomly(playAreaSize: CGFloat) {
        let margin = Constants.tileSize
        let x = CGFloat.random(in: margin...(playAreaSize - margin)) + Constants.playAreaOriginX
        let y = CGFloat.random(in: margin...(playAreaSize - margin)) + Constants.playAreaOriginY
        self.position = CGPoint(x: x, y: y)
    }
}
