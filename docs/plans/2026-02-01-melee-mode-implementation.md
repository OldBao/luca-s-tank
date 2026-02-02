# Melee Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 4-team "Melee Mode" where teams fight on procedurally generated maps, alongside the existing single-player mode.

**Architecture:** New standalone scenes and entities for melee mode. Existing single-player code stays untouched. Melee mode uses a new `MeleeGameScene` (not inheriting `GameScene`), a `MeleeConfig` data model, procedural `MapGenerator`, and a `MeleeTank` entity that supports team affiliation and color tinting. The existing `Pathfinder` is reused with variable grid sizes.

**Tech Stack:** Swift 5, SpriteKit, AVAudioEngine (existing), Core Graphics (existing texture generation)

---

### Task 1: MeleeConfig Data Model

**Files:**
- Create: `BattleCity/Sources/Data/MeleeConfig.swift`

**Step 1: Create the MeleeConfig data model**

This holds all match settings. No UI yet — just the data structures.

```swift
import Foundation

enum TeamColor: Int, CaseIterable {
    case yellow = 0, red = 1, blue = 2, green = 3

    var name: String {
        switch self {
        case .yellow: return "Yellow"
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        }
    }
}

struct TankTypeConfig {
    var count: Int
    var hp: Int
}

struct TeamConfig {
    var color: TeamColor
    var isPlayer: Bool
    var tanks: [EnemyType: TankTypeConfig]  // reuse EnemyType enum for tank types

    var totalTanks: Int {
        tanks.values.reduce(0) { $0 + $1.count }
    }

    static func defaultConfig(color: TeamColor, isPlayer: Bool) -> TeamConfig {
        return TeamConfig(
            color: color,
            isPlayer: isPlayer,
            tanks: [
                .basic: TankTypeConfig(count: 2, hp: 3),
                .fast: TankTypeConfig(count: 1, hp: 3),
                .power: TankTypeConfig(count: 1, hp: 3),
                .armor: TankTypeConfig(count: 1, hp: 3),
            ]
        )
    }
}

enum MapSize: Int, CaseIterable {
    case small = 16   // 16x16
    case medium = 20  // 20x20
    case large = 26   // 26x26
    case huge = 30    // 30x30

    var tiles: Int { rawValue }
    var label: String { "\(rawValue)x\(rawValue)" }
}

struct MeleeConfig {
    var mapSize: MapSize = .medium
    var playerColor: TeamColor = .yellow
    var teams: [TeamConfig]

    init() {
        let allColors: [TeamColor] = [.yellow, .red, .blue, .green]
        teams = allColors.map { color in
            TeamConfig.defaultConfig(color: color, isPlayer: color == .yellow)
        }
    }

    /// Reassign colors after player picks theirs
    mutating func setPlayerColor(_ color: TeamColor) {
        playerColor = color
        let otherColors = TeamColor.allCases.filter { $0 != color }
        teams[0] = TeamConfig.defaultConfig(color: color, isPlayer: true)
        for i in 1..<4 {
            teams[i] = TeamConfig.defaultConfig(color: otherColors[i - 1], isPlayer: false)
        }
    }
}
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Data/MeleeConfig.swift
git commit -m "feat(melee): add MeleeConfig data model for match settings"
```

---

### Task 2: Team Color Support in SpriteManager

**Files:**
- Modify: `BattleCity/Sources/Managers/SpriteManager.swift`

**Step 1: Add team color tinting method**

Add a method to `SpriteManager` that generates team-colored tank textures. The approach: take the existing enemy tank drawing code and apply a color tint based on team color. Add new color constants for each team.

Add to `NESColors`:

```swift
// Team colors for melee mode
static let teamYellowBody  = CGColor(red: 252/255, green: 200/255, blue: 56/255, alpha: 1)
static let teamYellowDark  = CGColor(red: 200/255, green: 152/255, blue: 36/255, alpha: 1)
static let teamRedBody     = CGColor(red: 252/255, green: 56/255, blue: 56/255, alpha: 1)
static let teamRedDark     = CGColor(red: 180/255, green: 36/255, blue: 36/255, alpha: 1)
static let teamBlueBody    = CGColor(red: 56/255, green: 100/255, blue: 252/255, alpha: 1)
static let teamBlueDark    = CGColor(red: 36/255, green: 72/255, blue: 200/255, alpha: 1)
static let teamGreenBody   = CGColor(red: 56/255, green: 200/255, blue: 56/255, alpha: 1)
static let teamGreenDark   = CGColor(red: 36/255, green: 148/255, blue: 36/255, alpha: 1)
```

Add to `SpriteManager`:

```swift
/// Melee mode team tank texture — draws a tank in the team's color.
/// Reuses the enemy tank drawing logic but swaps body/tread colors for the team.
func meleeTeamTankTexture(type: EnemyType, direction: Direction, frame: Int,
                          teamColor: TeamColor, armorHP: Int = 4) -> SKTexture {
    let key = "melee_\(teamColor.rawValue)_\(type.rawValue)_d\(direction.rawValue)_f\(frame)_hp\(armorHP)"
    if let cached = textureCache[key] { return cached }

    // Generate by drawing with team colors — reuse generateEnemyTankTexture approach
    // but override the body and tread colors based on teamColor
    let bodyColor: CGColor
    let treadColor: CGColor
    switch teamColor {
    case .yellow:
        bodyColor = NESColors.teamYellowBody
        treadColor = NESColors.teamYellowDark
    case .red:
        bodyColor = NESColors.teamRedBody
        treadColor = NESColors.teamRedDark
    case .blue:
        bodyColor = NESColors.teamBlueBody
        treadColor = NESColors.teamBlueDark
    case .green:
        bodyColor = NESColors.teamGreenBody
        treadColor = NESColors.teamGreenDark
    }

    let tex = generateTeamTankTexture(type: type, direction: direction, frame: frame,
                                       bodyColor: bodyColor, treadColor: treadColor,
                                       armorHP: armorHP)
    textureCache[key] = tex
    return tex
}
```

Then add `generateTeamTankTexture` — this should be a copy of the existing `generateEnemyTankTexture` private method but parameterized on body/tread colors instead of using hardcoded enemy colors. Refactor: extract the drawing logic into a shared helper that both `generateEnemyTankTexture` and `generateTeamTankTexture` call.

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Managers/SpriteManager.swift
git commit -m "feat(melee): add team-colored tank texture generation"
```

---

### Task 3: MeleeTank Entity

**Files:**
- Create: `BattleCity/Sources/Entities/MeleeTank.swift`

**Step 1: Create MeleeTank class**

`MeleeTank` extends `Tank` with team info, configurable HP, and AI for multi-team combat. It replaces both `PlayerTank` and `EnemyTank` roles in melee mode.

```swift
import SpriteKit

enum MeleeAIBehavior {
    case playerControlled  // human input
    case aiWander          // Basic: random movement
    case aiHuntNearest     // Fast: pathfind to nearest enemy
    case aiHuntAndBreak    // Power: pathfind + brick clearing
    case aiHuntWeakest     // Armor: target weakest team
}

class MeleeTank: Tank {
    let teamIndex: Int        // 0-3
    let teamColor: TeamColor
    let tankType: EnemyType   // reuse for speed/bullet properties
    let aiBehavior: MeleeAIBehavior
    var isPlayerControlled: Bool

    // Shield (from power-up)
    var isShielded: Bool = false
    var shieldTimer: TimeInterval = 0
    var shieldNode: SKSpriteNode?

    // Bullet tracking
    var bulletCount: Int = 0
    var maxBullets: Int { tankType == .armor ? 2 : 1 }

    // AI state (same structure as EnemyTank)
    var currentPath: [(Int, Int)] = []
    var pathRecalcTimer: TimeInterval = 0
    var pathRecalcInterval: TimeInterval = 1.0
    var directionChangeTimer: TimeInterval = 0
    var directionChangeInterval: TimeInterval = 2.0
    var fireTimer: TimeInterval = 0
    var fireInterval: TimeInterval = 1.5
    var collisionCooldown: TimeInterval = 0
    var wantsToFire: Bool = false

    // Frozen state (clock power-up)
    var isFrozen: Bool = false
    var frozenTimer: TimeInterval = 0

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

    // MARK: - AI Update (multi-team targeting)

    func updateMeleeAI(dt: TimeInterval,
                       enemyTanks: [MeleeTank],
                       teamTankCounts: [Int: Int],
                       grid: [[Tile?]],
                       gridSize: Int) {
        guard !isPlayerControlled, !isFrozen else { return }

        isMoving = true
        wantsToFire = false

        if collisionCooldown > 0 {
            collisionCooldown -= dt
        }

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
        case .playerControlled:
            break
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

        // Fire at enemies in LOS
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
            currentPath = Pathfinder.findPath(from: myTile, to: targetTile,
                                              grid: grid, canBreakBricks: false)
            if currentPath.isEmpty {
                updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
                return
            }
        }

        followPath()

        // Fire at enemies in LOS
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
            currentPath = Pathfinder.findPath(from: myTile, to: targetTile,
                                              grid: grid, canBreakBricks: true)
            if currentPath.isEmpty {
                updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
                return
            }
        }

        followPath()

        fireTimer += dt
        if fireTimer >= fireInterval {
            let myTile = currentTile(gridSize: gridSize)
            if Pathfinder.nextTileIsBrick(fromCol: myTile.0, fromRow: myTile.1,
                                           direction: direction, grid: grid) {
                fireTimer = 0
                fireInterval = TimeInterval.random(in: 0.4...1.2)
                wantsToFire = true
            } else {
                let targetTile = tileFromGrid(nearest.gridX, nearest.gridY, gridSize: gridSize)
                if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                              direction: direction,
                                              targetCol: targetTile.0, targetRow: targetTile.1,
                                              grid: grid) {
                    fireTimer = 0
                    fireInterval = TimeInterval.random(in: 0.4...1.2)
                    wantsToFire = true
                }
            }
        }
    }

    private func updateHuntWeakest(dt: TimeInterval, enemyTanks: [MeleeTank],
                                   teamTankCounts: [Int: Int],
                                   grid: [[Tile?]], gridSize: Int) {
        // Find the team with fewest tanks (excluding self's team and eliminated teams)
        let enemyCounts = teamTankCounts.filter { $0.key != teamIndex && $0.value > 0 }
        guard let weakestTeam = enemyCounts.min(by: { $0.value < $1.value })?.key else {
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
            return
        }

        let weakestTeamTanks = enemyTanks.filter { $0.teamIndex == weakestTeam }
        guard let target = weakestTeamTanks.min(by: {
            manhattanDist(to: $0) < manhattanDist(to: $1)
        }) else {
            updateWander(dt: dt, enemyTanks: enemyTanks, grid: grid, gridSize: gridSize)
            return
        }

        pathRecalcTimer += dt
        if pathRecalcTimer >= pathRecalcInterval || currentPath.isEmpty {
            pathRecalcTimer = 0
            let myTile = currentTile(gridSize: gridSize)
            let targetTile = tileFromGrid(target.gridX, target.gridY, gridSize: gridSize)
            currentPath = Pathfinder.findPath(from: myTile, to: targetTile,
                                              grid: grid, canBreakBricks: true)
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
            if Pathfinder.nextTileIsBrick(fromCol: myTile.0, fromRow: myTile.1,
                                           direction: direction, grid: grid) {
                shouldShoot = true
            } else {
                let targetTile = tileFromGrid(target.gridX, target.gridY, gridSize: gridSize)
                if Pathfinder.hasLineOfSight(fromCol: myTile.0, fromRow: myTile.1,
                                              direction: direction,
                                              targetCol: targetTile.0, targetRow: targetTile.1,
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

    // MARK: - Helpers

    private func followPath() {
        guard let next = currentPath.first else { return }
        let targetX = CGFloat(next.0) * Constants.tileSize + Constants.tileSize / 2
        let targetY = CGFloat(next.1) * Constants.tileSize + Constants.tileSize / 2
        let dx = targetX - gridX
        let dy = targetY - gridY
        if abs(dx) > abs(dy) {
            direction = dx > 0 ? .right : .left
        } else {
            direction = dy > 0 ? .down : .up
        }
        if abs(dx) < 2 && abs(dy) < 2 {
            currentPath.removeFirst()
        }
    }

    private func findNearestEnemy(_ enemies: [MeleeTank]) -> MeleeTank? {
        return enemies.min(by: { manhattanDist(to: $0) < manhattanDist(to: $1) })
    }

    private func manhattanDist(to other: MeleeTank) -> CGFloat {
        return abs(gridX - other.gridX) + abs(gridY - other.gridY)
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

    func canFire() -> Bool {
        return bulletCount < maxBullets
    }

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
            if shieldTimer <= 0 {
                isShielded = false
                shieldNode?.removeFromParent()
                shieldNode = nil
            }
        }
        if frozenTimer > 0 {
            frozenTimer -= dt
            if frozenTimer <= 0 { isFrozen = false }
        }
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
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Entities/MeleeTank.swift
git commit -m "feat(melee): add MeleeTank entity with team affiliation and multi-team AI"
```

---

### Task 4: MapGenerator for Procedural Maps

**Files:**
- Create: `BattleCity/Sources/Managers/MapGenerator.swift`

**Step 1: Create the MapGenerator**

Generates NxN tile grids with 4-way rotational symmetry, guaranteed connectivity, and corner spawn zones.

```swift
import SpriteKit

struct MapGenerator {

    /// Generate a procedural map for melee mode.
    /// Returns a 2D array [row][col] of TileType values.
    static func generate(size: Int) -> [[TileType]] {
        // Generate one quadrant (top-left), then mirror for 4-way symmetry
        let half = size / 2
        var quadrant = Array(repeating: Array(repeating: TileType.empty, count: half), count: half)

        // Fill quadrant with random terrain
        for row in 0..<half {
            for col in 0..<half {
                // Spawn zone: 3x3 clear area in corner
                if row < 3 && col < 3 { continue }

                // Central area: more open (within 2 tiles of center)
                let distToCenter = max(half - 1 - row, half - 1 - col)
                if distToCenter < 2 {
                    if Double.random(in: 0...1) < 0.3 {
                        quadrant[row][col] = randomTerrain()
                    }
                    continue
                }

                let roll = Double.random(in: 0...1)
                if roll < 0.35 {
                    quadrant[row][col] = randomTerrain()
                }
            }
        }

        // Build full map with 4-way rotational symmetry
        var map = Array(repeating: Array(repeating: TileType.empty, count: size), count: size)

        for row in 0..<half {
            for col in 0..<half {
                let t = quadrant[row][col]
                // Top-left
                map[row][col] = t
                // Top-right (rotate 90 CW)
                map[col][size - 1 - row] = t
                // Bottom-right (rotate 180)
                map[size - 1 - row][size - 1 - col] = t
                // Bottom-left (rotate 270 CW / 90 CCW)
                map[size - 1 - col][row] = t
            }
        }

        // Verify connectivity between all 4 spawn zones using BFS
        if !isConnected(map: map, size: size) {
            // Retry (recursive, but symmetry makes disconnection rare)
            return generate(size: size)
        }

        return map
    }

    private static func randomTerrain() -> TileType {
        let roll = Double.random(in: 0...1)
        if roll < 0.40 { return .brick }
        if roll < 0.65 { return .steel }
        if roll < 0.80 { return .trees }
        if roll < 0.90 { return .water }
        return .ice
    }

    /// BFS connectivity check: ensures all 4 corners can reach each other.
    private static func isConnected(map: [[TileType]], size: Int) -> Bool {
        let corners = [
            (1, 1),                      // top-left spawn center
            (1, size - 2),               // top-right spawn center
            (size - 2, size - 2),        // bottom-right spawn center
            (size - 2, 1),               // bottom-left spawn center
        ]

        // BFS from first corner
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        var queue: [(Int, Int)] = [corners[0]]
        visited[corners[0].0][corners[0].1] = true
        let directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]

        while !queue.isEmpty {
            let (cr, cc) = queue.removeFirst()
            for (dr, dc) in directions {
                let nr = cr + dr
                let nc = cc + dc
                guard nr >= 0, nr < size, nc >= 0, nc < size, !visited[nr][nc] else { continue }
                let tile = map[nr][nc]
                if tile == .steel || tile == .water { continue }
                visited[nr][nc] = true
                queue.append((nr, nc))
            }
        }

        // Check all corners reachable
        for (r, c) in corners {
            if !visited[r][c] { return false }
        }
        return true
    }

    /// Spawn positions (tile coordinates) for each team.
    /// Returns array of 4 spawn zones, each containing the tiles where tanks can spawn.
    static func spawnZones(size: Int) -> [[(Int, Int)]] {
        return [
            // Top-left: team 0
            [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)],
            // Top-right: team 1
            [(size-3, 0), (size-2, 0), (size-1, 0), (size-3, 1), (size-2, 1), (size-1, 1), (size-3, 2), (size-2, 2), (size-1, 2)],
            // Bottom-right: team 2
            [(size-3, size-3), (size-2, size-3), (size-1, size-3), (size-3, size-2), (size-2, size-2), (size-1, size-2), (size-3, size-1), (size-2, size-1), (size-1, size-1)],
            // Bottom-left: team 3
            [(0, size-3), (1, size-3), (2, size-3), (0, size-2), (1, size-2), (2, size-2), (0, size-1), (1, size-1), (2, size-1)],
        ]
    }
}
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Managers/MapGenerator.swift
git commit -m "feat(melee): add MapGenerator with 4-way symmetric procedural maps"
```

---

### Task 5: MeleeLevelManager

**Files:**
- Create: `BattleCity/Sources/Managers/MeleeLevelManager.swift`

**Step 1: Create MeleeLevelManager**

Like `LevelManager` but for variable-size maps, no eagle.

```swift
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
                tiles[row][col] = tile
                parentNode.addChild(tile)
            }
        }
    }

    func clearLevel() {
        for row in tiles {
            for tile in row {
                tile?.removeFromParent()
            }
        }
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
        let minX = x - halfSize
        let maxX = x + halfSize
        let minY = y - halfSize
        let maxY = y + halfSize

        if minX < 0 || maxX > playAreaSize || minY < 0 || maxY > playAreaSize {
            return false
        }

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
                    default:
                        break
                    }
                }
            }
        }
        return true
    }
}
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Managers/MeleeLevelManager.swift
git commit -m "feat(melee): add MeleeLevelManager for variable-size maps"
```

---

### Task 6: Melee Bullet with Team Affiliation

**Files:**
- Create: `BattleCity/Sources/Entities/MeleeBullet.swift`

**Step 1: Create MeleeBullet**

Extends `Bullet` concept with team index for friendly-fire prevention.

```swift
import SpriteKit

class MeleeBullet: SKSpriteNode {
    let direction: Direction
    let moveSpeed: CGFloat
    let teamIndex: Int
    let canDestroySteel: Bool
    let ownerID: ObjectIdentifier

    init(direction: Direction, speed: CGFloat, teamIndex: Int,
         canDestroySteel: Bool = false, owner: MeleeTank) {
        self.direction = direction
        self.moveSpeed = speed
        self.teamIndex = teamIndex
        self.canDestroySteel = canDestroySteel
        self.ownerID = ObjectIdentifier(owner)

        let tex = SpriteManager.shared.bulletTexture(direction: direction)
        super.init(texture: tex, color: .clear, size: CGSize(width: 4, height: 4))
        self.zPosition = 11
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Entities/MeleeBullet.swift
git commit -m "feat(melee): add MeleeBullet with team affiliation"
```

---

### Task 7: MeleeHUD

**Files:**
- Create: `BattleCity/Sources/HUD/MeleeHUD.swift`

**Step 1: Create MeleeHUD**

Shows team survival bars and player indicator. Overlaid on top of the camera viewport.

```swift
import SpriteKit

class MeleeHUD: SKNode {
    private var teamLabels: [SKLabelNode] = []
    private var teamBars: [SKSpriteNode] = []
    private var teamCountLabels: [SKLabelNode] = []
    private var playerMarker: SKLabelNode!

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
            let total = max(teamTotals[i], 1)
            let alive = surviving[i]
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
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/HUD/MeleeHUD.swift
git commit -m "feat(melee): add MeleeHUD with team survival bars"
```

---

### Task 8: MeleeGameScene — Core Game Loop

**Files:**
- Create: `BattleCity/Sources/Scenes/MeleeGameScene.swift`

**Step 1: Create MeleeGameScene**

This is the main melee gameplay scene. Standalone — does NOT inherit from `GameScene`. Handles:
- Scrolling camera centered on player's tank
- All tank spawning from config
- Multi-team bullet collision (friendly fire off)
- Power-up spawning on timer
- Win condition (last team standing)
- Player control switching on death

Key architecture decisions:
- `worldNode: SKNode` contains all game objects; camera moves the worldNode
- Viewport stays at 256x224 logical pixels
- `allTanks: [MeleeTank]` is the main array, split by team for collision checks
- Player marker (arrow) drawn above controlled tank

This is the largest task. The scene should handle:
1. `didMove(to:)` — setup world, generate map, spawn all tanks, setup HUD + camera + minimap
2. `update(_:)` — delta time, update player input, update AI tanks, update bullets, update power-ups, check win
3. Bullet collision — same logic as GameScene but with team-based filtering
4. Camera — lerp follow on player's current tank
5. Player death — switch control to next teammate
6. Win — transition to MeleeScoreScene

The code for this scene is too large to write inline. The implementing agent should:
- Model it closely after `GameScene.swift` (683 lines) but with these changes:
  - Replace `player: PlayerTank` + `enemies: [EnemyTank]` with `allTanks: [MeleeTank]` + `controlledTank: MeleeTank?`
  - Replace `levelManager: LevelManager` with `levelManager: MeleeLevelManager`
  - Replace fixed play area coordinates with dynamic `playAreaSize` from `gridSize`
  - Add `worldNode: SKNode` for camera scrolling
  - Add `cameraTarget: CGPoint` + lerp logic
  - Add `hudNode: MeleeHUD` pinned to camera (not world)
  - Add minimap node
  - Bullet collision: check `bullet.teamIndex != tank.teamIndex` instead of `isPlayerBullet`
  - Power-up spawn timer (every 15s, max 3)
  - Win check: count teams with > 0 tanks, if only 1 left → win
  - Player death: find next surviving tank in same team, set `isPlayerControlled = true`

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Scenes/MeleeGameScene.swift
git commit -m "feat(melee): add MeleeGameScene with scrolling camera and multi-team combat"
```

---

### Task 9: MeleeMenuScene — Config Screen

**Files:**
- Create: `BattleCity/Sources/Scenes/MeleeMenuScene.swift`

**Step 1: Create MeleeMenuScene**

Keyboard-driven config screen. Fields:
- Map size selector (16x16 / 20x20 / 26x26 / 30x30)
- Player color selector (Yellow / Red / Blue / Green)
- Per-team: 4 tank type rows, each with count (0-9) and HP (1-9)
- Start Battle button
- Escape → back to MenuScene

Navigation: arrow keys move a cursor between fields. Left/Right adjusts values. Enter starts.

Layout structure:
- `currentField` index tracks which field the cursor is on
- Fields are stored as an array of structs with (label, row, value range, getter/setter)
- Cursor (orange ▸) moves to the current field's Y position

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Scenes/MeleeMenuScene.swift
git commit -m "feat(melee): add MeleeMenuScene config screen"
```

---

### Task 10: MeleeScoreScene — Post-Match Results

**Files:**
- Create: `BattleCity/Sources/Scenes/MeleeScoreScene.swift`

**Step 1: Create MeleeScoreScene**

Displays match results:
- Winner team name + color
- Per-team stats: kills, deaths, survived
- Elimination order
- Player personal kills
- Enter/Escape → return to MeleeMenuScene

```swift
import SpriteKit

struct MeleeMatchResult {
    var winnerTeamIndex: Int
    var teamStats: [TeamMatchStats]
    var eliminationOrder: [Int]  // team indices in order of elimination
    var playerKills: Int
}

struct TeamMatchStats {
    var teamColor: TeamColor
    var kills: Int
    var deaths: Int
    var survived: Int
    var total: Int
}

class MeleeScoreScene: SKScene {
    var matchResult: MeleeMatchResult!
    var meleeConfig: MeleeConfig!

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit

        var y: CGFloat = 30

        // Title
        let title = SKLabelNode(text: "BATTLE RESULTS")
        title.fontName = "Courier-Bold"
        title.fontSize = 12
        title.fontColor = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
        title.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        title.horizontalAlignmentMode = .center
        self.addChild(title)

        y += 20

        // Winner
        let winnerColor = matchResult.teamStats[matchResult.winnerTeamIndex].teamColor
        let winner = SKLabelNode(text: "Winner: \(winnerColor.name) Team!")
        winner.fontName = "Courier-Bold"
        winner.fontSize = 10
        winner.fontColor = .white
        winner.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        winner.horizontalAlignmentMode = .center
        self.addChild(winner)

        y += 20

        // Header
        let header = SKLabelNode(text: "        Kills Deaths Survived")
        header.fontName = "Courier"
        header.fontSize = 6
        header.fontColor = SKColor(white: 0.6, alpha: 1)
        header.position = CGPoint(x: 20, y: y)
        header.horizontalAlignmentMode = .left
        self.addChild(header)

        y += 12

        // Team rows
        for stat in matchResult.teamStats {
            let name = stat.teamColor.name.padding(toLength: 7, withPad: " ", startingAt: 0)
            let text = "\(name)  \(stat.kills)     \(stat.deaths)     \(stat.survived)/\(stat.total)"
            let row = SKLabelNode(text: text)
            row.fontName = "Courier"
            row.fontSize = 6
            row.fontColor = .white
            row.position = CGPoint(x: 20, y: y)
            row.horizontalAlignmentMode = .left
            self.addChild(row)
            y += 10
        }

        y += 10

        // Player stats
        let pStats = SKLabelNode(text: "Your kills: \(matchResult.playerKills)")
        pStats.fontName = "Courier"
        pStats.fontSize = 7
        pStats.fontColor = .white
        pStats.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        pStats.horizontalAlignmentMode = .center
        self.addChild(pStats)

        y += 20

        let instr = SKLabelNode(text: "PRESS ENTER")
        instr.fontName = "Courier"
        instr.fontSize = 6
        instr.fontColor = SKColor(white: 0.5, alpha: 1)
        instr.position = CGPoint(x: Constants.logicalWidth / 2, y: y)
        instr.horizontalAlignmentMode = .center
        self.addChild(instr)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 53: // Enter or Escape
            let scene = MeleeMenuScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
            scene.meleeConfig = meleeConfig
            self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
        default:
            break
        }
    }
}
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Scenes/MeleeScoreScene.swift
git commit -m "feat(melee): add MeleeScoreScene post-match results"
```

---

### Task 11: Add "Melee Mode" Option to Main Menu

**Files:**
- Modify: `BattleCity/Sources/Scenes/MenuScene.swift`

**Step 1: Add melee mode option**

Add a third menu option "MELEE MODE" below "STAGE" in the existing `MenuScene`. When selected and Enter pressed, transition to `MeleeMenuScene`.

Changes:
- Add `opt2` label "MELEE MODE" at y=150
- Update `selectedOption` to support 3 values (0=1Player, 1=Stage, 2=Melee)
- Update `updateCursor()` to handle 3 positions
- Update `keyDown` Enter handler: if selectedOption == 2, go to MeleeMenuScene
- Adjust instruction text

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Scenes/MenuScene.swift
git commit -m "feat(melee): add Melee Mode option to main menu"
```

---

### Task 12: Minimap

**Files:**
- Create: `BattleCity/Sources/HUD/MeleeMinimap.swift`

**Step 1: Create minimap node**

Small overview of the full map in a corner of the HUD. Shows:
- Terrain as tiny colored pixels
- Colored dots for each team's tanks
- Fixed size (e.g. 48x48 pixels) regardless of map size

```swift
import SpriteKit

class MeleeMinimap: SKNode {
    private var minimapSize: CGFloat = 48
    private var background: SKSpriteNode!
    private var dotNodes: [SKSpriteNode] = []
    private var gridSize: Int = 20

    func setup(mapData: [[TileType]], gridSize: Int) {
        self.gridSize = gridSize
        self.zPosition = 200

        // Background
        background = SKSpriteNode(color: SKColor(white: 0.1, alpha: 0.8),
                                   size: CGSize(width: minimapSize + 4, height: minimapSize + 4))
        background.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(background)

        // Draw terrain
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
                dot.position = CGPoint(x: 2 + CGFloat(col) * scale, y: 2 + (minimapSize - CGFloat(row + 1) * scale))
                self.addChild(dot)
            }
        }
    }

    func updateTanks(_ tanks: [MeleeTank]) {
        // Remove old dots
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
```

**Step 2: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 3: Commit**

```bash
git add BattleCity/Sources/HUD/MeleeMinimap.swift
git commit -m "feat(melee): add minimap showing full map and team positions"
```

---

### Task 13: Pathfinder Update for Variable Grid Sizes

**Files:**
- Modify: `BattleCity/Sources/AI/Pathfinder.swift`

**Step 1: Verify Pathfinder works with variable grids**

The existing `Pathfinder.findPath` already uses `grid.count` and `grid[0].count` to determine bounds — it is NOT hardcoded to 13x13. Similarly, `hasLineOfSight` and `nextTileIsBrick` use dynamic bounds.

**No code changes needed** — just verify by reading the code. The Pathfinder already supports arbitrary grid sizes because `MeleeLevelManager.tiles` will be NxN.

**Step 2: Commit (skip if no changes)**

No commit needed.

---

### Task 14: Tile Positioning for Variable Play Areas

**Files:**
- Modify: `BattleCity/Sources/Entities/Tile.swift` (may need update)

**Step 1: Check Tile positioning**

Read `Tile.swift` to see if tile positioning uses hardcoded `Constants.playAreaOriginX/Y`. If tiles use absolute positioning with the 16px/8px offsets from Constants, the melee scene's `worldNode` approach should handle this — tiles are added to `worldNode` with positions relative to (0,0), and the worldNode is positioned/scrolled.

The existing Tile constructor:
```swift
Tile(type: tileType, tileX: col, tileY: row)
```
sets position using `Constants.playAreaOriginX/Y`. For melee mode, tiles should be positioned without the play area offset (since `worldNode` handles that).

**Options:**
- Add a parameter to `Tile.init` for custom origin offsets, OR
- Position tiles in `MeleeLevelManager.loadMap` by overriding after creation

The simpler approach: in `MeleeLevelManager.loadMap`, after creating each tile, override its position to not use the play area origin offset. The tile's `init` sets position with offsets, so reset:

```swift
// In MeleeLevelManager.loadMap, after creating tile:
tile.position = CGPoint(
    x: CGFloat(col) * Constants.tileSize + Constants.tileSize / 2,
    y: playAreaSize - (CGFloat(row) * Constants.tileSize + Constants.tileSize / 2)
)
```

This positions tiles in world-space (Y-up SpriteKit) without the play area origin offset.

Similarly, `MeleeTank.syncSpritePosition()` needs to NOT add `playAreaOriginX/Y` — it should use world-space coordinates. Override `syncSpritePosition` in `MeleeTank`:

```swift
override func syncSpritePosition() {
    let playArea = CGFloat(/* gridSize */) * Constants.tileSize
    self.position = CGPoint(x: gridX, y: playArea - gridY)
}
```

But `MeleeTank` needs to know `gridSize` for this. Store it as a property set during spawn.

**Step 2: Update MeleeTank and MeleeLevelManager**

Update `MeleeTank` to add `var playAreaSize: CGFloat = 0` and override `syncSpritePosition`:

```swift
var meleePlayAreaSize: CGFloat = 0

override func syncSpritePosition() {
    self.position = CGPoint(x: gridX, y: meleePlayAreaSize - gridY)
}
```

Update `MeleeLevelManager.loadMap` tile positioning.

**Step 3: Verify it compiles**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds.

**Step 4: Commit**

```bash
git add BattleCity/Sources/Entities/MeleeTank.swift BattleCity/Sources/Managers/MeleeLevelManager.swift
git commit -m "feat(melee): fix tile and tank positioning for variable-size maps"
```

---

### Task 15: Integration Testing — Build & Play

**Step 1: Full build**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`
Expected: Build succeeds with zero errors.

**Step 2: Fix any compilation errors**

Iterate until the build passes. Common issues:
- Missing imports
- Type mismatches between scenes
- Missing method implementations
- Circular references

**Step 3: Launch and test manually**

Run: `open /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode/build/BattleCity.app`

Test checklist:
- [ ] Main menu shows "1 PLAYER", "STAGE", "MELEE MODE" options
- [ ] Single player mode still works unchanged
- [ ] Melee config screen loads, all fields navigable
- [ ] Default config: 20x20, 5 tanks per team, 3 HP each
- [ ] Start battle → map generates, 4 teams spawn in corners
- [ ] Player controls one tank with arrow keys + space
- [ ] AI tanks move and shoot enemies
- [ ] Bullets don't hit teammates
- [ ] Camera follows player tank, scrolls smoothly
- [ ] Minimap shows tank positions
- [ ] HUD shows team survival counts
- [ ] When player tank dies, control switches to next teammate
- [ ] When player team eliminated, spectator mode
- [ ] Last team standing → score screen
- [ ] Score screen → back to melee config

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix(melee): integration fixes for melee mode"
```

---

### Task 16: Polish & Edge Cases

**Step 1: Handle edge cases**

- Player marker arrow above controlled tank
- Spectator camera auto-follows action
- Power-up spawn timer (15s interval, max 3 on map)
- Bomb power-up: destroy all enemy tanks on screen (visible in viewport)
- Clock power-up: freeze all enemy team tanks for 10s
- Shovel power-up: ignored in melee mode (no eagle to protect) — replace with extra shield
- Tank extra life power-up: respawn a random dead teammate

**Step 2: Verify build**

Run: `cd /Users/andy.zhanggx/projects/tank/.worktrees/feature-chaos-mode && bash build.sh`

**Step 3: Commit**

```bash
git add -A
git commit -m "feat(melee): polish power-ups, spectator mode, and edge cases"
```
