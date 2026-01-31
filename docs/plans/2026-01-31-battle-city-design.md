# Battle City — macOS Native Recreation

## Overview

A pixel-perfect recreation of the classic FC/NES game Battle City (1985) as a native macOS app using Swift and SpriteKit. Single player only. All 35 original levels. Keyboard controls.

## Architecture

**Project:** macOS SpriteKit app, Swift, bundled as `.app`.

**Core pattern:** Entity-Component with SpriteKit scene graph.

- **GameScene** (SKScene) — main game loop, input handling, collision detection
- **Entities** — Player tank, Enemy tanks (4 types), Bullets, Tiles, Power-ups, Eagle
- **LevelManager** — loads and manages all 35 level layouts
- **GameState** — tracks lives, score, current level, enemy queue
- **HUD** — side panel: remaining enemies, player lives, level number

**Game loop:**

1. `update()` — move entities, run enemy AI
2. `didBegin(contact:)` — SpriteKit physics collision detection
3. Render — SpriteKit automatic

**Coordinate system:**

- Logical resolution: 256x224 pixels (NES native)
- Play area: 208x208 pixels (13x13 tiles of 16x16)
- Nearest-neighbor scaling to fill window, letterboxed
- Tanks snap to 8px sub-grid (half-tile) for smooth turning

## Entities & Mechanics

### Player Tank

- 4-directional movement, snaps to 8px sub-grid
- One bullet on screen at a time (upgrades allow two)
- Star power-ups upgrade through 4 tiers:
  1. Faster bullet
  2. Two simultaneous bullets
  3. Can destroy steel walls
  4. All of the above

### Enemy Tanks (4 types)

| Type  | Speed  | Bullet | HP |
|-------|--------|--------|----|
| Basic | Slow   | Slow   | 1  |
| Fast  | High   | Normal | 1  |
| Power | Normal | Fast   | 1  |
| Armor | Normal | Normal | 4  |

- Armor tank flashes different colors per hit remaining
- Flashing enemies drop a power-up when destroyed
- 20 enemies per level, max 4 on screen simultaneously
- 3 fixed spawn points along top of map (left, center, right)

### Power-ups (6 types)

| Power-up | Effect |
|----------|--------|
| Star     | Upgrade player tank tier |
| Tank     | Extra life |
| Shield   | Temporary invincibility |
| Bomb     | Destroy all on-screen enemies |
| Clock    | Freeze all enemies |
| Shovel   | Temporarily fortify eagle with steel walls |

### Tiles (6 types)

| Tile   | Behavior |
|--------|----------|
| Brick  | Destructible, half-tile granularity |
| Steel  | Indestructible (unless player tier 3+) |
| Water  | Blocks tanks, bullets pass over |
| Trees  | Visual cover only, passable |
| Ice    | Tanks slide on movement |
| Eagle  | Base to protect — destroyed = game over |

## Level Data & Progression

### Level format

- 13x13 grid per level
- Bricks subdivided into 4 sub-tiles for partial destruction
- All 35 original layouts hardcoded from documented NES data

### Level flow

1. Stage screen ("STAGE X" on black)
2. Play area loads — eagle bottom center, player spawns bottom-left
3. Enemies spawn in waves from 3 top positions
4. Level complete when all 20 enemies destroyed
5. Score tally screen — breakdown by enemy type
6. Next level loads

### Game over

- Player loses all lives OR eagle destroyed
- "GAME OVER" text rises from bottom (classic animation)

### Progression

- Start with 3 lives
- Tank upgrade resets each level (back to tier 0)
- High score tracked via UserDefaults

## Rendering

- `SKSpriteNode` with `SKTexture` using `.nearest` filtering (no anti-aliasing)
- Original sprites: 16x16 and 8x8 pixel sprite sheets
- Animation: 2-frame tread alternation, 2+2 frame explosion sequence
- Render order (back to front): ice, base tiles, tanks/bullets, trees, HUD
- Window scales 256x224 logical resolution to screen, letterboxed

## Audio

- `SKAction.playSoundFileNamed` for all sound effects
- Effects: shoot, hit brick, hit steel, explosion (small/large), power-up pickup, enemy spawn, level start jingle, game over, bonus life
- No background music (faithful to original)
- Audio files as `.wav` in app bundle

## Enemy AI

### Movement

- Pick random direction, move until obstacle
- On collision: pick new random direction
- Random timer for spontaneous direction changes
- ~50% bias toward moving downward (toward eagle)

### Firing

- Fire at random intervals (varies by enemy type)
- One bullet per enemy on screen

### Spawning

- Cycle through 3 spawn points in order
- New spawn when on-screen count < 4 (with flash animation)
- 20 enemies total per level
- Enemy composition varies per level (more armor tanks later)
- Flashing (power-up) enemies at fixed queue positions (4, 11, 18)

## Input

- Arrow keys: move
- Space: fire
- Enter: start game / pause
- Keyboard only, no gamepad

## Tech Stack

- Swift
- SpriteKit
- macOS native `.app`
- Xcode project
