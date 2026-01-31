import Foundation

class GameState {
    var currentLevel: Int = 1
    var lives: Int = Constants.startingLives
    var score: Int = 0
    var highScore: Int = 0
    var isGameOver: Bool = false
    var isPaused: Bool = false

    // Per-level tracking
    var enemiesRemaining: Int = Constants.totalEnemiesPerLevel
    var enemiesOnScreen: Int = 0
    var enemyQueue: [EnemyType] = []
    var enemyQueueIndex: Int = 0
    var nextSpawnPointIndex: Int = 0

    // Score tally per enemy type this level
    var killsByType: [EnemyType: Int] = [:]

    // Power-up states
    var freezeTimer: TimeInterval = 0
    var shovelTimer: TimeInterval = 0
    var isFrozen: Bool { freezeTimer > 0 }
    var isShovelActive: Bool { shovelTimer > 0 }

    init() {
        highScore = UserDefaults.standard.integer(forKey: "highScore")
    }

    func startLevel(_ level: Int) {
        currentLevel = level
        enemiesOnScreen = 0
        enemyQueueIndex = 0
        nextSpawnPointIndex = 0
        freezeTimer = 0
        shovelTimer = 0
        killsByType = [:]
        buildEnemyQueue()
        enemiesRemaining = enemyQueue.count
    }

    func buildEnemyQueue() {
        let levelIndex = (currentLevel - 1) % LevelData.enemyComposition.count
        let comp = LevelData.enemyComposition[levelIndex]
        var queue: [EnemyType] = []

        for (typeIndex, count) in comp.enumerated() {
            if let t = EnemyType(rawValue: typeIndex) {
                queue.append(contentsOf: Array(repeating: t, count: count))
            }
        }

        // Shuffle but keep some structure
        queue.shuffle()
        enemyQueue = queue
    }

    func nextEnemy() -> (type: EnemyType, isFlashing: Bool)? {
        guard enemyQueueIndex < enemyQueue.count else { return nil }
        let type = enemyQueue[enemyQueueIndex]
        let flashing = LevelData.flashingEnemyPositions.contains(enemyQueueIndex)
        enemyQueueIndex += 1
        return (type, flashing)
    }

    func getSpawnPoint() -> CGPoint {
        let point = Constants.enemySpawnTiles[nextSpawnPointIndex % Constants.enemySpawnTiles.count]
        nextSpawnPointIndex += 1
        return point
    }

    func enemyDestroyed(type: EnemyType) {
        enemiesOnScreen -= 1
        enemiesRemaining -= 1
        score += type.score
        killsByType[type, default: 0] += 1

        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }

    func playerDied() {
        lives -= 1
        if lives < 0 {
            isGameOver = true
        }
    }

    func addLife() {
        lives += 1
    }

    func isLevelComplete() -> Bool {
        return enemiesRemaining <= 0 && enemiesOnScreen <= 0
    }

    func canSpawnEnemy() -> Bool {
        return enemiesOnScreen < Constants.maxEnemiesOnScreen && enemyQueueIndex < enemyQueue.count
    }

    func updateTimers(dt: TimeInterval) {
        if freezeTimer > 0 { freezeTimer -= dt }
        if shovelTimer > 0 { shovelTimer -= dt }
    }

    func reset() {
        currentLevel = 1
        lives = Constants.startingLives
        score = 0
        isGameOver = false
        isPaused = false
    }
}
