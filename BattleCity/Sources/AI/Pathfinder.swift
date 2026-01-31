import Foundation

struct Pathfinder {
    /// BFS pathfinding on the 13x13 tile grid.
    /// Returns array of (col, row) waypoints from start to target, excluding start.
    /// Empty array if no path found.
    static func findPath(
        from start: (Int, Int),
        to target: (Int, Int),
        grid: [[Tile?]],
        canBreakBricks: Bool
    ) -> [(Int, Int)] {
        let rows = grid.count
        guard rows > 0 else { return [] }
        let cols = grid[0].count

        let (sc, sr) = start
        let (tc, tr) = target

        guard sc >= 0, sc < cols, sr >= 0, sr < rows,
              tc >= 0, tc < cols, tr >= 0, tr < rows else { return [] }

        if sc == tc && sr == tr { return [] }

        // BFS
        var visited = Array(repeating: Array(repeating: false, count: cols), count: rows)
        var parent = Array(repeating: Array(repeating: (-1, -1), count: cols), count: rows)
        var queue: [(Int, Int)] = [(sc, sr)]
        visited[sr][sc] = true

        let directions = [(0, -1), (0, 1), (-1, 0), (1, 0)] // up, down, left, right

        while !queue.isEmpty {
            let (cc, cr) = queue.removeFirst()

            for (dc, dr) in directions {
                let nc = cc + dc
                let nr = cr + dr

                guard nc >= 0, nc < cols, nr >= 0, nr < rows, !visited[nr][nc] else { continue }

                // Check passability
                if let tile = grid[nr][nc] {
                    switch tile.tileType {
                    case .steel, .water:
                        continue // always impassable
                    case .brick:
                        if !canBreakBricks { continue } // impassable for basic/fast
                    case .trees, .ice, .empty:
                        break // passable
                    }
                }

                visited[nr][nc] = true
                parent[nr][nc] = (cc, cr)
                queue.append((nc, nr))

                if nc == tc && nr == tr {
                    // Reconstruct path
                    var path: [(Int, Int)] = []
                    var cur = (tc, tr)
                    while cur.0 != sc || cur.1 != sr {
                        path.append(cur)
                        cur = parent[cur.1][cur.0]
                    }
                    path.reverse()
                    return path
                }
            }
        }

        return [] // no path found
    }

    /// Check if there's a clear line of sight from a tile in a given direction to a target tile.
    /// Returns true if the target is reached before hitting a wall.
    static func hasLineOfSight(
        fromCol: Int, fromRow: Int,
        direction: Direction,
        targetCol: Int, targetRow: Int,
        grid: [[Tile?]]
    ) -> Bool {
        let rows = grid.count
        guard rows > 0 else { return false }
        let cols = grid[0].count

        let (dc, dr): (Int, Int)
        switch direction {
        case .up:    (dc, dr) = (0, -1)
        case .down:  (dc, dr) = (0, 1)
        case .left:  (dc, dr) = (-1, 0)
        case .right: (dc, dr) = (1, 0)
        }

        var c = fromCol + dc
        var r = fromRow + dr

        while c >= 0 && c < cols && r >= 0 && r < rows {
            if c == targetCol && r == targetRow {
                return true
            }
            // Check if blocked
            if let tile = grid[r][c] {
                switch tile.tileType {
                case .brick, .steel, .water:
                    return false
                default:
                    break
                }
            }
            c += dc
            r += dr
        }

        return false
    }

    /// Check if the next tile in the given direction is a brick.
    static func nextTileIsBrick(
        fromCol: Int, fromRow: Int,
        direction: Direction,
        grid: [[Tile?]]
    ) -> Bool {
        let (dc, dr): (Int, Int)
        switch direction {
        case .up:    (dc, dr) = (0, -1)
        case .down:  (dc, dr) = (0, 1)
        case .left:  (dc, dr) = (-1, 0)
        case .right: (dc, dr) = (1, 0)
        }

        let nc = fromCol + dc
        let nr = fromRow + dr
        let rows = grid.count
        guard rows > 0 else { return false }
        let cols = grid[0].count
        guard nc >= 0, nc < cols, nr >= 0, nr < rows else { return false }

        if let tile = grid[nr][nc], tile.tileType == .brick {
            return true
        }
        return false
    }
}
