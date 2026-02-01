import SpriteKit

class MeleeLevelManager {
    var tiles: [[Tile?]] = []
    var gridSize: Int = 20
    weak var scene: SKScene?

    var playAreaSize: CGFloat { CGFloat(gridSize) * Constants.tileSize }

    func loadMap(_ mapData: [[TileType]], into scene: SKScene, parentNode: SKNode) {
        self.scene = scene
        self.gridSize = mapData.count
        clearLevel()

        tiles = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let tileType = mapData[row][col]
                guard tileType != .empty else { continue }

                let tile = Tile(type: tileType, tileX: col, tileY: row)
                // Override position to world-space (no play area origin offset)
                tile.position = CGPoint(
                    x: CGFloat(col) * Constants.tileSize + Constants.tileSize / 2,
                    y: playAreaSize - (CGFloat(row) * Constants.tileSize + Constants.tileSize / 2)
                )
                tiles[row][col] = tile
                parentNode.addChild(tile)
            }
        }
    }

    func clearLevel() {
        for row in tiles { for tile in row { tile?.removeFromParent() } }
        tiles = []
    }

    func tileAt(col: Int, row: Int) -> Tile? {
        guard row >= 0, row < gridSize, col >= 0, col < gridSize else { return nil }
        return tiles[row][col]
    }

    func removeTile(col: Int, row: Int) {
        guard row >= 0, row < gridSize, col >= 0, col < gridSize else { return }
        tiles[row][col]?.removeFromParent()
        tiles[row][col] = nil
    }

    func canMoveTo(x: CGFloat, y: CGFloat, size: CGFloat) -> Bool {
        let halfSize = size / 2 - 1
        let minX = x - halfSize; let maxX = x + halfSize
        let minY = y - halfSize; let maxY = y + halfSize

        if minX < 0 || maxX > playAreaSize || minY < 0 || maxY > playAreaSize { return false }

        let startCol = max(0, Int(minX / Constants.tileSize))
        let endCol = min(gridSize - 1, Int(maxX / Constants.tileSize))
        let startRow = max(0, Int(minY / Constants.tileSize))
        let endRow = min(gridSize - 1, Int(maxY / Constants.tileSize))

        for row in startRow...endRow {
            for col in startCol...endCol {
                if let tile = tiles[row][col] {
                    switch tile.tileType {
                    case .brick, .steel, .water:
                        let tileMinX = CGFloat(col) * Constants.tileSize
                        let tileMaxX = tileMinX + Constants.tileSize
                        let tileMinY = CGFloat(row) * Constants.tileSize
                        let tileMaxY = tileMinY + Constants.tileSize
                        if maxX > tileMinX && minX < tileMaxX && maxY > tileMinY && minY < tileMaxY {
                            return false
                        }
                    default: break
                    }
                }
            }
        }
        return true
    }
}
