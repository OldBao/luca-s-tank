# Melee Config Mirroring + HP Hearts Design

## Overview

Add two melee-mode features:

- Configurable total tanks for the player team, with AI teams mirroring the same composition and HP.
- HP displayed above all tanks as hearts (1 heart = 1 HP), capped at 5.

Single-player mode remains untouched.

## Requirements

- Main menu melee config shows a single team setup for the player.
- AI teams mirror player composition and HP at match start.
- A `Total Tanks` field is configurable.
- A `Remaining` counter prevents total counts exceeding `Total Tanks`.
- Per-type HP is configurable and capped at 5.
- HP is shown above all tanks as heart icons.

## UI / Interaction

Config screen layout:

```
=== MELEE MODE ===

Map Size:     [ 20x20 ]
Your Color:   [ Yellow ]
Total Tanks:  [ 5 ]   Remaining: 0

--- Your Team (Mirrored to AI) ---
Basic:  2   HP: 3
Fast:   1   HP: 2
Power:  1   HP: 3
Armor:  1   HP: 5

[Start Battle]
```

Controls:
- Up/Down moves between fields.
- Left/Right adjusts the selected value.
- Each tank row has two focusable fields: Count and HP.
- Count increases are blocked when `Remaining` is 0.
- HP is clamped to 1..5.

`Total Tanks` changes:
- Increasing adds capacity without changing current counts.
- Decreasing below current sum auto-reduces counts in stable order: Basic -> Fast -> Power -> Armor, starting from the last-edited type.

## Data Model

`MeleeConfig` additions:
- `totalTanks: Int`
- `teamConfig: TeamConfig` (counts + HP per type)
- `hpCap: Int = 5`

Validation helpers:
- `remainingTanks = totalTanks - sum(counts)`
- `clampCounts()` and `clampHp()` prevent invalid state.

## Game Setup

At match start:
- Build player team from `teamConfig`.
- Clone `teamConfig` to AI teams (same counts and HP).
- Keep runtime team stats separate for kills/deaths.

## HP Rendering

- Add an `HPIndicator` SKNode that attaches above each `MeleeTank`.
- Render 1..5 heart sprites based on current HP.
- Update on damage and on spawn.

## Testing

- UI: Verify total/remaining logic with count adjustments.
- Config: HP clamped at 1..5.
- Game: AI teams mirror player setup.
- Rendering: hearts show above all tanks and update after damage.
