import SpriteKit

class MeleeHUD: SKNode {
    private var teamLabels: [SKLabelNode] = []
    private var teamBars: [SKSpriteNode] = []
    private var teamCountLabels: [SKLabelNode] = []

    var teamColors: [TeamColor] = []
    var teamTotals: [Int] = []

    func setup(config: MeleeConfig) {
        self.zPosition = 200
        teamColors = config.teams.map { $0.color }
        teamTotals = config.teams.map { $0.totalTanks }

        for i in 0..<4 {
            let color = skColor(for: teamColors[i])

            let label = SKLabelNode(text: teamColors[i].name)
            label.fontName = "Courier-Bold"
            label.fontSize = 6
            label.fontColor = color
            label.position = CGPoint(x: 8, y: CGFloat(8 + i * 10))
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            self.addChild(label)
            teamLabels.append(label)

            let bar = SKSpriteNode(color: color, size: CGSize(width: 40, height: 5))
            bar.anchorPoint = CGPoint(x: 0, y: 0.5)
            bar.position = CGPoint(x: 45, y: CGFloat(8 + i * 10))
            self.addChild(bar)
            teamBars.append(bar)

            let countLabel = SKLabelNode(text: "\(teamTotals[i])/\(teamTotals[i])")
            countLabel.fontName = "Courier"
            countLabel.fontSize = 5
            countLabel.fontColor = .white
            countLabel.position = CGPoint(x: 90, y: CGFloat(8 + i * 10))
            countLabel.horizontalAlignmentMode = .left
            countLabel.verticalAlignmentMode = .center
            self.addChild(countLabel)
            teamCountLabels.append(countLabel)
        }
    }

    func update(surviving: [Int]) {
        for i in 0..<4 {
            let alive = surviving[i]
            let total = max(teamTotals[i], 1)
            let ratio = CGFloat(alive) / CGFloat(total)
            teamBars[i].xScale = ratio
            teamCountLabels[i].text = "\(alive)/\(teamTotals[i])"
            if alive == 0 {
                teamLabels[i].alpha = 0.3
                teamBars[i].alpha = 0.3
                teamCountLabels[i].alpha = 0.3
            }
        }
    }

    private func skColor(for color: TeamColor) -> SKColor {
        switch color {
        case .yellow: return SKColor(red: 252/255, green: 200/255, blue: 56/255, alpha: 1)
        case .red:    return SKColor(red: 252/255, green: 56/255, blue: 56/255, alpha: 1)
        case .blue:   return SKColor(red: 56/255, green: 100/255, blue: 252/255, alpha: 1)
        case .green:  return SKColor(red: 56/255, green: 200/255, blue: 56/255, alpha: 1)
        }
    }
}
