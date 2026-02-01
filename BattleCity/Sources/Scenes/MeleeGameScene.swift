import SpriteKit

// MARK: - Data Structs (will move to MeleeScoreScene.swift in Task 10)

struct MeleeMatchResult {
    var winnerTeamIndex: Int
    var teamStats: [TeamMatchStats]
    var eliminationOrder: [Int]
    var playerKills: Int
}

struct TeamMatchStats {
    var teamColor: TeamColor
    var kills: Int
    var deaths: Int
    var survived: Int
    var total: Int
}

// MARK: - MeleeGameScene

class MeleeGameScene: SKScene {

    // MARK: - Configuration

    var meleeConfig: MeleeConfig!

    // MARK: - World

    var worldNode: SKNode!
    var playAreaBackground: SKSpriteNode!
    var levelManager: MeleeLevelManager!

    // MARK: - Tanks

    var allTanks: [MeleeTank] = []
    var controlledTank: MeleeTank?
    var playerMarker: SKSpriteNode!
    var spectatorTarget: MeleeTank?

    // MARK: - Bullets

    var meleeBullets: [MeleeBullet] = []

    // MARK: - Power-ups

    var activePowerUps: [PowerUp] = []
    var powerUpTimer: TimeInterval = 0
    let powerUpInterval: TimeInterval = 15.0
    let maxPowerUps = 3

    // MARK: - HUD

    var meleeHUD: MeleeHUD!

    // MARK: - Stats

    var teamKills: [Int] = [0, 0, 0, 0]
    var teamDeaths: [Int] = [0, 0, 0, 0]
    var playerKills: Int = 0
    var eliminationOrder: [Int] = []

    // MARK: - Camera

    var cameraX: CGFloat = 0
    var cameraY: CGFloat = 0

    // MARK: - State

    var lastUpdateTime: TimeInterval = 0
    var pressedKeys: Set<UInt16> = []
    var isMatchOver: Bool = false

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        self.scaleMode = .aspectFit
        self.backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

        // Create world node
        worldNode = SKNode()
        worldNode.zPosition = 0
        self.addChild(worldNode)

        // Generate map
        let gridSize = meleeConfig.mapSize.tiles
        let mapData = MapGenerator.generate(size: gridSize)

        // Create level manager and load map
        levelManager = MeleeLevelManager()
        levelManager.loadMap(mapData, into: self, parentNode: worldNode)

        let playAreaSize = levelManager.playAreaSize

        // Create black background for play area
        playAreaBackground = SKSpriteNode(color: .black, size: CGSize(width: playAreaSize, height: playAreaSize))
        playAreaBackground.anchorPoint = CGPoint(x: 0, y: 0)
        playAreaBackground.position = CGPoint(x: 0, y: 0)
        playAreaBackground.zPosition = -1
        worldNode.addChild(playAreaBackground)

        // Spawn all tanks
        spawnAllTanks(mapData: mapData)

        // Setup HUD (added to scene, not worldNode)
        meleeHUD = MeleeHUD()
        meleeHUD.setup(config: meleeConfig)
        meleeHUD.zPosition = 200
        self.addChild(meleeHUD)

        // Create player marker
        playerMarker = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 4))
        playerMarker.zPosition = 25
        worldNode.addChild(playerMarker)
        updatePlayerMarker()

        // Initialize camera to player position
        if let tank = controlledTank {
            cameraX = tank.position.x
            cameraY = tank.position.y
        } else {
            cameraX = playAreaSize / 2
            cameraY = playAreaSize / 2
        }
        updateCameraPosition()

        // Start music
        SoundManager.shared.startMusic()
    }

    // MARK: - Tank Spawning

    func spawnAllTanks(mapData: [[TileType]]) {
        let gridSize = meleeConfig.mapSize.tiles
        let zones = MapGenerator.spawnZones(size: gridSize)
        let playAreaSize = levelManager.playAreaSize

        for teamIdx in 0..<4 {
            let teamConfig = meleeConfig.teams[teamIdx]
            let zone = zones[teamIdx]
            var spawnIndex = 0

            // Iterate through tank types in a consistent order
            let tankTypes: [EnemyType] = [.basic, .fast, .power, .armor]
            for tankType in tankTypes {
                guard let typeConfig = teamConfig.tanks[tankType] else { continue }
                for _ in 0..<typeConfig.count {
                    let spawnTile = zone[spawnIndex % zone.count]
                    spawnIndex += 1

                    let isPlayer = (teamIdx == 0) && (spawnIndex == 1)
                    let tank = MeleeTank(
                        teamIndex: teamIdx,
                        teamColor: teamConfig.color,
                        tankType: tankType,
                        hp: typeConfig.hp,
                        isPlayerControlled: isPlayer
                    )
                    tank.meleePlayAreaSize = playAreaSize
                    tank.setGridPosition(tileX: spawnTile.0, tileY: spawnTile.1)
                    tank.activateShield(duration: 3.0)

                    worldNode.addChild(tank)
                    allTanks.append(tank)

                    if isPlayer {
                        controlledTank = tank
                    }
                }
            }
        }
    }

    // MARK: - Input

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        pressedKeys.insert(event.keyCode)

        if event.keyCode == 49 { // Space
            if let tank = controlledTank {
                fireMeleeBullet(from: tank)
            }
        }
    }

    override func keyUp(with event: NSEvent) {
        pressedKeys.remove(event.keyCode)
    }

    func getInputDirection() -> Direction? {
        if pressedKeys.contains(126) { return .up }
        if pressedKeys.contains(125) { return .down }
        if pressedKeys.contains(123) { return .left }
        if pressedKeys.contains(124) { return .right }
        return nil
    }

    // MARK: - Bullet Firing

    func fireMeleeBullet(from tank: MeleeTank) {
        guard tank.canFire() else { return }

        let bullet = MeleeBullet(
            direction: tank.direction,
            speed: tank.tankType.bulletSpeed,
            teamIndex: tank.teamIndex,
            canDestroySteel: tank.tankType == .power,
            owner: tank
        )

        let offset = Constants.tileSize / 2 + 2
        // tank.position is in SpriteKit world-space
        // direction.vector uses NES Y (up = -1, down = +1), so negate dy for SpriteKit
        bullet.position = CGPoint(
            x: tank.position.x + tank.direction.vector.dx * offset,
            y: tank.position.y - tank.direction.vector.dy * offset
        )

        worldNode.addChild(bullet)
        meleeBullets.append(bullet)
        tank.bulletCount += 1
        SoundManager.shared.playShoot(on: self)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        guard !isMatchOver else { return }

        updatePlayerInput(dt: dt)
        updateAI(dt: dt)
        updateTankMovement(dt: dt)
        updateBullets(dt: dt)
        updatePowerUps(dt: dt)
        updateShieldsAndFreeze(dt: dt)
        updateAnimations(dt: dt)
        updateHUD()
        updateCamera(dt: dt)
        checkWinCondition()
    }

    // MARK: - Player Input Update

    func updatePlayerInput(dt: TimeInterval) {
        guard let tank = controlledTank, tank.isPlayerControlled else { return }

        let inputDir = getInputDirection()
        tank.isMoving = inputDir != nil

        if let dir = inputDir {
            if dir != tank.direction {
                tank.direction = dir
                tank.snapPerpendicularAxis()
                tank.updateTexture()
            }

            let newPos = tank.moveStep(dt: dt)
            if levelManager.canMoveTo(x: newPos.x, y: newPos.y, size: Constants.tileSize - 2) {
                // Check tank-tank collision
                var blocked = false
                for other in allTanks where other !== tank {
                    if abs(newPos.x - other.gridX) < Constants.tileSize - 2 &&
                       abs(newPos.y - other.gridY) < Constants.tileSize - 2 {
                        blocked = true
                        break
                    }
                }
                if !blocked {
                    tank.applyMove(newX: newPos.x, newY: newPos.y)
                } else {
                    tank.snapToGrid()
                    tank.syncSpritePosition()
                }
            } else {
                tank.snapToGrid()
                tank.syncSpritePosition()
            }

            // Clamp to play area
            let playArea = levelManager.playAreaSize
            let half = Constants.tileSize / 2
            tank.gridX = max(half, min(playArea - half, tank.gridX))
            tank.gridY = max(half, min(playArea - half, tank.gridY))
            tank.syncSpritePosition()
        }

        // Auto-fire while holding space
        if pressedKeys.contains(49) {
            fireMeleeBullet(from: tank)
        }
    }

    // MARK: - AI Update

    func updateAI(dt: TimeInterval) {
        let gridSize = levelManager.gridSize

        // Build team count map
        var teamTankCounts: [Int: Int] = [:]
        for tank in allTanks {
            teamTankCounts[tank.teamIndex, default: 0] += 1
        }

        for tank in allTanks {
            guard !tank.isPlayerControlled else { continue }

            let enemyTanks = allTanks.filter { $0.teamIndex != tank.teamIndex }
            tank.updateMeleeAI(
                dt: dt,
                enemyTanks: enemyTanks,
                teamTankCounts: teamTankCounts,
                grid: levelManager.tiles,
                gridSize: gridSize
            )

            // Fire if AI wants to
            if tank.wantsToFire {
                fireMeleeBullet(from: tank)
            }
        }
    }

    // MARK: - Tank Movement (AI tanks)

    func updateTankMovement(dt: TimeInterval) {
        let playArea = levelManager.playAreaSize
        let half = Constants.tileSize / 2
        let gridSize = levelManager.gridSize

        for tank in allTanks {
            guard !tank.isPlayerControlled, !tank.isFrozen else { continue }

            let newPos = tank.moveStep(dt: dt)
            if levelManager.canMoveTo(x: newPos.x, y: newPos.y, size: Constants.tileSize - 2) {
                var blocked = false
                for other in allTanks where other !== tank {
                    if abs(newPos.x - other.gridX) < Constants.tileSize - 2 &&
                       abs(newPos.y - other.gridY) < Constants.tileSize - 2 {
                        blocked = true
                        break
                    }
                }
                if !blocked {
                    tank.applyMove(newX: newPos.x, newY: newPos.y)
                } else {
                    tank.onCollision(gridSize: gridSize)
                }
            } else {
                tank.onCollision(gridSize: gridSize)
            }

            // Clamp to play area
            let oldX = tank.gridX
            let oldY = tank.gridY
            tank.gridX = max(half, min(playArea - half, tank.gridX))
            tank.gridY = max(half, min(playArea - half, tank.gridY))

            let atEdge = (tank.gridX != oldX || tank.gridY != oldY)
            let facingEdge = (tank.gridX <= half && tank.direction == .left)
                || (tank.gridX >= playArea - half && tank.direction == .right)
                || (tank.gridY <= half && tank.direction == .up)
                || (tank.gridY >= playArea - half && tank.direction == .down)
            if (atEdge || facingEdge) && tank.collisionCooldown <= 0 {
                tank.onCollision(gridSize: gridSize)
            }

            tank.syncSpritePosition()
        }

        // Separate overlapping tanks
        for i in 0..<allTanks.count {
            for j in (i+1)..<allTanks.count {
                let a = allTanks[i]
                let b = allTanks[j]
                let dx = a.gridX - b.gridX
                let dy = a.gridY - b.gridY
                let overlapX = Constants.tileSize - abs(dx)
                let overlapY = Constants.tileSize - abs(dy)
                if overlapX > 0 && overlapY > 0 {
                    if overlapX < overlapY {
                        let push = overlapX / 2 + 0.5
                        if dx > 0 { a.gridX += push; b.gridX -= push }
                        else { a.gridX -= push; b.gridX += push }
                    } else {
                        let push = overlapY / 2 + 0.5
                        if dy > 0 { a.gridY += push; b.gridY -= push }
                        else { a.gridY -= push; b.gridY += push }
                    }
                    a.syncSpritePosition()
                    b.syncSpritePosition()
                }
            }
        }
    }

    // MARK: - Bullet Update

    func updateBullets(dt: TimeInterval) {
        var toRemove = Set<ObjectIdentifier>()

        for bullet in meleeBullets {
            let bid = ObjectIdentifier(bullet)
            guard !toRemove.contains(bid) else { continue }

            // Move bullet
            let dx = bullet.direction.vector.dx * bullet.moveSpeed * CGFloat(dt)
            let dy = -bullet.direction.vector.dy * bullet.moveSpeed * CGFloat(dt)
            bullet.position.x += dx
            bullet.position.y += dy

            let bx = bullet.position.x
            let by = bullet.position.y
            let playArea = levelManager.playAreaSize

            // Check bounds (world-space: 0..playAreaSize)
            if bx < 0 || bx > playArea || by < 0 || by > playArea {
                toRemove.insert(bid)
                continue
            }

            // Check tile collision
            let col = max(0, min(levelManager.gridSize - 1, Int(bx / Constants.tileSize)))
            let row = max(0, min(levelManager.gridSize - 1, Int((playArea - by) / Constants.tileSize)))

            if let tile = levelManager.tileAt(col: col, row: row) {
                switch tile.tileType {
                case .brick:
                    let destroyed = tile.hitBrick(from: bullet.direction)
                    if destroyed {
                        levelManager.removeTile(col: col, row: row)
                    }
                    toRemove.insert(bid)
                    SoundManager.shared.playHitBrick(on: self)
                    continue
                case .steel:
                    if bullet.canDestroySteel {
                        levelManager.removeTile(col: col, row: row)
                    }
                    toRemove.insert(bid)
                    SoundManager.shared.playHitSteel(on: self)
                    continue
                default:
                    break
                }
            }

            // Check tank collisions (friendly fire OFF)
            for (i, tank) in allTanks.enumerated().reversed() {
                guard bullet.teamIndex != tank.teamIndex else { continue }
                guard bullet.ownerID != ObjectIdentifier(tank) else { continue }

                if abs(bx - tank.position.x) < 10 && abs(by - tank.position.y) < 10 {
                    toRemove.insert(bid)

                    if tank.isShielded {
                        let exp = Explosion(at: bullet.position, size: .small)
                        worldNode.addChild(exp)
                        SoundManager.shared.playExplosionSmall(on: self)
                        break
                    }

                    if tank.takeDamage() {
                        // Tank destroyed
                        handleTankDeath(tank: tank, killerTeamIndex: bullet.teamIndex, at: i)
                    } else {
                        let exp = Explosion(at: bullet.position, size: .small)
                        worldNode.addChild(exp)
                        SoundManager.shared.playExplosionSmall(on: self)
                    }
                    break
                }
            }

            // Bullet vs bullet (different teams cancel)
            if !toRemove.contains(bid) {
                for other in meleeBullets where other !== bullet {
                    let oid = ObjectIdentifier(other)
                    guard !toRemove.contains(oid) else { continue }
                    if bullet.teamIndex != other.teamIndex {
                        if abs(bullet.position.x - other.position.x) < 4 &&
                           abs(bullet.position.y - other.position.y) < 4 {
                            toRemove.insert(bid)
                            toRemove.insert(oid)
                            break
                        }
                    }
                }
            }
        }

        // Remove bullets and update owner bullet counts
        for bullet in meleeBullets {
            if toRemove.contains(ObjectIdentifier(bullet)) {
                // Decrement bullet count on owner tank
                for tank in allTanks {
                    if ObjectIdentifier(tank) == bullet.ownerID {
                        tank.bulletCount = max(0, tank.bulletCount - 1)
                        break
                    }
                }
                bullet.removeFromParent()
            }
        }
        meleeBullets.removeAll { $0.parent == nil }
    }

    // MARK: - Tank Death

    func handleTankDeath(tank: MeleeTank, killerTeamIndex: Int, at index: Int) {
        let exp = Explosion(at: tank.position, size: .large)
        worldNode.addChild(exp)
        SoundManager.shared.playExplosionLarge(on: self)

        // Stats
        teamKills[killerTeamIndex] += 1
        teamDeaths[tank.teamIndex] += 1
        if killerTeamIndex == 0 {
            playerKills += 1
        }

        // Was this the controlled tank?
        let wasControlled = (tank === controlledTank)

        tank.removeFromParent()
        allTanks.remove(at: index)

        // Remove any bullets owned by this tank
        let deadID = ObjectIdentifier(tank)
        for bullet in meleeBullets where bullet.ownerID == deadID {
            bullet.removeFromParent()
        }
        meleeBullets.removeAll { $0.parent == nil }

        // Check if team is now eliminated
        let teamIdx = tank.teamIndex
        let teamAlive = allTanks.filter { $0.teamIndex == teamIdx }.count
        if teamAlive == 0 && !eliminationOrder.contains(teamIdx) {
            eliminationOrder.append(teamIdx)
        }

        // Switch control if needed
        if wasControlled {
            switchToNextTeammate()
        }
    }

    // MARK: - Player Control Switch

    func switchToNextTeammate() {
        controlledTank?.isPlayerControlled = false
        controlledTank = nil

        let playerTeamIdx = 0  // player is always team 0
        let teammates = allTanks.filter { $0.teamIndex == playerTeamIdx }
        if let next = teammates.first {
            next.isPlayerControlled = true
            controlledTank = next
        } else {
            // Spectator mode: follow a random surviving tank
            spectatorTarget = allTanks.first
        }
        updatePlayerMarker()
    }

    // MARK: - Power-up Update

    func updatePowerUps(dt: TimeInterval) {
        powerUpTimer += dt

        // Spawn new power-ups
        if powerUpTimer >= powerUpInterval && activePowerUps.count < maxPowerUps {
            powerUpTimer = 0
            spawnPowerUp()
        }

        // Check collection by player-controlled tank only
        guard let tank = controlledTank else { return }
        for (i, pu) in activePowerUps.enumerated().reversed() {
            guard pu.parent != nil else {
                activePowerUps.remove(at: i)
                continue
            }
            let dist = hypot(tank.position.x - pu.position.x, tank.position.y - pu.position.y)
            if dist < Constants.tileSize {
                collectPowerUp(pu, collector: tank)
                activePowerUps.remove(at: i)
            }
        }
    }

    func spawnPowerUp() {
        let type = PowerUpType.allCases.randomElement()!
        let pu = PowerUp(type: type)
        let margin = Constants.tileSize
        let playArea = levelManager.playAreaSize
        let x = CGFloat.random(in: margin...(playArea - margin))
        let y = CGFloat.random(in: margin...(playArea - margin))
        pu.position = CGPoint(x: x, y: y)
        worldNode.addChild(pu)
        activePowerUps.append(pu)
    }

    func collectPowerUp(_ powerUp: PowerUp, collector: MeleeTank) {
        SoundManager.shared.playPowerUp(on: self)

        switch powerUp.powerUpType {
        case .star:
            // Give shield in melee (no upgrade system)
            collector.activateShield(duration: 5.0)
        case .tank:
            // No respawn mechanic — give shield instead
            collector.activateShield(duration: 10.0)
        case .shield:
            collector.activateShield(duration: 10.0)
        case .bomb:
            // Destroy all enemy tanks on screen (for collector's team)
            for (i, tank) in allTanks.enumerated().reversed() {
                guard tank.teamIndex != collector.teamIndex else { continue }
                let exp = Explosion(at: tank.position, size: .large)
                worldNode.addChild(exp)
                teamKills[collector.teamIndex] += 1
                teamDeaths[tank.teamIndex] += 1
                if collector.teamIndex == 0 { playerKills += 1 }
                let wasControlled = (tank === controlledTank)
                tank.removeFromParent()
                allTanks.remove(at: i)
                // Check team elimination
                let teamAlive = allTanks.filter { $0.teamIndex == tank.teamIndex }.count
                if teamAlive == 0 && !eliminationOrder.contains(tank.teamIndex) {
                    eliminationOrder.append(tank.teamIndex)
                }
                if wasControlled {
                    switchToNextTeammate()
                }
            }
            SoundManager.shared.playExplosionLarge(on: self)
        case .clock:
            // Freeze all teams except collector's team for 10s
            for tank in allTanks where tank.teamIndex != collector.teamIndex {
                tank.isFrozen = true
                tank.frozenTimer = 10.0
            }
        case .shovel:
            // Give shield instead (no eagle in melee)
            collector.activateShield(duration: 10.0)
        case .steelBreaker:
            // Give shield instead
            collector.activateShield(duration: 5.0)
        }

        powerUp.removeFromParent()
    }

    // MARK: - Shield & Freeze Update

    func updateShieldsAndFreeze(dt: TimeInterval) {
        for tank in allTanks {
            tank.updateShield(dt: dt)
        }
    }

    // MARK: - Animation Update

    func updateAnimations(dt: TimeInterval) {
        for tank in allTanks {
            tank.updateAnimation(dt: dt)
            tank.updateTexture()
        }
        updatePlayerMarker()
    }

    // MARK: - HUD Update

    func updateHUD() {
        var surviving = [0, 0, 0, 0]
        for tank in allTanks {
            surviving[tank.teamIndex] += 1
        }
        meleeHUD.update(surviving: surviving)
    }

    // MARK: - Camera

    func updateCamera(dt: TimeInterval) {
        // Determine target
        var targetX: CGFloat
        var targetY: CGFloat

        if let tank = controlledTank {
            targetX = tank.position.x
            targetY = tank.position.y
        } else if let spec = spectatorTarget, spec.parent != nil {
            targetX = spec.position.x
            targetY = spec.position.y
        } else {
            // Pick a new spectator target
            spectatorTarget = allTanks.first
            targetX = spectatorTarget?.position.x ?? levelManager.playAreaSize / 2
            targetY = spectatorTarget?.position.y ?? levelManager.playAreaSize / 2
        }

        // Lerp
        cameraX += (targetX - cameraX) * 0.1
        cameraY += (targetY - cameraY) * 0.1

        // Clamp so viewport doesn't go outside map
        let halfW = Constants.logicalWidth / 2
        let halfH = Constants.logicalHeight / 2
        let playArea = levelManager.playAreaSize

        cameraX = max(halfW, min(playArea - halfW, cameraX))
        cameraY = max(halfH, min(playArea - halfH, cameraY))

        updateCameraPosition()
    }

    func updateCameraPosition() {
        let viewCenterX = Constants.logicalWidth / 2
        let viewCenterY = Constants.logicalHeight / 2
        worldNode.position = CGPoint(x: viewCenterX - cameraX, y: viewCenterY - cameraY)
    }

    // MARK: - Player Marker

    func updatePlayerMarker() {
        if let tank = controlledTank {
            playerMarker.isHidden = false
            playerMarker.position = CGPoint(x: tank.position.x, y: tank.position.y + Constants.tileSize / 2 + 4)
        } else {
            playerMarker.isHidden = true
        }
    }

    // MARK: - Win Condition

    func checkWinCondition() {
        var teamSurviving = [0, 0, 0, 0]
        for tank in allTanks {
            teamSurviving[tank.teamIndex] += 1
        }
        let aliveTeams = (0..<4).filter { teamSurviving[$0] > 0 }
        if aliveTeams.count <= 1 {
            let winnerIndex = aliveTeams.first ?? 0
            transitionToScoreScene(winner: winnerIndex, surviving: teamSurviving)
        }
    }

    // MARK: - Score Scene Transition

    func transitionToScoreScene(winner: Int, surviving: [Int]) {
        isMatchOver = true
        SoundManager.shared.stopMusic()

        // Determine if player won
        if winner == 0 {
            SoundManager.shared.playPowerUp(on: self)
        } else {
            SoundManager.shared.playGameOver(on: self)
        }

        let result = MeleeMatchResult(
            winnerTeamIndex: winner,
            teamStats: (0..<4).map { i in
                TeamMatchStats(
                    teamColor: meleeConfig.teams[i].color,
                    kills: teamKills[i],
                    deaths: teamDeaths[i],
                    survived: surviving[i],
                    total: meleeConfig.teams[i].totalTanks
                )
            },
            eliminationOrder: eliminationOrder,
            playerKills: playerKills
        )

        // Show winner text
        let winLabel = SKLabelNode(text: "\(meleeConfig.teams[winner].color.name) WINS!")
        winLabel.fontName = "Courier-Bold"
        winLabel.fontSize = 14
        winLabel.fontColor = .white
        winLabel.horizontalAlignmentMode = .center
        winLabel.verticalAlignmentMode = .center
        winLabel.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight / 2)
        winLabel.zPosition = 300
        self.addChild(winLabel)

        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let scene = MeleeScoreScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
                scene.matchResult = result
                scene.meleeConfig = self.meleeConfig
                self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
            }
        ]))
    }
}
