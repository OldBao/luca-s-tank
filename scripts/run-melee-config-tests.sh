#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.tmp/melee_config_tests"

mkdir -p "$ROOT/.tmp"

swiftc \
  -target arm64-apple-macos13.0 \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -framework SpriteKit \
  -framework Cocoa \
  -framework AVFoundation \
  -o "$BIN" \
  "$ROOT/Tests/MeleeConfigTests.swift" \
  "$ROOT/BattleCity/Sources/Data/MeleeConfig.swift" \
  "$ROOT/BattleCity/Sources/Data/Constants.swift" \
  "$ROOT/BattleCity/Sources/Entities/Direction.swift"

"$BIN"
