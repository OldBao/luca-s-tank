import SpriteKit

class GameOverScene: SKScene {
    var gameState: GameState!

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit
        SoundManager.shared.playGameOver(on: self)

        let goLabel = SKLabelNode(text: "GAME OVER")
        goLabel.fontName = "Courier-Bold"
        goLabel.fontSize = 14
        goLabel.fontColor = .red
        goLabel.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight / 2 - 20)
        goLabel.horizontalAlignmentMode = .center
        self.addChild(goLabel)

        // Score
        let scoreLabel = SKLabelNode(text: "SCORE: \(gameState.score)")
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 10
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight / 2 + 5)
        scoreLabel.horizontalAlignmentMode = .center
        self.addChild(scoreLabel)

        // High score
        let hiLabel = SKLabelNode(text: "HI-SCORE: \(gameState.highScore)")
        hiLabel.fontName = "Courier-Bold"
        hiLabel.fontSize = 8
        hiLabel.fontColor = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
        hiLabel.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight / 2 + 20)
        hiLabel.horizontalAlignmentMode = .center
        self.addChild(hiLabel)

        let prompt = SKLabelNode(text: "PRESS ENTER")
        prompt.fontName = "Courier"
        prompt.fontSize = 8
        prompt.fontColor = SKColor(white: 0.5, alpha: 1)
        prompt.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight / 2 + 50)
        prompt.horizontalAlignmentMode = .center
        self.addChild(prompt)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { // Enter
            let menu = MenuScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
            self.view?.presentScene(menu, transition: SKTransition.fade(with: .black, duration: 0.5))
        }
    }
}
