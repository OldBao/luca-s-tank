import SpriteKit

class GameHUD: SKNode {
    private var enemyIcons: [SKSpriteNode] = []
    private var livesLabel: SKLabelNode!
    private var livesIcon: SKSpriteNode!
    private var levelLabel: SKLabelNode!
    private var levelFlag: SKSpriteNode!

    let hudX: CGFloat = Constants.playAreaOriginX + Constants.playAreaSize + 8

    func setup() {
        self.zPosition = 50

        let topY = Constants.playAreaOriginY + Constants.playAreaSize
        let bottomY = Constants.playAreaOriginY

        // Enemy indicators (right side, from top going down) - 2 columns of 10
        for i in 0..<20 {
            let icon = SKSpriteNode(texture: SpriteManager.shared.hudEnemyIcon())
            icon.size = CGSize(width: 8, height: 8)
            let col = i % 2
            let row = i / 2
            icon.position = CGPoint(
                x: hudX + CGFloat(col) * 10,
                y: topY - 4 - CGFloat(row) * 10
            )
            icon.anchorPoint = CGPoint(x: 0, y: 1)
            self.addChild(icon)
            enemyIcons.append(icon)
        }

        // Lives display (right side, below enemy icons)
        let livesY = bottomY + 40

        livesIcon = SKSpriteNode(texture: SpriteManager.shared.hudLifeIcon())
        livesIcon.size = CGSize(width: 8, height: 8)
        livesIcon.position = CGPoint(x: hudX, y: livesY)
        livesIcon.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(livesIcon)

        livesLabel = createLabel(text: "3", position: CGPoint(x: hudX + 10, y: livesY))
        self.addChild(livesLabel)

        // Level indicator (right side, bottom)
        levelFlag = SKSpriteNode(texture: SpriteManager.shared.hudFlagIcon())
        levelFlag.size = CGSize(width: 16, height: 16)
        levelFlag.position = CGPoint(x: hudX, y: bottomY + 8)
        levelFlag.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(levelFlag)

        levelLabel = createLabel(text: "1", position: CGPoint(x: hudX + 4, y: bottomY + 2))
        self.addChild(levelLabel)
    }

    private func createLabel(text: String, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Courier-Bold"
        label.fontSize = 8
        label.fontColor = .black
        label.position = position
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .bottom
        return label
    }

    func updateEnemyCount(_ remaining: Int) {
        for (i, icon) in enemyIcons.enumerated() {
            icon.isHidden = i >= remaining
        }
    }

    func updateLives(_ lives: Int) {
        livesLabel.text = "\(max(0, lives))"
    }

    func updateLevel(_ level: Int) {
        levelLabel.text = "\(level)"
    }
}
