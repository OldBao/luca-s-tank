import SpriteKit

class StageIntroScene: SKScene {
    var stageNumber: Int = 1
    var gameState: GameState!

    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        self.scaleMode = .aspectFit
        SoundManager.shared.playLevelStart(on: self)

        let label = SKLabelNode(text: "STAGE \(stageNumber)")
        label.fontName = "Courier-Bold"
        label.fontSize = 12
        label.fontColor = .black
        label.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight / 2)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        self.addChild(label)

        // Transition to game after delay
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: Constants.stageIntroDuration),
            SKAction.run { [weak self] in
                self?.startLevel()
            }
        ]))
    }

    func startLevel() {
        let gameScene = GameScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
        gameScene.gameState = gameState
        gameScene.currentLevel = stageNumber
        self.view?.presentScene(gameScene, transition: SKTransition.fade(with: .black, duration: 0.3))
    }
}
