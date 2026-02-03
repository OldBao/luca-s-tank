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
    var totalTanks: Int = 5
    var teamConfig: TeamConfig = TeamConfig.defaultConfig(color: .yellow, isPlayer: true)
    var teams: [TeamConfig] = []
    let hpCap: Int = 5

    init() {
        teamConfig = TeamConfig.defaultConfig(color: .yellow, isPlayer: true)
        totalTanks = teamConfig.totalTanks
        teams = buildMirroredTeams()
    }

    var remainingTanks: Int {
        max(0, totalTanks - teamConfig.totalTanks)
    }

    mutating func setPlayerColor(_ color: TeamColor) {
        playerColor = color
        teamConfig.color = color
        teams = buildMirroredTeams()
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
}
