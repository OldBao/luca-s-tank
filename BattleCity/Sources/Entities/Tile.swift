import SpriteKit

class Tile: SKSpriteNode {
    let tileType: TileType
    let tileX: Int
    let tileY: Int

    // For brick tiles: 4 sub-bricks (2x2), each can be independently destroyed
    // [topLeft, topRight, bottomLeft, bottomRight]
    var subBricks: [Bool] = [true, true, true, true]

    // Water animation
    var waterFrame: Int = 0

    init(type: TileType, tileX: Int, tileY: Int) {
        self.tileType = type
        self.tileX = tileX
        self.tileY = tileY

        let tex = SpriteManager.shared.tileTexture(type: type, variant: 0)
        super.init(texture: tex, color: .clear, size: CGSize(width: Constants.tileSize, height: Constants.tileSize))
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.name = "tile_\(tileX)_\(tileY)"

        let px = Constants.playAreaOriginX + CGFloat(tileX) * Constants.tileSize + Constants.tileSize / 2
        // Flip Y: row 0 = top of play area = high SpriteKit Y
        let py = Constants.playAreaOriginY + Constants.playAreaSize - (CGFloat(tileY) * Constants.tileSize + Constants.tileSize / 2)
        self.position = CGPoint(x: px, y: py)

        switch type {
        case .brick:
            self.zPosition = 5
        case .steel:
            self.zPosition = 5
        case .water:
            self.zPosition = 2
            startWaterAnimation()
        case .trees:
            self.zPosition = 15  // drawn above tanks
        case .ice:
            self.zPosition = 1
        case .empty:
            break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func startWaterAnimation() {
        let anim = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.waterFrame = (self.waterFrame + 1) % 2
                self.texture = SpriteManager.shared.tileTexture(type: .water, variant: self.waterFrame)
            }
        ]))
        self.run(anim, withKey: "waterAnim")
    }

    /// Hit brick tile from a given direction. Returns true if entire tile destroyed.
    func hitBrick(from direction: Direction) -> Bool {
        guard tileType == .brick else { return false }

        // Destroy the 2 sub-bricks on the near side; if already gone, destroy far side
        switch direction {
        case .up:
            // Bullet traveling up hits bottom first, then top
            if subBricks[2] || subBricks[3] {
                subBricks[2] = false  // bottomLeft
                subBricks[3] = false  // bottomRight
            } else {
                subBricks[0] = false  // topLeft
                subBricks[1] = false  // topRight
            }
        case .down:
            // Bullet traveling down hits top first, then bottom
            if subBricks[0] || subBricks[1] {
                subBricks[0] = false  // topLeft
                subBricks[1] = false  // topRight
            } else {
                subBricks[2] = false  // bottomLeft
                subBricks[3] = false  // bottomRight
            }
        case .left:
            // Bullet traveling left hits right side first, then left
            if subBricks[1] || subBricks[3] {
                subBricks[1] = false  // topRight
                subBricks[3] = false  // bottomRight
            } else {
                subBricks[0] = false  // topLeft
                subBricks[2] = false  // bottomLeft
            }
        case .right:
            // Bullet traveling right hits left side first, then right
            if subBricks[0] || subBricks[2] {
                subBricks[0] = false  // topLeft
                subBricks[2] = false  // bottomLeft
            } else {
                subBricks[1] = false  // topRight
                subBricks[3] = false  // bottomRight
            }
        }

        updateBrickTexture()

        // Check if all sub-bricks destroyed
        return !subBricks.contains(true)
    }

    private func updateBrickTexture() {
        // Encode sub-brick state as variant
        var variant = 0
        for (i, alive) in subBricks.enumerated() {
            if alive { variant |= (1 << i) }
        }
        self.texture = SpriteManager.shared.tileTexture(type: .brick, variant: variant)
    }

    /// Convert this tile to steel (shovel power-up) or back to brick
    func convertToSteel() {
        self.texture = SpriteManager.shared.tileTexture(type: .steel, variant: 0)
    }

    func convertToBrick() {
        subBricks = [true, true, true, true]
        self.texture = SpriteManager.shared.tileTexture(type: .brick, variant: 0)
    }
}
