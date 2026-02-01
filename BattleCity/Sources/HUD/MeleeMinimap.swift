import SpriteKit

class MeleeMinimap: SKNode {
    private var minimapSize: CGFloat = 48
    private var dotNodes: [SKSpriteNode] = []
    private var gridSize: Int = 20

    func setup(mapData: [[TileType]], gridSize: Int) {
        self.gridSize = gridSize
        self.zPosition = 200

        // Background
        let bg = SKSpriteNode(color: SKColor(white: 0.1, alpha: 0.8),
                              size: CGSize(width: minimapSize + 4, height: minimapSize + 4))
        bg.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(bg)

        // Draw terrain pixels
        let scale = minimapSize / CGFloat(gridSize)
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let type = mapData[row][col]
                guard type != .empty else { continue }
                let color: SKColor
                switch type {
                case .brick:  color = SKColor(red: 0.6, green: 0.3, blue: 0.0, alpha: 1)
                case .steel:  color = SKColor(white: 0.7, alpha: 1)
                case .water:  color = SKColor(red: 0.0, green: 0.2, blue: 1.0, alpha: 1)
                case .trees:  color = SKColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1)
                case .ice:    color = SKColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1)
                default:      continue
                }
                let dot = SKSpriteNode(color: color, size: CGSize(width: max(1, scale), height: max(1, scale)))
                dot.anchorPoint = CGPoint(x: 0, y: 0)
                dot.position = CGPoint(x: 2 + CGFloat(col) * scale,
                                       y: 2 + minimapSize - CGFloat(row + 1) * scale)
                self.addChild(dot)
            }
        }
    }

    func updateTanks(_ tanks: [MeleeTank]) {
        for dot in dotNodes { dot.removeFromParent() }
        dotNodes.removeAll()

        let scale = minimapSize / CGFloat(gridSize)
        let tileSize = Constants.tileSize

        for tank in tanks {
            let color: SKColor
            switch tank.teamColor {
            case .yellow: color = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
            case .red:    color = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1)
            case .blue:   color = SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1)
            case .green:  color = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1)
            }
            let dotSize = max(2, scale * 1.5)
            let dot = SKSpriteNode(color: color, size: CGSize(width: dotSize, height: dotSize))
            dot.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            let mx = 2 + (tank.gridX / tileSize) * scale
            let my = 2 + minimapSize - (tank.gridY / tileSize) * scale
            dot.position = CGPoint(x: mx, y: my)
            dot.zPosition = 1
            self.addChild(dot)
            dotNodes.append(dot)
        }
    }
}
