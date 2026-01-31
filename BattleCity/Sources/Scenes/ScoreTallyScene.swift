import SpriteKit

class ScoreTallyScene: SKScene {
    var gameState: GameState!
    var nextLevel: Int = 2

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit

        var y: CGFloat = 40

        let hiScore = SKLabelNode(text: "HI-SCORE  \(gameState.highScore)")
        hiScore.fontName = "Courier-Bold"
        hiScore.fontSize = 8
        hiScore.fontColor = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
        hiScore.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        hiScore.horizontalAlignmentMode = .center
        self.addChild(hiScore)

        y += 16

        let stageLabel = SKLabelNode(text: "STAGE \(gameState.currentLevel)")
        stageLabel.fontName = "Courier-Bold"
        stageLabel.fontSize = 10
        stageLabel.fontColor = .white
        stageLabel.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        stageLabel.horizontalAlignmentMode = .center
        self.addChild(stageLabel)

        y += 20

        let types: [(EnemyType, String)] = [
            (.basic, "BASIC"),
            (.fast, "FAST"),
            (.power, "POWER"),
            (.armor, "ARMOR")
        ]

        var totalKills = 0
        var totalPoints = 0

        for (type, name) in types {
            let kills = gameState.killsByType[type] ?? 0
            let pts = kills * type.score
            totalKills += kills
            totalPoints += pts

            let line = SKLabelNode(text: String(format: "%4d PTS  %2d  %@", pts, kills, name))
            line.fontName = "Courier"
            line.fontSize = 8
            line.fontColor = .white
            line.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
            line.horizontalAlignmentMode = .center
            self.addChild(line)
            y += 14
        }

        y += 4
        let totalLine = SKLabelNode(text: "TOTAL  \(totalKills) KILLS")
        totalLine.fontName = "Courier-Bold"
        totalLine.fontSize = 8
        totalLine.fontColor = .white
        totalLine.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        totalLine.horizontalAlignmentMode = .center
        self.addChild(totalLine)

        // Transition to next level
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.run { [weak self] in
                self?.goToNextLevel()
            }
        ]))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 {
            goToNextLevel()
        }
    }

    func goToNextLevel() {
        let stageScene = StageIntroScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
        stageScene.stageNumber = nextLevel
        stageScene.gameState = gameState
        self.view?.presentScene(stageScene, transition: SKTransition.fade(with: .black, duration: 0.3))
    }
}
