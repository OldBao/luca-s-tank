# Melee Mode Design

## Overview

A new "Melee Mode" alongside the existing single-player mode. 4 teams fight on a procedurally generated map — last team standing wins. The original single-player mode remains completely untouched.

## Game Concept

- 4 teams, each with configurable tank composition and HP per type
- No eagle/base — victory by elimination (last team with tanks alive wins)
- Player controls one tank on their team; teammates are AI-controlled
- When player's tank is destroyed, control passes to next surviving teammate
- If entire player team is eliminated, switch to spectator mode
- Map size configurable, procedurally generated with random terrain
- Power-ups spawn at random locations on a timer
- Each team has a distinct color; player picks theirs, AI gets the remaining three

## Game Flow

1. Main menu → choose "Single Player" or "Melee Mode"
2. Melee config screen → set map size, pick color, configure each team's tank composition and HP
3. Match starts → 4 teams spawn in corners
4. Play until 3 teams eliminated
5. Score screen with stats → back to melee config menu

## New Files

Keep all existing single-player code untouched. New files:

- `Scenes/MeleeMenuScene.swift` — melee config UI
- `Scenes/MeleeGameScene.swift` — melee gameplay scene (standalone, not inheriting GameScene)
- `Scenes/MeleeScoreScene.swift` — post-match stats screen
- `Data/MeleeConfig.swift` — data structure for match settings
- `Managers/MapGenerator.swift` — procedural map generation
- `Entities/TeamTank.swift` — melee-mode tank with team affiliation, configurable HP, color tinting

Existing `MenuScene.swift` gets one new menu option: "Melee Mode".

## Config Screen

Keyboard-driven, same style as existing menu.

```
=== MELEE MODE ===

Map Size:  [ 20x20 ]       (options: 16x16, 20x20, 26x26, 30x30)

Your Color: [ Yellow ]      (Yellow, Red, Blue, Green)

--- Team 1 (You) - Yellow ---
Basic:  2  HP: 3
Fast:   1  HP: 2
Power:  1  HP: 3
Armor:  1  HP: 5

--- Team 2 (AI) - Red ---
Basic:  2  HP: 3
Fast:   1  HP: 2
Power:  1  HP: 3
Armor:  1  HP: 5

--- Team 3 (AI) - Blue ---
(same format)

--- Team 4 (AI) - Green ---
(same format)

[Start Battle]
```

Controls:
- Arrow keys to navigate between fields
- Left/Right to adjust values
- Enter to start the match
- Escape to go back to main menu

Defaults: 20x20 map, each team gets 2 Basic + 1 Fast + 1 Power + 1 Armor, all 3 HP.

## Map Generation

Procedural generation rules:

- Grid is NxN tiles (based on config). Each tile is 16x16 pixels.
- **4 spawn zones** — one in each corner, a 3x3 clear area guaranteed empty for each team.
- **4-way rotational symmetry** — no team has terrain advantage.
- **Terrain distribution** (approximate):
  - 30% open ground
  - 25% brick walls (destructible)
  - 15% steel walls (indestructible)
  - 10% trees (visual cover, bullets pass through)
  - 10% water (impassable)
  - 10% ice (slippery movement)
- **Connectivity** — BFS check after generation to guarantee paths between all 4 spawn zones. Regenerate if disconnected.
- **Central area** — slightly more open to encourage mid-map fights.

## Power-ups

- One power-up appears every 15 seconds at a random open tile
- Max 3 power-ups on the map at once
- All 6 types available: Star, Tank (extra life), Shield, Bomb, Clock, Shovel
- **Bomb in melee**: destroys all enemy tanks currently on screen (from picker's perspective)
- **Shovel in melee**: temporarily fortifies area around picking team's surviving tanks with steel

## Tank Types & Combat

### Tank Types

| Type  | Speed  | Bullets | Special        | AI Behavior                                      |
|-------|--------|---------|----------------|--------------------------------------------------|
| Basic | Slow   | 1       | —              | Random wander, shoots nearby enemies              |
| Fast  | High   | 1       | —              | Hunts nearest enemy tank                          |
| Power | Normal | 1       | Destroys steel | Hunts nearest enemy, clears walls in path         |
| Armor | Normal | 2       | Destroys steel | Targets weakest enemy team's tanks                |

### HP & Damage

- HP per tank type is configurable (set in config screen)
- Every bullet does 1 damage regardless of source
- No friendly fire — bullets pass through teammates

### Color Tinting

- 4 colors: Yellow, Red, Blue, Green
- Applied as color multiply on existing tank sprites
- Player's current tank has a small arrow indicator above it

### Player Control Switching

- When player's tank is destroyed, camera briefly shows explosion, then snaps to next surviving teammate
- If entire player team eliminated, switch to spectator mode — camera auto-follows largest ongoing fight

## AI Targeting (Multi-Team)

- Each AI tank picks a target from enemy teams (not its own)
- **Basic**: wanders randomly, shoots at any enemy within line of sight
- **Fast**: pathfinds to nearest enemy tank across all enemy teams
- **Power**: pathfinds to nearest enemy, prefers breaking walls to create paths
- **Armor**: targets team with fewest remaining tanks, picks closest tank in that team
- Pathfinder reuses existing BFS on larger NxN grid
- Recalculation intervals: 0.8s (Fast) to 1.5s (Power)

## HUD

```
┌──────────────────────────────┐
│  Yellow: ██████ 4/5          │  (your team, always top)
│  Red:    ████   3/5          │
│  Blue:   ██████ 4/5          │
│  Green:  ██     2/5          │
│                              │
│         [match area]         │
│                              │
└──────────────────────────────┘
```

- Team bars show surviving/total tanks per team
- Eliminated teams grayed out
- Current player tank has small marker above it

## Camera & Viewport

- Viewport stays at 256x224 logical pixels (same rendering pipeline as single-player)
- Camera centers on player's current tank
- Smooth follow with lerp (0.1 per frame)
- Camera clamps at map edges
- In spectator mode, camera auto-follows largest ongoing fight
- **Minimap** in corner showing full map with colored dots per team

## Score Screen

```
=== BATTLE RESULTS ===

Winner: Yellow Team!

        Kills   Deaths   Survived
Yellow    12      1        4/5
Red        8      5        0/5
Blue       6      5        0/5
Green      4      5        0/5

Elimination order: Green → Blue → Red

Your stats:
  Personal kills: 7
  Deaths: 1

[Back to Menu]
```

- Teams ranked by elimination order (winner first)
- Player's personal kills tracked separately
- Enter or Escape returns to melee config menu
