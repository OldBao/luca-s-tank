import SpriteKit

struct MapGenerator {
    static func generate(size: Int) -> [[TileType]] {
        let half = size / 2
        var quadrant = Array(repeating: Array(repeating: TileType.empty, count: half), count: half)

        for row in 0..<half {
            for col in 0..<half {
                if row < 3 && col < 3 { continue }
                let distToCenter = max(half - 1 - row, half - 1 - col)
                if distToCenter < 2 {
                    if Double.random(in: 0...1) < 0.3 { quadrant[row][col] = randomTerrain() }
                    continue
                }
                if Double.random(in: 0...1) < 0.35 { quadrant[row][col] = randomTerrain() }
            }
        }

        var map = Array(repeating: Array(repeating: TileType.empty, count: size), count: size)
        for row in 0..<half {
            for col in 0..<half {
                let t = quadrant[row][col]
                map[row][col] = t
                map[col][size - 1 - row] = t
                map[size - 1 - row][size - 1 - col] = t
                map[size - 1 - col][row] = t
            }
        }

        if !isConnected(map: map, size: size) { return generate(size: size) }
        return map
    }

    private static func randomTerrain() -> TileType {
        let roll = Double.random(in: 0...1)
        if roll < 0.40 { return .brick }
        if roll < 0.65 { return .steel }
        if roll < 0.80 { return .trees }
        if roll < 0.90 { return .water }
        return .ice
    }

    private static func isConnected(map: [[TileType]], size: Int) -> Bool {
        let corners = [(1, 1), (1, size - 2), (size - 2, size - 2), (size - 2, 1)]
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        var queue: [(Int, Int)] = [corners[0]]
        visited[corners[0].0][corners[0].1] = true
        let directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]

        while !queue.isEmpty {
            let (cr, cc) = queue.removeFirst()
            for (dr, dc) in directions {
                let nr = cr + dr; let nc = cc + dc
                guard nr >= 0, nr < size, nc >= 0, nc < size, !visited[nr][nc] else { continue }
                let tile = map[nr][nc]
                if tile == .steel || tile == .water { continue }
                visited[nr][nc] = true
                queue.append((nr, nc))
            }
        }
        for (r, c) in corners { if !visited[r][c] { return false } }
        return true
    }

    static func spawnZones(size: Int) -> [[(Int, Int)]] {
        return [
            [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)],
            [(size-3, 0), (size-2, 0), (size-1, 0), (size-3, 1), (size-2, 1), (size-1, 1), (size-3, 2), (size-2, 2), (size-1, 2)],
            [(size-3, size-3), (size-2, size-3), (size-1, size-3), (size-3, size-2), (size-2, size-2), (size-1, size-2), (size-3, size-1), (size-2, size-1), (size-1, size-1)],
            [(0, size-3), (1, size-3), (2, size-3), (0, size-2), (1, size-2), (2, size-2), (0, size-1), (1, size-1), (2, size-1)],
        ]
    }
}
