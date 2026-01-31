# Enemy AI Design — Per-Type Intelligence

## Overview

Replace the current random enemy AI with per-type behavior profiles. Each enemy type has a distinct intelligence level and combat role, creating natural difficulty scaling through level composition.

## Enemy Behavior Profiles

| Type | Role | Pathfinding | Firing | Brick Breaking |
|------|------|-------------|--------|----------------|
| Basic | Cannon fodder | None (random + 50% downward bias) | Random timer | No |
| Fast | Player hunter | BFS to player, recalc every ~0.8s | Line-of-sight to player only | No |
| Power | Eagle assassin | BFS to eagle, recalc every ~1.5s | Clears bricks in path + LOS | Yes |
| Armor | Smart all-rounder | BFS to closer of player/eagle, recalc every ~1.2s | Clears bricks + LOS to both | Yes |

## Architecture

Two additions to the codebase:

### Pathfinder.swift

A stateless struct with one static method:

```swift
static func findPath(from: (Int,Int), to: (Int,Int), grid: [[Tile?]], canBreakBricks: Bool) -> [(Int,Int)]
```

- Standard BFS on the 13x13 tile grid (169 cells max).
- Empty, ice, trees are passable. Steel and water are impassable.
- Bricks: impassable when `canBreakBricks = false`, passable when `true`.
- Returns array of `(col, row)` waypoints excluding start. Empty if no path.
- Pure function, no state. Called per-enemy at their recalc interval.
- At 4 enemies max x ~1 call/second = negligible cost.

### EnemyTank.swift Modifications

New properties:
- `aiBehavior: AIBehavior` — enum `.wander`, `.huntPlayer`, `.huntEagle`, `.smartHunter`, set from `EnemyType` in init
- `currentPath: [(Int,Int)]` — current waypoint list
- `pathRecalcTimer: TimeInterval` — time since last pathfind
- `pathRecalcInterval: TimeInterval` — varies by behavior (0.8s, 1.2s, 1.5s)

New on `Bullet`:
- `ownerID: ObjectIdentifier?` — tracks which tank fired the bullet, so smart enemies know if their bullet is still in flight

### updateAI dispatch

`updateAI` dispatches to behavior-specific methods:
- `.wander` — Current random logic, unchanged
- `.huntPlayer` — Pathfind to player, follow waypoints, LOS firing
- `.huntEagle` — Pathfind to eagle, clear bricks in path, LOS firing
- `.smartHunter` — Pathfind to closer target, combined firing logic

## Pathfinding Behavior

Each frame for smart enemies:
1. Increment `pathRecalcTimer`. If exceeded interval, recalculate BFS path.
2. If `currentPath` is non-empty, set `direction` toward next waypoint.
3. When within ~2px of a waypoint, pop it and aim for the next.
4. On collision (wall or tank), immediately recalculate path.
5. If no path found, fall back to `.wander` behavior.

## Firing Logic

### Line-of-Sight Check

`hasLineOfSight(from:direction:targetTile:grid:) -> Bool`

Walk tiles in the facing direction from the enemy's tile. If you reach the target tile before hitting a wall/boundary, return true. Max 13 iterations.

### Firing Decision Matrix

| Condition | Basic | Fast | Power | Armor |
|-----------|-------|------|-------|-------|
| Random timer expired | Fire | - | - | - |
| Player in LOS | - | Fire | Fire | Fire |
| Eagle in LOS | - | - | Fire | Fire |
| Next path tile is brick & facing it | - | - | Fire | Fire |
| Own bullet still in flight | Ignore | Don't fire | Don't fire | Don't fire |

Smart tanks fire fewer but more intentional shots. Power tanks carve paths to the eagle. Fast tanks ambush the player.

## Files to Create/Modify

- **Create:** `BattleCity/Sources/AI/Pathfinder.swift`
- **Modify:** `BattleCity/Sources/Entities/EnemyTank.swift` — add behavior profiles, pathfinding state, behavior-specific update methods
- **Modify:** `BattleCity/Sources/Entities/Bullet.swift` — add `ownerID` property
- **Modify:** `BattleCity/Sources/Scenes/GameScene.swift` — pass `ownerID` when creating enemy bullets, pass `levelManager` tiles to AI methods
