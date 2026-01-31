import SpriteKit

struct Constants {
    // NES native resolution
    static let logicalWidth: CGFloat = 256
    static let logicalHeight: CGFloat = 224

    // Play area (13x13 tiles)
    static let playAreaTiles = 13
    static let tileSize: CGFloat = 16
    static let subTileSize: CGFloat = 8
    static let playAreaSize: CGFloat = CGFloat(playAreaTiles) * tileSize  // 208

    // Play area origin (offset from left edge to center in logical space)
    static let playAreaOriginX: CGFloat = 16
    static let playAreaOriginY: CGFloat = 8

    // Grid snapping
    static let snapSize: CGFloat = 8  // half-tile for smooth turning

    // Tank properties
    static let playerSpeed: CGFloat = 60       // pixels per second (slow)
    static let playerFastSpeed: CGFloat = 75
    static let basicEnemySpeed: CGFloat = 30
    static let fastEnemySpeed: CGFloat = 60
    static let powerEnemySpeed: CGFloat = 40
    static let armorEnemySpeed: CGFloat = 40

    // Bullet speeds
    static let bulletSlowSpeed: CGFloat = 120
    static let bulletNormalSpeed: CGFloat = 160
    static let bulletFastSpeed: CGFloat = 200

    // Game rules
    static let startingLives = 3
    static let maxEnemiesOnScreen = 4
    static let totalEnemiesPerLevel = 20
    static let maxPlayerBullets = 1       // tier 0-1
    static let maxPlayerBulletsTier2 = 2  // tier 2+

    // Spawn points (tile coordinates)
    static let playerSpawnTile = CGPoint(x: 4, y: 12)
    static let enemySpawnTiles: [CGPoint] = [
        CGPoint(x: 0, y: 0),
        CGPoint(x: 6, y: 0),
        CGPoint(x: 12, y: 0)
    ]
    static let eagleTile = CGPoint(x: 6, y: 12)

    // Timing
    static let shieldDuration: TimeInterval = 10.0
    static let freezeDuration: TimeInterval = 10.0
    static let shovelDuration: TimeInterval = 15.0
    static let steelBreakerDuration: TimeInterval = 15.0
    static let spawnAnimDuration: TimeInterval = 1.0
    static let explosionDuration: TimeInterval = 0.3
    static let stageIntroDuration: TimeInterval = 2.0
    static let gameOverRiseDuration: TimeInterval = 2.0

    // Scoring
    static let scoreBasic = 100
    static let scoreFast = 200
    static let scorePower = 300
    static let scoreArmor = 400

    // Window
    static let windowScale: CGFloat = 3.0
    static let windowWidth: CGFloat = logicalWidth * windowScale
    static let windowHeight: CGFloat = logicalHeight * windowScale
}
