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
    case small = 16
    case medium = 20
    case large = 26
    case huge = 30

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

    mutating func setPlayerColor(_ color: TeamColor) {
        playerColor = color
        let otherColors = TeamColor.allCases.filter { $0 != color }
        teams[0] = TeamConfig.defaultConfig(color: color, isPlayer: true)
        for i in 1..<4 {
            teams[i] = TeamConfig.defaultConfig(color: otherColors[i - 1], isPlayer: false)
        }
    }
}
