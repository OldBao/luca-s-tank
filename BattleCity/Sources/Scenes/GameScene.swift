import SpriteKit

class GameScene: SKScene {
    var gameState: GameState!
    var currentLevel: Int = 1

    // Managers
    let levelManager = LevelManager()
    let hud = GameHUD()

    // Player
    var player: PlayerTank!
    var enemies: [EnemyTank] = []
    var bullets: [Bullet] = []
    var activePowerUp: PowerUp?

    // Input state
    var pressedKeys: Set<UInt16> = []
    var currentMoveDirection: Direction?

    // Spawn timer
    var spawnTimer: TimeInterval = 0
    let spawnInterval: TimeInterval = 2.0
    var pendingSpawnPoints: Set<Int> = []  // track spawn point indices with pending effects

    // Level complete
    var levelCompleteTimer: TimeInterval = 0
    var isLevelEnding: Bool = false

    // Game over animation
    var isGameOverAnimating: Bool = false
    var gameOverLabel: SKLabelNode?
    var gameOverY: CGFloat = 0

    // Last update time
    var lastUpdateTime: TimeInterval = 0

    // Background
    var playAreaBackground: SKSpriteNode!

    override func didMove(to view: SKView) {
        self.scaleMode = .aspectFit
        self.backgroundColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)

        // Play area background (black)
        playAreaBackground = SKSpriteNode(color: .black, size: CGSize(width: Constants.playAreaSize, height: Constants.playAreaSize))
        playAreaBackground.anchorPoint = CGPoint(x: 0, y: 0)
        playAreaBackground.position = CGPoint(x: Constants.playAreaOriginX, y: Constants.playAreaOriginY)
        playAreaBackground.zPosition = 0
        self.addChild(playAreaBackground)

        // Load level
        gameState.startLevel(currentLevel)
        levelManager.loadLevel(currentLevel, into: self)

        // Setup HUD
        hud.setup()
        self.addChild(hud)
        hud.updateLevel(currentLevel)
        hud.updateLives(gameState.lives)
        hud.updateEnemyCount(gameState.enemyQueue.count - gameState.enemyQueueIndex)

        // Spawn player
        spawnPlayer()

        // Start background music
        SoundManager.shared.startMusic()
    }

    // MARK: - Player Spawn

    func spawnPlayer() {
        if player != nil {
            player.removeFromParent()
        }

        player = PlayerTank()
        player.setGridPosition(tileX: Int(Constants.playerSpawnTile.x), tileY: Int(Constants.playerSpawnTile.y))
        self.addChild(player)
        player.spawnWithShield()
        player.updateTexture()
    }

    // MARK: - Enemy Spawn

    func trySpawnEnemy() {
        guard gameState.canSpawnEnemy() else { return }

        // Check if next spawn point is pending
        let spawnIndex = gameState.nextSpawnPointIndex % Constants.enemySpawnTiles.count
        if pendingSpawnPoints.contains(spawnIndex) {
            return  // this point already has a spawn in progress
        }

        let spawnTile = gameState.getSpawnPoint()

        let spawnPos = CGPoint(
            x: Constants.playAreaOriginX + spawnTile.x * Constants.tileSize + Constants.tileSize / 2,
            y: Constants.playAreaOriginY + Constants.playAreaSize - (spawnTile.y * Constants.tileSize + Constants.tileSize / 2)
        )

        // Check if spawn point is clear of existing enemies
        for enemy in enemies {
            if abs(enemy.position.x - spawnPos.x) < Constants.tileSize &&
               abs(enemy.position.y - spawnPos.y) < Constants.tileSize {
                return  // blocked, try again later
            }
        }

        guard let info = gameState.nextEnemy() else { return }

        pendingSpawnPoints.insert(spawnIndex)
        let capturedIndex = spawnIndex

        // Spawn effect
        let effect = SpawnEffect(at: spawnPos) { [weak self] in
            guard let self = self else { return }
            self.pendingSpawnPoints.remove(capturedIndex)
            let enemy = EnemyTank(type: info.type, flashing: info.isFlashing)
            enemy.setGridPosition(tileX: Int(spawnTile.x), tileY: Int(spawnTile.y))
            self.addChild(enemy)
            self.enemies.append(enemy)
            self.gameState.enemiesOnScreen += 1
        }
        self.addChild(effect)
    }

    // MARK: - Input

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        pressedKeys.insert(event.keyCode)

        switch event.keyCode {
        case 36: // Enter - pause
            gameState.isPaused.toggle()
        case 49: // Space - fire
            fireBullet()
        default:
            break
        }
    }

    override func keyUp(with event: NSEvent) {
        pressedKeys.remove(event.keyCode)
    }

    func getInputDirection() -> Direction? {
        // Arrow keys: up=126, down=125, left=123, right=124
        if pressedKeys.contains(126) { return .up }
        if pressedKeys.contains(125) { return .down }
        if pressedKeys.contains(123) { return .left }
        if pressedKeys.contains(124) { return .right }
        return nil
    }

    // MARK: - Shooting

    func fireBullet() {
        guard let player = player, player.canFire() else { return }

        let bullet = Bullet(
            direction: player.direction,
            speed: player.bulletSpeed,
            isPlayerBullet: true,
            canDestroySteel: player.canDestroySteel
        )

        // Direction vectors are NES (down=+Y), SpriteKit is Y-up, so flip Y
        let offset = Constants.tileSize / 2 + 2
        bullet.position = CGPoint(
            x: player.position.x + player.direction.vector.dx * offset,
            y: player.position.y - player.direction.vector.dy * offset
        )

        self.addChild(bullet)
        bullets.append(bullet)
        player.bulletCount += 1

        SoundManager.shared.playShoot(on: self)
    }

    func enemyFire(_ enemy: EnemyTank) {
        let bullet = Bullet(
            direction: enemy.direction,
            speed: enemy.enemyType.bulletSpeed,
            isPlayerBullet: false,
            ownerID: ObjectIdentifier(enemy)
        )

        let offset = Constants.tileSize / 2 + 2
        bullet.position = CGPoint(
            x: enemy.position.x + enemy.direction.vector.dx * offset,
            y: enemy.position.y - enemy.direction.vector.dy * offset
        )

        self.addChild(bullet)
        bullets.append(bullet)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        guard !gameState.isPaused && !isGameOverAnimating else {
            updateGameOverAnimation(dt: dt)
            return
        }

        gameState.updateTimers(dt: dt)

        // Handle shovel deactivation
        if !gameState.isShovelActive {
            // Check if we need to deactivate
        }

        updatePlayer(dt: dt)
        updateEnemies(dt: dt)
        updateBullets(dt: dt)
        updateSpawning(dt: dt)
        checkLevelComplete(dt: dt)

        hud.updateEnemyCount(gameState.enemyQueue.count - gameState.enemyQueueIndex)
        hud.updateLives(gameState.lives)
    }

    func updatePlayer(dt: TimeInterval) {
        guard let player = player else { return }

        let inputDir = getInputDirection()
        player.isMoving = inputDir != nil

        if let dir = inputDir {
            if dir != player.direction {
                player.direction = dir
                player.snapPerpendicularAxis()
                player.updateTexture()
            }

            // Try to move
            let newPos = player.moveStep(dt: dt)
            let testX = newPos.x
            let testY = newPos.y

            if levelManager.canMoveTo(x: testX, y: testY, size: Constants.tileSize - 2) {
                player.applyMove(newX: testX, newY: testY)
            } else {
                player.snapToGrid()
                player.syncSpritePosition()
            }

            // Clamp to play area
            player.gridX = max(Constants.tileSize / 2, min(Constants.playAreaSize - Constants.tileSize / 2, player.gridX))
            player.gridY = max(Constants.tileSize / 2, min(Constants.playAreaSize - Constants.tileSize / 2, player.gridY))
            player.syncSpritePosition()
        }

        player.updateAnimation(dt: dt)
        player.updateShield(dt: dt)

        // Auto-fire while holding space
        if pressedKeys.contains(49) {
            fireBullet()
        }

        // Check power-up collection
        if let pu = activePowerUp, pu.parent != nil {
            let dist = hypot(player.position.x - pu.position.x, player.position.y - pu.position.y)
            if dist < Constants.tileSize {
                collectPowerUp(pu)
            }
        }

        // Player-enemy contact: enemy is destroyed
        for (i, enemy) in enemies.enumerated().reversed() {
            if abs(player.position.x - enemy.position.x) < Constants.tileSize - 2 &&
               abs(player.position.y - enemy.position.y) < Constants.tileSize - 2 {
                let exp = Explosion(at: enemy.position, size: .large)
                self.addChild(exp)
                SoundManager.shared.playExplosionLarge(on: self)

                if enemy.isFlashing {
                    spawnPowerUp()
                }

                gameState.enemyDestroyed(type: enemy.enemyType)
                enemy.removeFromParent()
                enemies.remove(at: i)
            }
        }

        // Safety: sync bulletCount with actual bullets on screen
        let playerBulletsAlive = bullets.filter { $0.isPlayerBullet && $0.parent != nil }.count
        player.bulletCount = playerBulletsAlive
    }

    func updateEnemies(dt: TimeInterval) {
        for enemy in enemies {
            enemy.updateAI(dt: dt, playerPosition: player?.position, grid: levelManager.tiles, bullets: bullets)
            enemy.updateAnimation(dt: dt)
            enemy.updateTexture()

            guard !enemy.isFrozen else { continue }

            // Move enemy
            let newPos = enemy.moveStep(dt: dt)
            if levelManager.canMoveTo(x: newPos.x, y: newPos.y, size: Constants.tileSize - 2) {
                // Check collision with other tanks (AABB)
                var blocked = false
                for other in enemies where other !== enemy {
                    if abs(newPos.x - other.gridX) < Constants.tileSize - 2 &&
                       abs(newPos.y - other.gridY) < Constants.tileSize - 2 {
                        blocked = true
                        break
                    }
                }
                // Check collision with player
                if let player = player {
                    if abs(newPos.x - player.gridX) < Constants.tileSize - 2 &&
                       abs(newPos.y - player.gridY) < Constants.tileSize - 2 {
                        blocked = true
                    }
                }

                if !blocked {
                    enemy.applyMove(newX: newPos.x, newY: newPos.y)
                } else {
                    enemy.onCollision()
                }
            } else {
                enemy.onCollision()
            }

            // Clamp and detect edge-stuck
            let minBound = Constants.tileSize / 2
            let maxBound = Constants.playAreaSize - Constants.tileSize / 2
            let oldX = enemy.gridX
            let oldY = enemy.gridY
            enemy.gridX = max(minBound, min(maxBound, enemy.gridX))
            enemy.gridY = max(minBound, min(maxBound, enemy.gridY))

            // If clamped to boundary while facing into it, treat as collision
            let atEdge = (enemy.gridX != oldX || enemy.gridY != oldY)
            let facingEdge = (enemy.gridX <= minBound && enemy.direction == .left)
                || (enemy.gridX >= maxBound && enemy.direction == .right)
                || (enemy.gridY <= minBound && enemy.direction == .up)
                || (enemy.gridY >= maxBound && enemy.direction == .down)
            if (atEdge || facingEdge) && enemy.collisionCooldown <= 0 {
                enemy.onCollision()
            }

            enemy.syncSpritePosition()

            // Fire
            if enemy.shouldFire() {
                enemyFire(enemy)
            }
        }

        // Separate overlapping enemies
        for i in 0..<enemies.count {
            for j in (i+1)..<enemies.count {
                let a = enemies[i]
                let b = enemies[j]
                let dx = a.gridX - b.gridX
                let dy = a.gridY - b.gridY
                let overlapX = Constants.tileSize - abs(dx)
                let overlapY = Constants.tileSize - abs(dy)
                if overlapX > 0 && overlapY > 0 {
                    // Push apart along the axis with less overlap
                    if overlapX < overlapY {
                        let push = overlapX / 2 + 0.5
                        if dx > 0 {
                            a.gridX += push; b.gridX -= push
                        } else {
                            a.gridX -= push; b.gridX += push
                        }
                    } else {
                        let push = overlapY / 2 + 0.5
                        if dy > 0 {
                            a.gridY += push; b.gridY -= push
                        } else {
                            a.gridY -= push; b.gridY += push
                        }
                    }
                    a.syncSpritePosition()
                    b.syncSpritePosition()
                }
            }
        }

        // Apply freeze
        if gameState.isFrozen {
            enemies.forEach { $0.isFrozen = true }
        } else {
            enemies.forEach { $0.isFrozen = false }
        }
    }

    func updateBullets(dt: TimeInterval) {
        var toRemove = Set<ObjectIdentifier>()

        for bullet in bullets {
            let bid = ObjectIdentifier(bullet)
            guard !toRemove.contains(bid) else { continue }

            // Move bullet
            let speed = bullet.moveSpeed
            let dx = bullet.direction.vector.dx * speed * CGFloat(dt)
            let dy = -bullet.direction.vector.dy * speed * CGFloat(dt)  // flip Y for SpriteKit
            bullet.position = CGPoint(x: bullet.position.x + dx, y: bullet.position.y + dy)

            // Check bounds
            let bx = bullet.position.x
            let by = bullet.position.y
            if bx < Constants.playAreaOriginX || bx > Constants.playAreaOriginX + Constants.playAreaSize ||
               by < Constants.playAreaOriginY || by > Constants.playAreaOriginY + Constants.playAreaSize {
                toRemove.insert(bid)
                continue
            }

            // Check tile collision - convert SpriteKit Y to grid row
            let localX = bx - Constants.playAreaOriginX
            let localY = Constants.playAreaOriginY + Constants.playAreaSize - by  // flip Y back to grid
            let col = max(0, min(Constants.playAreaTiles - 1, Int(localX / Constants.tileSize)))
            let row = max(0, min(Constants.playAreaTiles - 1, Int(localY / Constants.tileSize)))

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
                    if bullet.isPlayerBullet && bullet.canDestroySteel {
                        levelManager.removeTile(col: col, row: row)
                    }
                    toRemove.insert(bid)
                    SoundManager.shared.playHitSteel(on: self)
                    continue

                default:
                    break
                }
            }

            // Check eagle hit - only enemy bullets can destroy the eagle
            if !bullet.isPlayerBullet, let eagle = levelManager.eagle, eagle.isAlive {
                let eaglePos = eagle.position
                if abs(bx - eaglePos.x) < 10 && abs(by - eaglePos.y) < 10 {
                    eagle.destroy()
                    toRemove.insert(bid)
                    let exp = Explosion(at: eaglePos, size: .large)
                    self.addChild(exp)
                    triggerGameOver()
                    continue
                }
            }

            // Check bullet vs tanks
            if bullet.isPlayerBullet {
                for (i, enemy) in enemies.enumerated().reversed() {
                    if abs(bx - enemy.position.x) < 10 && abs(by - enemy.position.y) < 10 {
                        toRemove.insert(bid)
                        if enemy.takeDamage() {
                            let exp = Explosion(at: enemy.position, size: .large)
                            self.addChild(exp)
                            SoundManager.shared.playExplosionLarge(on: self)

                            if enemy.isFlashing {
                                spawnPowerUp()
                            }

                            gameState.enemyDestroyed(type: enemy.enemyType)
                            enemy.removeFromParent()
                            enemies.remove(at: i)
                        } else {
                            let exp = Explosion(at: bullet.position, size: .small)
                            self.addChild(exp)
                            SoundManager.shared.playExplosionSmall(on: self)
                        }
                        break
                    }
                }
            } else {
                // Enemy bullet hits player
                if let player = player, !player.isShielded {
                    if abs(bx - player.position.x) < 10 && abs(by - player.position.y) < 10 {
                        toRemove.insert(bid)
                        playerHit()
                    }
                }
            }

            // Bullet vs bullet
            for other in bullets where other !== bullet {
                let oid = ObjectIdentifier(other)
                guard !toRemove.contains(oid) else { continue }
                if bullet.isPlayerBullet != other.isPlayerBullet {
                    if abs(bullet.position.x - other.position.x) < 4 && abs(bullet.position.y - other.position.y) < 4 {
                        toRemove.insert(bid)
                        toRemove.insert(oid)
                    }
                }
            }
        }

        // Remove bullets and update counts
        for bullet in bullets {
            if toRemove.contains(ObjectIdentifier(bullet)) {
                if bullet.isPlayerBullet {
                    player?.bulletCount = max(0, (player?.bulletCount ?? 1) - 1)
                }
                bullet.removeFromParent()
            }
        }
        bullets.removeAll { $0.parent == nil }
    }

    func updateSpawning(dt: TimeInterval) {
        spawnTimer += dt
        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            trySpawnEnemy()
        }
    }

    // MARK: - Power-ups

    func spawnPowerUp() {
        activePowerUp?.removeFromParent()

        let type = PowerUpType.allCases.randomElement()!
        let pu = PowerUp(type: type)
        pu.placeRandomly(playAreaSize: Constants.playAreaSize)
        self.addChild(pu)
        activePowerUp = pu
    }

    func collectPowerUp(_ powerUp: PowerUp) {
        SoundManager.shared.playPowerUp(on: self)

        switch powerUp.powerUpType {
        case .star:
            player.upgradeTier()
        case .tank:
            gameState.addLife()
            SoundManager.shared.playBonusLife(on: self)
        case .shield:
            player.spawnWithShield(duration: Constants.shieldDuration)
        case .bomb:
            // Destroy all on-screen enemies
            for enemy in enemies {
                let exp = Explosion(at: enemy.position, size: .large)
                self.addChild(exp)
                gameState.enemyDestroyed(type: enemy.enemyType)
                enemy.removeFromParent()
            }
            enemies.removeAll()
        case .clock:
            gameState.freezeTimer = Constants.freezeDuration
        case .shovel:
            gameState.shovelTimer = Constants.shovelDuration
            levelManager.activateShovel()
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: Constants.shovelDuration),
                SKAction.run { [weak self] in
                    self?.levelManager.deactivateShovel()
                }
            ]), withKey: "shovel")
        case .steelBreaker:
            player.steelBreakerTimer = Constants.steelBreakerDuration
        }

        powerUp.removeFromParent()
        if activePowerUp === powerUp {
            activePowerUp = nil
        }
    }

    // MARK: - Player Hit

    func playerHit() {
        guard let player = player else { return }
        self.player = nil  // prevent multiple hits in same frame

        let exp = Explosion(at: player.position, size: .large)
        self.addChild(exp)
        SoundManager.shared.playExplosionLarge(on: self)

        player.removeFromParent()

        gameState.playerDied()

        if gameState.isGameOver {
            triggerGameOver()
        } else {
            // Respawn after delay
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    self?.spawnPlayer()
                }
            ]))
        }
    }

    // MARK: - Game Over

    func triggerGameOver() {
        isGameOverAnimating = true
        SoundManager.shared.playGameOver(on: self)

        // Classic "GAME OVER" rising from bottom
        gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel!.fontName = "Courier-Bold"
        gameOverLabel!.fontSize = 12
        gameOverLabel!.fontColor = .red
        gameOverLabel!.horizontalAlignmentMode = .center
        gameOverLabel!.verticalAlignmentMode = .center
        gameOverLabel!.position = CGPoint(x: Constants.logicalWidth / 2, y: Constants.logicalHeight + 10)
        gameOverLabel!.zPosition = 100
        self.addChild(gameOverLabel!)

        gameOverY = Constants.logicalHeight + 10
    }

    func updateGameOverAnimation(dt: TimeInterval) {
        guard isGameOverAnimating, let label = gameOverLabel else { return }

        let targetY = Constants.logicalHeight / 2
        gameOverY -= CGFloat(dt) * 80  // rise speed
        if gameOverY <= targetY {
            gameOverY = targetY
            // Wait then go to game over screen
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let scene = GameOverScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
                    scene.gameState = self.gameState
                    self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
                }
            ]))
            isGameOverAnimating = false
        }
        label.position.y = gameOverY
    }

    // MARK: - Level Complete

    func checkLevelComplete(dt: TimeInterval) {
        if gameState.isLevelComplete() && !isLevelEnding {
            isLevelEnding = true
            levelCompleteTimer = 0
        }

        if isLevelEnding {
            levelCompleteTimer += dt
            if levelCompleteTimer >= 3.0 {
                goToScoreTally()
            }
        }
    }

    func goToScoreTally() {
        SoundManager.shared.stopMusic()
        let scene = ScoreTallyScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
        scene.gameState = gameState
        scene.nextLevel = currentLevel + 1
        self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
    }

    // Power-up collection is handled manually in updatePlayer()
}
