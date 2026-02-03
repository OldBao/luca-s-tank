# Melee Config Mirroring + HP Hearts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add melee menu tank composition with a configurable total, mirrored AI teams, and HP hearts above all tanks (1 heart = 1 HP, max 5).

**Architecture:** Extend `MeleeConfig` with a single player-team configuration and helpers to enforce totals/HP caps. The menu drives that config, then the game scene mirrors it into four runtime teams. Each `MeleeTank` owns a small `HPIndicator` node that renders heart icons above the tank and updates on damage.

**Tech Stack:** Swift, SpriteKit, macOS app built via `build.sh`.

### Task 1: Add a Lightweight Config Test Harness

**Files:**
- Create: `scripts/run-melee-config-tests.sh`
- Create: `Tests/MeleeConfigTests.swift`

**Step 1: Write failing tests for new MeleeConfig helpers**

```swift
import Foundation

@main
struct MeleeConfigTests {
    static func main() {
        var config = MeleeConfig()
        config.totalTanks = 5
        // Default counts 2/1/1/1, HP 3
        assertEqual(config.remainingTanks, 0, "remaining default")

        // Cannot exceed total
        let didAdd = config.adjustCount(for: .basic, delta: 1)
        assertEqual(didAdd, false, "reject count > total")

        // Increasing total allows increment
        config.adjustTotalTanks(to: 6, lastEdited: .basic)
        let didAddAfter = config.adjustCount(for: .basic, delta: 1)
        assertEqual(didAddAfter, true, "allow count after total increase")

        // HP clamp
        config.adjustHP(for: .armor, delta: 10)
        assertEqual(config.teamConfig.tanks[.armor]?.hp ?? 0, 5, "hp capped")

        // Mirror teams
        let mirrored = config.buildMirroredTeams()
        assertEqual(mirrored.count, 4, "mirrors 4 teams")
        assertEqual(mirrored[1].tanks[.basic]?.count ?? 0, config.teamConfig.tanks[.basic]?.count ?? 0, "mirror counts")

        print("OK")
    }
}

func assertEqual<T: Equatable>(_ value: T, _ expected: T, _ message: String) {
    if value != expected {
        print("FAIL: \(message) expected \(expected), got \(value)")
        exit(1)
    }
}
```

**Step 2: Run tests to confirm failure**

Run: `scripts/run-melee-config-tests.sh`
Expected: FAIL (missing `remainingTanks`, `adjustCount`, `adjustHP`, `adjustTotalTanks`, `buildMirroredTeams`).

**Step 3: Commit**

```bash
git add scripts/run-melee-config-tests.sh Tests/MeleeConfigTests.swift
git commit -m "test: add melee config test harness"
```

### Task 2: Implement MeleeConfig Helpers and Mirroring

**Files:**
- Modify: `BattleCity/Sources/Data/MeleeConfig.swift`

**Step 1: Implement the new API to satisfy tests**

```swift
struct MeleeConfig {
    var mapSize: MapSize = .medium
    var playerColor: TeamColor = .yellow
    var totalTanks: Int = 5
    var teamConfig: TeamConfig = TeamConfig.defaultConfig(color: .yellow, isPlayer: true)
    let hpCap: Int = 5

    var remainingTanks: Int {
        max(0, totalTanks - teamConfig.totalTanks)
    }

    mutating func adjustCount(for type: EnemyType, delta: Int) -> Bool {
        guard var cfg = teamConfig.tanks[type] else { return false }
        let newCount = max(0, cfg.count + delta)
        let newTotal = teamConfig.totalTanks - cfg.count + newCount
        guard newTotal <= totalTanks else { return false }
        cfg.count = newCount
        teamConfig.tanks[type] = cfg
        return true
    }

    mutating func adjustHP(for type: EnemyType, delta: Int) {
        guard var cfg = teamConfig.tanks[type] else { return }
        cfg.hp = max(1, min(hpCap, cfg.hp + delta))
        teamConfig.tanks[type] = cfg
    }

    mutating func adjustTotalTanks(to newTotal: Int, lastEdited: EnemyType?) {
        totalTanks = max(1, newTotal)
        guard teamConfig.totalTanks > totalTanks else { return }
        reduceCountsToFit(prefer: lastEdited)
    }

    mutating func reduceCountsToFit(prefer: EnemyType?) {
        let order: [EnemyType] = [.basic, .fast, .power, .armor]
        var types = order
        if let prefer = prefer, let idx = types.firstIndex(of: prefer) {
            types.remove(at: idx)
            types.insert(prefer, at: 0)
        }
        while teamConfig.totalTanks > totalTanks {
            for type in types {
                if var cfg = teamConfig.tanks[type], cfg.count > 0 {
                    cfg.count -= 1
                    teamConfig.tanks[type] = cfg
                    break
                }
            }
        }
    }

    func buildMirroredTeams() -> [TeamConfig] {
        let otherColors = TeamColor.allCases.filter { $0 != playerColor }
        return [
            TeamConfig(color: playerColor, isPlayer: true, tanks: teamConfig.tanks),
            TeamConfig(color: otherColors[0], isPlayer: false, tanks: teamConfig.tanks),
            TeamConfig(color: otherColors[1], isPlayer: false, tanks: teamConfig.tanks),
            TeamConfig(color: otherColors[2], isPlayer: false, tanks: teamConfig.tanks)
        ]
    }

    mutating func setPlayerColor(_ color: TeamColor) {
        playerColor = color
        teamConfig.color = color
    }
}
```

**Step 2: Run tests**

Run: `scripts/run-melee-config-tests.sh`
Expected: PASS with `OK`.

**Step 3: Commit**

```bash
git add BattleCity/Sources/Data/MeleeConfig.swift
git commit -m "feat: add melee config helpers and mirroring"
```

### Task 3: Update Melee Menu UI to Configure Composition

**Files:**
- Modify: `BattleCity/Sources/Scenes/MeleeMenuScene.swift`

**Step 1: Update fields and labels**

```swift
private enum Field {
    case mapSize, playerColor, totalTanks
    case basicCount, basicHP
    case fastCount, fastHP
    case powerCount, powerHP
    case armorCount, armorHP
    case start
}

private let fields: [Field] = [
    .mapSize, .playerColor, .totalTanks,
    .basicCount, .basicHP,
    .fastCount, .fastHP,
    .powerCount, .powerHP,
    .armorCount, .armorHP,
    .start
]
```

**Step 2: Render counts/HP per row and remaining**

```swift
remainingLabel.text = "Remaining: \(meleeConfig.remainingTanks)"
rowLabels[.basicCount]?.text = "Basic: \(count(.basic))"
rowLabels[.basicHP]?.text = "HP: \(hp(.basic))"
```

**Step 3: Adjust values via MeleeConfig helpers**

```swift
case .totalTanks:
    meleeConfig.adjustTotalTanks(to: meleeConfig.totalTanks + delta, lastEdited: lastEditedType)
case .basicCount:
    if meleeConfig.adjustCount(for: .basic, delta: delta) { lastEditedType = .basic }
case .basicHP:
    meleeConfig.adjustHP(for: .basic, delta: delta)
```

**Step 4: Manual verification**

Run: `./build.sh && open build/BattleCity.app`
Expected:
- Total/Remaining updates correctly
- Counts never exceed total
- HP clamped to 1..5
- Start Battle launches match

**Step 5: Commit**

```bash
git add BattleCity/Sources/Scenes/MeleeMenuScene.swift
git commit -m "feat: add melee menu tank composition"
```

### Task 4: Mirror Teams at Match Start

**Files:**
- Modify: `BattleCity/Sources/Scenes/MeleeMenuScene.swift`
- Modify: `BattleCity/Sources/Scenes/MeleeGameScene.swift`
- Modify: `BattleCity/Sources/HUD/MeleeHUD.swift`

**Step 1: Build mirrored teams before starting match**

```swift
meleeConfig.teams = meleeConfig.buildMirroredTeams()
```

**Step 2: Ensure HUD totals use mirrored teams**

```swift
teamTotals = config.teams.map { $0.totalTanks }
```

**Step 3: Manual verification**

Run: `./build.sh && open build/BattleCity.app`
Expected: All teams have identical counts/HP as player config.

**Step 4: Commit**

```bash
git add BattleCity/Sources/Scenes/MeleeMenuScene.swift \
       BattleCity/Sources/Scenes/MeleeGameScene.swift \
       BattleCity/Sources/HUD/MeleeHUD.swift
git commit -m "feat: mirror melee team config at start"
```

### Task 5: Add HP Heart Indicators Above Tanks

**Files:**
- Create: `BattleCity/Sources/Entities/HPIndicator.swift`
- Modify: `BattleCity/Sources/Managers/SpriteManager.swift`
- Modify: `BattleCity/Sources/Entities/MeleeTank.swift`

**Step 1: Add a heart texture generator**

```swift
func hudHeartIcon() -> SKTexture {
    return textureCache["hud_heart"]!
}

private func generateHUDHeartIcon() -> SKTexture {
    guard let ctx = createContext(width: 6, height: 6) else { return SKTexture() }
    ctx.clear(CGRect(x: 0, y: 0, width: 6, height: 6))
    let red = NESColors.red
    // simple 6x6 heart
    fillRect(ctx, x: 1, y: 3, w: 1, h: 1, color: red)
    fillRect(ctx, x: 4, y: 3, w: 1, h: 1, color: red)
    fillRect(ctx, x: 0, y: 2, w: 2, h: 2, color: red)
    fillRect(ctx, x: 4, y: 2, w: 2, h: 2, color: red)
    fillRect(ctx, x: 1, y: 1, w: 4, h: 2, color: red)
    fillRect(ctx, x: 2, y: 0, w: 2, h: 1, color: red)
    return textureFromContext(ctx)
}
```

**Step 2: Create HPIndicator node**

```swift
final class HPIndicator: SKNode {
    private var hearts: [SKSpriteNode] = []

    func update(hp: Int) {
        let count = max(0, min(5, hp))
        if hearts.count != count {
            hearts.forEach { $0.removeFromParent() }
            hearts = []
            for i in 0..<count {
                let heart = SKSpriteNode(texture: SpriteManager.shared.hudHeartIcon())
                heart.size = CGSize(width: 6, height: 6)
                heart.position = CGPoint(x: CGFloat(i) * 7, y: 0)
                addChild(heart)
                hearts.append(heart)
            }
        }
    }
}
```

**Step 3: Attach and update in MeleeTank**

```swift
private let hpIndicator = HPIndicator()

init(...) {
    ...
    addChild(hpIndicator)
    hpIndicator.position = CGPoint(x: -CGFloat(hp - 1) * 3, y: Constants.tileSize / 2 + 4)
    hpIndicator.zPosition = 30
    hpIndicator.update(hp: hp)
}

override func takeDamage() -> Bool {
    hp -= 1
    updateTexture()
    hpIndicator.update(hp: hp)
    return hp <= 0
}
```

**Step 4: Manual verification**

Run: `./build.sh && open build/BattleCity.app`
Expected: Hearts appear above all tanks and decrement on hits.

**Step 5: Commit**

```bash
git add BattleCity/Sources/Entities/HPIndicator.swift \
       BattleCity/Sources/Managers/SpriteManager.swift \
       BattleCity/Sources/Entities/MeleeTank.swift
git commit -m "feat: show hp hearts above melee tanks"
```

### Task 6: Final Manual Verification

**Step 1: Full run-through**

Run: `./build.sh && open build/BattleCity.app`
Expected:
- Menu allows per-type counts + HP, total/remaining enforced
- AI teams mirror player setup
- Hearts render above all tanks and update on damage

**Step 2: Commit any final tweaks**

```bash
git add -A
git commit -m "fix: polish melee config and hp hearts"
```
