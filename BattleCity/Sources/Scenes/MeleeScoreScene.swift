import SpriteKit

class MeleeScoreScene: SKScene {
    var matchResult: MeleeMatchResult!
    var meleeConfig: MeleeConfig!

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit

        let orange = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
        let centerX = Constants.logicalWidth / 2

        // Title
        let title = SKLabelNode(text: "BATTLE RESULTS")
        title.fontName = "Courier-Bold"
        title.fontSize = 12
        title.fontColor = orange
        title.position = CGPoint(x: centerX, y: 24)
        title.horizontalAlignmentMode = .center
        self.addChild(title)

        // Winner
        let winnerColor = matchResult.teamStats[matchResult.winnerTeamIndex].teamColor
        let winLabel = SKLabelNode(text: "\(winnerColor.name) WINS!")
        winLabel.fontName = "Courier-Bold"
        winLabel.fontSize = 10
        winLabel.fontColor = colorForTeam(winnerColor)
        winLabel.position = CGPoint(x: centerX, y: 44)
        winLabel.horizontalAlignmentMode = .center
        self.addChild(winLabel)

        // Column headers
        let headerY: CGFloat = 64
        let headers = ["TEAM", "KILLS", "DEATHS", "ALIVE"]
        let colX: [CGFloat] = [40, 110, 155, 210]

        for (i, header) in headers.enumerated() {
            let label = SKLabelNode(text: header)
            label.fontName = "Courier-Bold"
            label.fontSize = 6
            label.fontColor = SKColor(white: 0.6, alpha: 1)
            label.position = CGPoint(x: colX[i], y: headerY)
            label.horizontalAlignmentMode = .left
            self.addChild(label)
        }

        // Team rows
        for (i, stats) in matchResult.teamStats.enumerated() {
            let rowY = headerY + 16 + CGFloat(i) * 16

            let nameLabel = SKLabelNode(text: stats.teamColor.name)
            nameLabel.fontName = "Courier-Bold"
            nameLabel.fontSize = 6
            nameLabel.fontColor = colorForTeam(stats.teamColor)
            nameLabel.position = CGPoint(x: colX[0], y: rowY)
            nameLabel.horizontalAlignmentMode = .left
            self.addChild(nameLabel)

            let killsLabel = SKLabelNode(text: "\(stats.kills)")
            killsLabel.fontName = "Courier"
            killsLabel.fontSize = 6
            killsLabel.fontColor = .white
            killsLabel.position = CGPoint(x: colX[1], y: rowY)
            killsLabel.horizontalAlignmentMode = .left
            self.addChild(killsLabel)

            let deathsLabel = SKLabelNode(text: "\(stats.deaths)")
            deathsLabel.fontName = "Courier"
            deathsLabel.fontSize = 6
            deathsLabel.fontColor = .white
            deathsLabel.position = CGPoint(x: colX[2], y: rowY)
            deathsLabel.horizontalAlignmentMode = .left
            self.addChild(deathsLabel)

            let aliveLabel = SKLabelNode(text: "\(stats.survived)/\(stats.total)")
            aliveLabel.fontName = "Courier"
            aliveLabel.fontSize = 6
            aliveLabel.fontColor = .white
            aliveLabel.position = CGPoint(x: colX[3], y: rowY)
            aliveLabel.horizontalAlignmentMode = .left
            self.addChild(aliveLabel)
        }

        // Player kills
        let playerY: CGFloat = headerY + 16 + CGFloat(matchResult.teamStats.count) * 16 + 10
        let playerLabel = SKLabelNode(text: "YOUR KILLS: \(matchResult.playerKills)")
        playerLabel.fontName = "Courier-Bold"
        playerLabel.fontSize = 7
        playerLabel.fontColor = .white
        playerLabel.position = CGPoint(x: centerX, y: playerY)
        playerLabel.horizontalAlignmentMode = .center
        self.addChild(playerLabel)

        // Prompt
        let promptY: CGFloat = 195
        let prompt = SKLabelNode(text: "PRESS ENTER TO CONTINUE")
        prompt.fontName = "Courier"
        prompt.fontSize = 6
        prompt.fontColor = SKColor(white: 0.5, alpha: 1)
        prompt.position = CGPoint(x: centerX, y: promptY)
        prompt.horizontalAlignmentMode = .center
        self.addChild(prompt)

        // Blink the prompt
        prompt.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            ])
        ))
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 53: // Enter or Escape
            let scene = MeleeMenuScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
            scene.meleeConfig = meleeConfig
            self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
        default:
            break
        }
    }

    private func colorForTeam(_ color: TeamColor) -> SKColor {
        switch color {
        case .yellow: return SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
        case .red:    return SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1)
        case .blue:   return SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1)
        case .green:  return SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1)
        }
    }
}
