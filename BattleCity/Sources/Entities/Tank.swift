import SpriteKit

class Tank: SKSpriteNode {
    var direction: Direction = .up
    var moveSpeed: CGFloat = 0
    var hp: Int = 1
    var isMoving: Bool = false
    var animFrame: Int = 0
    private var animTimer: TimeInterval = 0
    private let animInterval: TimeInterval = 0.1

    // Grid-aligned position (pixel coords within play area)
    var gridX: CGFloat = 0
    var gridY: CGFloat = 0

    init(texture: SKTexture) {
        super.init(texture: texture, color: .clear, size: CGSize(width: Constants.tileSize, height: Constants.tileSize))
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.zPosition = 10
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setGridPosition(tileX: Int, tileY: Int) {
        gridX = CGFloat(tileX) * Constants.tileSize + Constants.tileSize / 2
        gridY = CGFloat(tileY) * Constants.tileSize + Constants.tileSize / 2
        syncSpritePosition()
    }

    func syncSpritePosition() {
        // gridY is in NES coords (Y-down), convert to SpriteKit (Y-up)
        self.position = CGPoint(
            x: Constants.playAreaOriginX + gridX,
            y: Constants.playAreaOriginY + Constants.playAreaSize - gridY
        )
    }

    func snapToGrid() {
        let snap = Constants.snapSize
        gridX = (gridX / snap).rounded() * snap
        gridY = (gridY / snap).rounded() * snap
    }

    /// Snap the axis perpendicular to movement direction
    func snapPerpendicularAxis() {
        let snap = Constants.snapSize
        if direction.isHorizontal {
            gridY = (gridY / snap).rounded() * snap
        } else {
            gridX = (gridX / snap).rounded() * snap
        }
    }

    func updateAnimation(dt: TimeInterval) {
        guard isMoving else { return }
        animTimer += dt
        if animTimer >= animInterval {
            animTimer = 0
            animFrame = (animFrame + 1) % 2
            updateTexture()
        }
    }

    func updateTexture() {
        // Override in subclasses
    }

    func moveStep(dt: TimeInterval) -> CGPoint {
        let dx = direction.vector.dx * moveSpeed * CGFloat(dt)
        let dy = direction.vector.dy * moveSpeed * CGFloat(dt)
        return CGPoint(x: gridX + dx, y: gridY + dy)
    }

    func applyMove(newX: CGFloat, newY: CGFloat) {
        gridX = newX
        gridY = newY
        syncSpritePosition()
    }

    func takeDamage() -> Bool {
        hp -= 1
        return hp <= 0
    }
}
