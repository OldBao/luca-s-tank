import SpriteKit

enum MeleeAIBehavior {
    case playerControlled
    case aiWander
    case aiHuntNearest
    case aiHuntAndBreak
    case aiHuntWeakest
}

class MeleeTank: Tank {
    let teamIndex: Int
    let teamColor: TeamColor
    let tankType: EnemyType
    let aiBehavior: MeleeAIBehavior
    var isPlayerControlled: Bool

    var isShielded: Bool = false
    var shieldTimer: TimeInterval = 0
    var shieldNode: SKSpriteNode?

    var bulletCount: Int = 0
    var maxBullets: Int { tankType == .armor ? 2 : 1 }

    var currentPath: [(Int, Int)] = []
    var pathRecalcTimer: TimeInterval = 0
    var pathRecalcInterval: TimeInterval = 1.0
    var directionChangeTimer: TimeInterval = 0
    var directionChangeInterval: TimeInterval = 2.0
    var fireTimer: TimeInterval = 0
    var fireInterval: TimeInterval = 1.5
    var collisionCooldown: TimeInterval = 0
    var wantsToFire: Bool = false

    var isFrozen: Bool = false
    var frozenTimer: TimeInterval = 0

    // For world-space positioning (no play area origin offset)
    var meleePlayAreaSize: CGFloat = 0

    init(teamIndex: Int, teamColor: TeamColor, tankType: EnemyType,
         hp: Int, isPlayerControlled: Bool) {
        self.teamIndex = teamIndex
        self.teamColor = teamColor
        self.tankType = tankType
        self.isPlayerControlled = isPlayerControlled

        if isPlayerControlled {
            self.aiBehavior = .playerControlled
        } else {
            switch tankType {
            case .basic: self.aiBehavior = .aiWander
            case .fast:  self.aiBehavior = .aiHuntNearest
            case .power: self.aiBehavior = .aiHuntAndBreak
            case .armor: self.aiBehavior = .aiHuntWeakest
            }
        }

        let tex = SpriteManager.shared.meleeTeamTankTexture(
            type: tankType, direction: .up, frame: 0, teamColor: teamColor
        )
        super.init(texture: tex)
        self.moveSpeed = tankType.speed
        self.hp = hp
        self.direction = .up

        directionChangeInterval = TimeInterval.random(in: 1.5...4.0)
        fireInterval = TimeInterval.random(in: 0.8...2.5)

        switch aiBehavior {
        case .playerControlled: pathRecalcInterval = 0
        case .aiWander:         pathRecalcInterval = 0
        case .aiHuntNearest:    pathRecalcInterval = 0.8
        case .aiHuntAndBreak:   pathRecalcInterval = 1.5
        case .aiHuntWeakest:    pathRecalcInterval = 1.2
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // World-space positioning (no Constants.playAreaOriginX/Y offset)
    override func syncSpritePosition() {
        self.position = CGPoint(x: gridX, y: meleePlayAreaSize - gridY)
    }

    // MARK: - AI Update

    func updateMeleeAI(dt: TimeInterval,
                       enemyTanks: [MeleeTank],
                       teamTankCounts: [Int: Int],
                       grid: [[Tile?]],
                       gridSize: Int) {
        guard !isPlayerControlled, !isFrozen else { return }

        isMoving = true
        wantsToFire = false

        if collisionCooldown > 0 { collisionCooldown -= dt }
        guard collisionCooldown <= 0 else {
            fireTimer += dt
            if fireTimer >= fireInterval {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.5...1.5)
                wantsToFire = true
            }
            return
        }

        switch aiBehavior {
        case .playerControlled: break
        case .aiWander:
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
        case .aiHuntNearest:
            updateHuntNearest(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
        case .aiHuntAndBreak:
            updateHuntAndBreak(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
        case .aiHuntWeakest:
            updateHuntWeakest(dt: dt, enemyTanks: enemyTanks, teamTankCounts: teamTankCounts,
                              grid: grid, gridSize: gridSize)
        }
    }

    private func updateWander(dt: TimeInterval, enemyTanks: [MeleeTank],
                              grid: [[Tile?]], gridSize: Int) {
        directionChangeTimer += dt
        if directionChangeTimer >= directionChangeInterval {
            directionChangeTimer = 0
            directionChangeInterval = TimeInterval.random(in: 1.5...4.0)
            direction = Direction.allCases.randomElement() ?? .down
        }
        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile(gridSize: gridSize)
            for enemy in enemyTanks {
                let enemyTile = tileFromGrid(enemy.gridX, enemy.gridY, gridSize: gridSize)
                if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                              direction: direction,
                                              targetCol: enemyTile.0, targetRow: enemyTile.1,
                                              grid: grid) {
                    fireTimer = 0
                    fireInterval = TimeInterval.random(in: 0.8...2.5)
                    wantsToFire = true
                    break
                }
            }
        }
    }

    private func updateHuntNearest(dt: TimeInterval, enemyTanks: [MeleeTank],
                                   grid: [[Tile?]], gridSize: Int) {
        guard let nearest = findNearestEnemy(enemyTanks) else {
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
            return
        }
        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0
            let myTile = currentTile(gridSize: gridSize)
            let targetTile = tileFromGrid(nearest.gridX, nearest.gridY, gridSize: gridSize)
            currentPath = Pathfinder.findPath(from: myTile, to: targetTile, grid: grid, canBreakBricks: false)
            if currentPath.isEmpty {
                updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
                return
            }
        }
        followPath()
        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile(gridSize: gridSize)
            let targetTile = tileFromGrid(nearest.gridX, nearest.gridY, gridSize: gridSize)
            if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                          direction: direction,
                                          targetCol: targetTile.0, targetRow: targetTile.1,
                                          grid: grid) {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.5...1.5)
                wantsToFire = true
            }
        }
    }

    private func updateHuntAndBreak(dt: TimeInterval, enemyTanks: [MeleeTank],
                                    grid: [[Tile?]], gridSize: Int) {
        guard let nearest = findNearestEnemy(enemyTanks) else {
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
            return
        }
        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0
            let myTile = currentTile(gridSize: gridSize)
            let targetTile = tileFromGrid(nearest.gridX, nearest.gridY, gridSize: gridSize)
            currentPath = Pathfinder.findPath(from: myTile, to: targetTile, grid: grid, canBreakBricks: true)
            if currentPath.isEmpty {
                updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
                return
            }
        }
        followPath()
        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile(gridSize: gridSize)
            if Pathfinder.nextTileIsBrick(fromCol: myTile.0, fromRow: myTile.1, direction: direction, grid: grid) {
                fireTimer = 0; fireInterval = TimeInterval.random(in: 0.4...1.2); wantsToFire = true
            } else {
                let targetTile = tileFromGrid(nearest.gridX, nearest.gridY, gridSize: gridSize)
                if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1, direction: direction,
                                              targetCol: targetTile.0, targetRow: targetTile.1, grid: grid) {
                    fireTimer = 0; fireInterval = TimeInterval.random(in: 0.4...1.2); wantsToFire = true
                }
            }
        }
    }

    private func updateHuntWeakest(dt: TimeInterval, enemyTanks: [MeleeTank],
                                   teamTankCounts: [Int: Int],
                                   grid: [[Tile?]], gridSize: Int) {
        let enemyCounts = teamTankCounts.filter { $0.key != teamIndex && $0.value > 0 }
        guard let weakestTeam = enemyCounts.min(by: { $0.value < $1.value })?.key else {
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
            return
        }
        let weakestTeamTanks = enemyTanks.filter { $0.teamIndex == weakestTeam }
        guard let target = weakestTeamTanks.min(by: { manhattanDist(to: $0) < manhattanDist(to: $1) }) else {
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
            return
        }
        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0
            let myTile = currentTile(gridSize: gridSize)
            let targetTile = tileFromGrid(target.gridX, target.gridY, gridSize: gridSize)
            currentPath = Pathfinder.findPath(from: myTile, to: targetTile, grid: grid, canBreakBricks: true)
            if currentPath.isEmpty {
                updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
                return
            }
        }
        followPath()
        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile(gridSize: gridSize)
            var shouldShoot = false
            if Pathfinder.nextTileIsBrick(fromCol: myTile.0, fromRow: myTile.1, direction: direction, grid: grid) {
                shouldShoot = true
            } else {
                let targetTile = tileFromGrid(target.gridX, target.gridY, gridSize: gridSize)
                if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1, direction: direction,
                                              targetCol: targetTile.0, targetRow: targetTile.1, grid: grid) {
                    shouldShoot = true
                }
            }
            if shouldShoot { fireTimer = 0; fireInterval = TimeInterval.random(in: 0.4...1.2); wantsToFire = true }
        }
    }

    // MARK: - Helpers

    private func followPath() {
        guard let next = currentPath.first else { return }
        let targetX = CGFloat(next.0) * Constants.tileSize + Constants.tileSize / 2
        let targetY = CGFloat(next.1) * Constants.tileSize + Constants.tileSize / 2
        let dx = targetX - gridX
        let dy = targetY - gridY
        if abs(dx) > abs(dy) { direction = dx > 0 ? .right : .left }
        else { direction = dy > 0 ? .down : .up }
        if abs(dx) < 2 && abs(dy) < 2 { currentPath.removeFirst() }
    }

    private func findNearestEnemy(_ enemies: [MeleeTank]) -> MeleeTank? {
        enemies.min(by: { manhattanDist(to: $0) < manhattanDist(to: $1) })
    }

    private func manhattanDist(to other: MeleeTank) -> CGFloat {
        abs(gridX - other.gridX) + abs(gridY - other.gridY)
    }

    func currentTile(gridSize: Int) -> (Int, Int) {
        let col = max(0, min(gridSize - 1, Int(gridX / Constants.tileSize)))
        let row = max(0, min(gridSize - 1, Int(gridY / Constants.tileSize)))
        return (col, row)
    }

    private func tileFromGrid(_ x: CGFloat, _ y: CGFloat, gridSize: Int) -> (Int, Int) {
        let col = max(0, min(gridSize - 1, Int(x / Constants.tileSize)))
        let row = max(0, min(gridSize - 1, Int(y / Constants.tileSize)))
        return (col, row)
    }

    func onCollision(gridSize: Int) {
        directionChangeTimer = 0
        collisionCooldown = 0.3
        let playArea = CGFloat(gridSize) * Constants.tileSize
        let margin = Constants.tileSize / 2 + 2
        let maxCoord = playArea - margin
        var blockedDirs: Set<Direction> = [direction]
        if gridX <= margin { blockedDirs.insert(.left) }
        if gridX >= maxCoord { blockedDirs.insert(.right) }
        if gridY <= margin { blockedDirs.insert(.up) }
        if gridY >= maxCoord { blockedDirs.insert(.down) }
        let viable = Direction.allCases.filter { !blockedDirs.contains($0) }
        direction = viable.randomElement() ?? direction.opposite
        currentPath = []
        pathRecalcTimer = pathRecalcInterval
    }

    func canFire() -> Bool { bulletCount < maxBullets }

    // MARK: - Shield

    func activateShield(duration: TimeInterval = 10.0) {
        isShielded = true
        shieldTimer = duration
        shieldNode?.removeFromParent()
        let shield = SKSpriteNode(texture: SpriteManager.shared.shieldTexture(frame: 0))
        shield.size = CGSize(width: 18, height: 18)
        shield.zPosition = 1
        self.addChild(shield)
        shieldNode = shield
        let anim = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { shield.texture = SpriteManager.shared.shieldTexture(frame: 0) },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { shield.texture = SpriteManager.shared.shieldTexture(frame: 1) },
            SKAction.wait(forDuration: 0.1),
        ]))
        shield.run(anim, withKey: "shieldAnim")
    }

    func updateShield(dt: TimeInterval) {
        if isShielded {
            shieldTimer -= dt
            if shieldTimer <= 0 { isShielded = false; shieldNode?.removeFromParent(); shieldNode = nil }
        }
        if frozenTimer > 0 { frozenTimer -= dt; if frozenTimer <= 0 { isFrozen = false } }
    }

    // MARK: - Texture

    override func updateTexture() {
        self.texture = SpriteManager.shared.meleeTeamTankTexture(
            type: tankType, direction: direction, frame: animFrame,
            teamColor: teamColor, armorHP: hp
        )
    }

    override func takeDamage() -> Bool {
        hp -= 1
        updateTexture()
        return hp <= 0
    }
}
