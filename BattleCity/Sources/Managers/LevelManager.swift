import SpriteKit

class LevelManager {
    var tiles: [[Tile?]] = []
    var eagle: Eagle?
    weak var scene: SKScene?

    // Eagle protection tiles (for shovel power-up)
    var eagleProtectionTiles: [Tile] = []

    func loadLevel(_ levelNumber: Int, into scene: SKScene) {
        self.scene = scene
        clearLevel()

        let levelIndex = (levelNumber - 1) % LevelData.levels.count
        let data = LevelData.levels[levelIndex]

        tiles = Array(repeating: Array(repeating: nil, count: Constants.playAreaTiles), count: Constants.playAreaTiles)

        for row in 0..<Constants.playAreaTiles {
            for col in 0..<Constants.playAreaTiles {
                let tileValue = data[row][col]
                guard let tileType = TileType(rawValue: tileValue), tileType != .empty else { continue }

                // Skip eagle position
                if row == 12 && col == 6 { continue }

                let tile = Tile(type: tileType, tileX: col, tileY: row)
                tiles[row][col] = tile
                scene.addChild(tile)

                // Track eagle protection tiles
                if isEagleProtectionTile(row: row, col: col) {
                    eagleProtectionTiles.append(tile)
                }
            }
        }

        // Place eagle
        let eagleNode = Eagle()
        eagleNode.setTilePosition(tileX: 6, tileY: 12)
        scene.addChild(eagleNode)
        eagle = eagleNode
    }

    func clearLevel() {
        for row in tiles {
            for tile in row {
                tile?.removeFromParent()
            }
        }
        tiles = []
        eagle?.removeFromParent()
        eagle = nil
        eagleProtectionTiles = []
    }

    func tileAt(col: Int, row: Int) -> Tile? {
        guard row >= 0, row < Constants.playAreaTiles, col >= 0, col < Constants.playAreaTiles else { return nil }
        return tiles[row][col]
    }

    func removeTile(col: Int, row: Int) {
        tiles[row][col]?.removeFromParent()
        tiles[row][col] = nil
    }

    func isEagleProtectionTile(row: Int, col: Int) -> Bool {
        // Tiles surrounding the eagle at (12, 6)
        let protectionCoords: [(Int, Int)] = [
            (10, 5), (10, 6), (10, 7),
            (11, 5), (11, 7),
            (12, 5), (12, 7)
        ]
        return protectionCoords.contains { $0.0 == row && $0.1 == col }
    }

    func activateShovel() {
        for tile in eagleProtectionTiles {
            tile.convertToSteel()
        }
    }

    func deactivateShovel() {
        for tile in eagleProtectionTiles {
            tile.convertToBrick()
        }
    }

    /// Check if a tank can move to a given position
    func canMoveTo(x: CGFloat, y: CGFloat, size: CGFloat, excludeTile: Tile? = nil) -> Bool {
        let halfSize = size / 2 - 1  // slight tolerance
        let minX = x - halfSize
        let maxX = x + halfSize
        let minY = y - halfSize
        let maxY = y + halfSize

        // Check play area bounds
        if minX < 0 || maxX > Constants.playAreaSize || minY < 0 || maxY > Constants.playAreaSize {
            return false
        }

        // Check tile collisions
        let startCol = max(0, Int(minX / Constants.tileSize))
        let endCol = min(Constants.playAreaTiles - 1, Int(maxX / Constants.tileSize))
        let startRow = max(0, Int(minY / Constants.tileSize))
        let endRow = min(Constants.playAreaTiles - 1, Int(maxY / Constants.tileSize))

        for row in startRow...endRow {
            for col in startCol...endCol {
                if let tile = tiles[row][col], tile !== excludeTile {
                    switch tile.tileType {
                    case .brick, .steel, .water:
                        // Check actual overlap
                        let tileMinX = CGFloat(col) * Constants.tileSize
                        let tileMaxX = tileMinX + Constants.tileSize
                        let tileMinY = CGFloat(row) * Constants.tileSize
                        let tileMaxY = tileMinY + Constants.tileSize

                        if maxX > tileMinX && minX < tileMaxX && maxY > tileMinY && minY < tileMaxY {
                            return false
                        }
                    default:
                        break
                    }
                }
            }
        }

        // Check eagle collision
        if eagle != nil {
            let eagleX = CGFloat(6) * Constants.tileSize + Constants.tileSize / 2
            let eagleY = CGFloat(12) * Constants.tileSize + Constants.tileSize / 2  // grid coords
            let eHalf = Constants.tileSize / 2
            if maxX > eagleX - eHalf && minX < eagleX + eHalf && maxY > eagleY - eHalf && minY < eagleY + eHalf {
                return false
            }
        }

        return true
    }

    /// Get tile at pixel position within play area
    func tileAtPixel(x: CGFloat, y: CGFloat) -> Tile? {
        let col = Int(x / Constants.tileSize)
        let row = Int(y / Constants.tileSize)
        return tileAt(col: col, row: row)
    }

    /// Check if position is on ice
    func isOnIce(x: CGFloat, y: CGFloat) -> Bool {
        let col = Int(x / Constants.tileSize)
        let row = Int(y / Constants.tileSize)
        if let tile = tileAt(col: col, row: row), tile.tileType == .ice {
            return true
        }
        return false
    }
}
