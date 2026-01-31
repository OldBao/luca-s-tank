import SpriteKit

enum AIBehavior {
    case wander       // Basic: random movement, random firing
    case huntPlayer   // Fast: pathfind to player, LOS firing
    case huntEagle    // Power: pathfind to eagle, brick clearing + LOS
    case smartHunter  // Armor: pathfind to closer target, full tactical
}

class EnemyTank: Tank {
    let enemyType: EnemyType
    var isFlashing: Bool  // drops power-up when destroyed
    var isFrozen: Bool = false
    let aiBehavior: AIBehavior

    // AI state — wander (Basic)
    var directionChangeTimer: TimeInterval = 0
    var directionChangeInterval: TimeInterval = 2.0
    var fireTimer: TimeInterval = 0
    var fireInterval: TimeInterval = 1.5

    // AI state — pathfinding (Fast/Power/Armor)
    var currentPath: [(Int, Int)] = []
    var pathRecalcTimer: TimeInterval = 0
    var pathRecalcInterval: TimeInterval = 1.0

    // Flashing animation
    var flashAnimTimer: TimeInterval = 0
    var showFlashColor: Bool = false

    // Collision cooldown: prevents AI from overriding direction right after hitting a wall
    var collisionCooldown: TimeInterval = 0

    // Firing decision (set by AI, read by GameScene)
    var wantsToFire: Bool = false

    init(type: EnemyType, flashing: Bool = false) {
        self.enemyType = type
        self.isFlashing = flashing

        switch type {
        case .basic:
            self.aiBehavior = .wander
        case .fast:
            self.aiBehavior = .huntPlayer
        case .power:
            self.aiBehavior = .huntEagle
        case .armor:
            self.aiBehavior = .smartHunter
        }

        let tex = SpriteManager.shared.enemyTankTexture(type: type, direction: .down, frame: 0, isFlashing: flashing, armorHP: type.maxHP)
        super.init(texture: tex)
        self.direction = .down
        self.moveSpeed = type.speed
        self.hp = type.maxHP

        directionChangeInterval = TimeInterval.random(in: 1.5...4.0)
        fireInterval = TimeInterval.random(in: 0.8...2.5)

        switch aiBehavior {
        case .wander:      pathRecalcInterval = 0 // unused
        case .huntPlayer:  pathRecalcInterval = 0.8
        case .huntEagle:   pathRecalcInterval = 1.5
        case .smartHunter: pathRecalcInterval = 1.2
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Main AI Update

    func updateAI(dt: TimeInterval, playerPosition: CGPoint?, grid: [[Tile?]], bullets: [Bullet]) {
        guard !isFrozen else { return }

        isMoving = true
        wantsToFire = false

        // Tick down collision cooldown
        if collisionCooldown > 0 {
            collisionCooldown -= dt
        }

        // Flashing animation for power-up enemies
        if isFlashing {
            flashAnimTimer += dt
            if flashAnimTimer >= 0.15 {
                flashAnimTimer = 0
                showFlashColor.toggle()
            }
        }

        // During collision cooldown, keep current direction (don't let AI override it)
        guard collisionCooldown <= 0 else {
            // Still update fire timers
            fireTimer += dt
            if fireTimer >= fireInterval {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.5...1.5)
                wantsToFire = true
            }
            return
        }

        switch aiBehavior {
        case .wander:
            updateWander(dt: dt)
        case .huntPlayer:
            updateHuntPlayer(dt: dt, playerPosition: playerPosition, grid: grid)
        case .huntEagle:
            updateHuntEagle(dt: dt, grid: grid)
        case .smartHunter:
            updateSmartHunter(dt: dt, playerPosition: playerPosition, grid: grid)
        }
    }

    // MARK: - Wander (Basic)

    private func updateWander(dt: TimeInterval) {
        directionChangeTimer += dt
        if directionChangeTimer >= directionChangeInterval {
            directionChangeTimer = 0
            directionChangeInterval = TimeInterval.random(in: 1.5...4.0)
            pickRandomDirection()
        }

        fireTimer += dt
        if fireTimer >= fireInterval {
            fireTimer = 0
            fireInterval = TimeInterval.random(in: 0.8...2.5)
            wantsToFire = true
        }
    }

    private func pickRandomDirection() {
        if Double.random(in: 0...1) < 0.5 {
            direction = .down
        } else {
            direction = Direction.allCases.randomElement() ?? .down
        }
    }

    // MARK: - Hunt Player (Fast)

    private func updateHuntPlayer(dt: TimeInterval, playerPosition: CGPoint?, grid: [[Tile?]]) {
        guard let playerPos = playerPosition else {
            updateWander(dt: dt)
            return
        }

        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0
            let myTile = currentTile()
            let playerTile = positionToTile(playerPos)
            currentPath = Pathfinder.findPath(from: myTile, to: playerTile, grid: grid, canBreakBricks: false)

            // No path? Fall back to wander
            if currentPath.isEmpty {
                updateWander(dt: dt)
                return
            }
        }

        followPath()

        // Tactical firing: shoot if player is in LOS
        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile()
            let playerTile = positionToTile(playerPos)
            if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                         direction: direction,
                                         targetCol: playerTile.0, targetRow: playerTile.1,
                                         grid: grid) {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.5...1.5)
                wantsToFire = true
            }
        }
    }

    // MARK: - Hunt Eagle (Power)

    private func updateHuntEagle(dt: TimeInterval, grid: [[Tile?]]) {
        let eagleTile = (6, 12) // eagle is always at tile (6, 12)

        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0
            let myTile = currentTile()
            currentPath = Pathfinder.findPath(from: myTile, to: eagleTile, grid: grid, canBreakBricks: true)

            if currentPath.isEmpty {
                updateWander(dt: dt)
                return
            }
        }

        followPath()

        // Tactical firing: clear bricks in path or shoot eagle on LOS
        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile()

            // Check if next tile in path is a brick we're facing
            if Pathfinder.nextTileIsBrick(fromCol: myTile.0, fromRow: myTile.1,
                                          direction: direction, grid: grid) {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.4...1.2)
                wantsToFire = true
            }
            // Also fire if eagle in LOS
            else if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                              direction: direction,
                                              targetCol: eagleTile.0, targetRow: eagleTile.1,
                                              grid: grid) {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.4...1.2)
                wantsToFire = true
            }
        }
    }

    // MARK: - Smart Hunter (Armor)

    private func updateSmartHunter(dt: TimeInterval, playerPosition: CGPoint?, grid: [[Tile?]]) {
        let eagleTile = (6, 12)
        let myTile = currentTile()

        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0

            // Pick closer target
            let eagleGridX = CGFloat(eagleTile.0) * Constants.tileSize + Constants.tileSize / 2
            let eagleGridY = CGFloat(eagleTile.1) * Constants.tileSize + Constants.tileSize / 2
            let distToEagle = abs(gridX - eagleGridX) + abs(gridY - eagleGridY)

            var targetTile = eagleTile
            if let playerPos = playerPosition {
                let playerT = positionToTile(playerPos)
                let playerGridX = CGFloat(playerT.0) * Constants.tileSize + Constants.tileSize / 2
                let playerGridY = CGFloat(playerT.1) * Constants.tileSize + Constants.tileSize / 2
                let distToPlayer = abs(gridX - playerGridX) + abs(gridY - playerGridY)
                if distToPlayer < distToEagle {
                    targetTile = playerT
                }
            }

            currentPath = Pathfinder.findPath(from: myTile, to: targetTile, grid: grid, canBreakBricks: true)

            if currentPath.isEmpty {
                updateWander(dt: dt)
                return
            }
        }

        followPath()

        // Full tactical firing
        fireTimer += dt
        if fireTimer >= fireInterval {
            var shouldShoot = false
            // Clear bricks in path
            if Pathfinder.nextTileIsBrick(fromCol: myTile.0, fromRow: myTile.1,
                                          direction: direction, grid: grid) {
                shouldShoot = true
            }
            // Eagle in LOS
            else if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                              direction: direction,
                                              targetCol: eagleTile.0, targetRow: eagleTile.1,
                                              grid: grid) {
                shouldShoot = true
            }
            // Player in LOS
            else if let playerPos = playerPosition {
                let playerT = positionToTile(playerPos)
                if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                             direction: direction,
                                             targetCol: playerT.0, targetRow: playerT.1,
                                             grid: grid) {
                    shouldShoot = true
                }
            }
            if shouldShoot {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.4...1.2)
                wantsToFire = true
            }
        }
    }

    // MARK: - Path Following

    private func followPath() {
        guard let next = currentPath.first else { return }

        // Convert waypoint to grid pixel position
        let targetX = CGFloat(next.0) * Constants.tileSize + Constants.tileSize / 2
        let targetY = CGFloat(next.1) * Constants.tileSize + Constants.tileSize / 2

        let dx = targetX - gridX
        let dy = targetY - gridY

        // Pick direction toward next waypoint
        if abs(dx) > abs(dy) {
            direction = dx > 0 ? .right : .left
        } else {
            direction = dy > 0 ? .down : .up
        }

        // Check if we've reached the waypoint
        if abs(dx) < 2 && abs(dy) < 2 {
            currentPath.removeFirst()
        }
    }

    // MARK: - Helpers

    func currentTile() -> (Int, Int) {
        let col = max(0, min(Constants.playAreaTiles - 1, Int(gridX / Constants.tileSize)))
        let row = max(0, min(Constants.playAreaTiles - 1, Int(gridY / Constants.tileSize)))
        return (col, row)
    }

    private func positionToTile(_ pos: CGPoint) -> (Int, Int) {
        // Convert SpriteKit position to grid tile
        let localX = pos.x - Constants.playAreaOriginX
        let localY = Constants.playAreaOriginY + Constants.playAreaSize - pos.y
        let col = max(0, min(Constants.playAreaTiles - 1, Int(localX / Constants.tileSize)))
        let row = max(0, min(Constants.playAreaTiles - 1, Int(localY / Constants.tileSize)))
        return (col, row)
    }

    // MARK: - Collision

    func onCollision() {
        directionChangeTimer = 0
        // Prevent AI from overriding direction for a short time
        collisionCooldown = 0.3

        // Filter out directions that would move into play area boundaries
        let margin = Constants.tileSize / 2 + 2
        let maxCoord = Constants.playAreaSize - margin
        var blockedDirs: Set<Direction> = [direction]
        if gridX <= margin { blockedDirs.insert(.left) }
        if gridX >= maxCoord { blockedDirs.insert(.right) }
        if gridY <= margin { blockedDirs.insert(.up) }
        if gridY >= maxCoord { blockedDirs.insert(.down) }

        let viable = Direction.allCases.filter { !blockedDirs.contains($0) }

        if aiBehavior == .wander {
            direction = viable.randomElement() ?? direction.opposite
        } else {
            direction = viable.randomElement() ?? direction.opposite
            currentPath = []
            pathRecalcTimer = pathRecalcInterval
        }
    }

    func shouldFire() -> Bool {
        return wantsToFire
    }

    // MARK: - Texture

    override func updateTexture() {
        self.texture = SpriteManager.shared.enemyTankTexture(
            type: enemyType,
            direction: direction,
            frame: animFrame,
            isFlashing: isFlashing && showFlashColor,
            armorHP: hp
        )
    }

    override func takeDamage() -> Bool {
        hp -= 1
        updateTexture()
        return hp <= 0
    }
}
