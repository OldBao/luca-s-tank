import Foundation

@main
struct MeleeConfigTests {
    static func main() {
        var config = MeleeConfig()
        config.totalTanks = 5
        // Default counts 2/1/1/1, HP 3
        assertEqual(config.remainingTanks, 0, "remaining default")

        // Cannot exceed total
        let didAdd = config.adjustCount(for: .basic, delta: 1)
        assertEqual(didAdd, false, "reject count > total")

        // Increasing total allows increment
        config.adjustTotalTanks(to: 6, lastEdited: .basic)
        let didAddAfter = config.adjustCount(for: .basic, delta: 1)
        assertEqual(didAddAfter, true, "allow count after total increase")

        // HP clamp
        config.adjustHP(for: .armor, delta: 10)
        assertEqual(config.teamConfig.tanks[.armor]?.hp ?? 0, 5, "hp capped")

        // Mirror teams
        let mirrored = config.buildMirroredTeams()
        assertEqual(mirrored.count, 4, "mirrors 4 teams")
        assertEqual(mirrored[1].tanks[.basic]?.count ?? 0,
                    config.teamConfig.tanks[.basic]?.count ?? 0,
                    "mirror counts")

        print("OK")
    }
}

func assertEqual<T: Equatable>(_ value: T, _ expected: T, _ message: String) {
    if value != expected {
        print("FAIL: \(message) expected \(expected), got \(value)")
        exit(1)
    }
}
