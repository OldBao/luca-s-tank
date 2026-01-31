import SpriteKit

enum Direction: Int, CaseIterable {
    case up = 0, right = 1, down = 2, left = 3

    var vector: CGVector {
        switch self {
        case .up:    return CGVector(dx: 0, dy: -1)
        case .down:  return CGVector(dx: 0, dy: 1)
        case .left:  return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        }
    }

    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var isHorizontal: Bool {
        self == .left || self == .right
    }

    var isVertical: Bool {
        self == .up || self == .down
    }
}

enum EnemyType: Int, CaseIterable {
    case basic = 0, fast = 1, power = 2, armor = 3

    var speed: CGFloat {
        switch self {
        case .basic: return Constants.basicEnemySpeed
        case .fast:  return Constants.fastEnemySpeed
        case .power: return Constants.powerEnemySpeed
        case .armor: return Constants.armorEnemySpeed
        }
    }

    var bulletSpeed: CGFloat {
        switch self {
        case .basic: return Constants.bulletSlowSpeed
        case .fast:  return Constants.bulletNormalSpeed
        case .power: return Constants.bulletFastSpeed
        case .armor: return Constants.bulletNormalSpeed
        }
    }

    var maxHP: Int {
        switch self {
        case .basic, .fast, .power: return 1
        case .armor: return 4
        }
    }

    var score: Int {
        switch self {
        case .basic: return Constants.scoreBasic
        case .fast:  return Constants.scoreFast
        case .power: return Constants.scorePower
        case .armor: return Constants.scoreArmor
        }
    }
}

enum PowerUpType: Int, CaseIterable {
    case star = 0, tank = 1, shield = 2, bomb = 3, clock = 4, shovel = 5, steelBreaker = 6
}

enum TileType: Int, CaseIterable {
    case empty = 0, brick = 1, steel = 2, water = 3, trees = 4, ice = 5
}

enum ExplosionSize {
    case small, large
}
