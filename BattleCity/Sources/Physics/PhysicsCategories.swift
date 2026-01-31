import Foundation

struct PhysicsCategory {
    static let none:        UInt32 = 0
    static let playerTank:  UInt32 = 1 << 0
    static let enemyTank:   UInt32 = 1 << 1
    static let playerBullet:UInt32 = 1 << 2
    static let enemyBullet: UInt32 = 1 << 3
    static let brickWall:   UInt32 = 1 << 4
    static let steelWall:   UInt32 = 1 << 5
    static let water:       UInt32 = 1 << 6
    static let eagle:       UInt32 = 1 << 7
    static let powerUp:     UInt32 = 1 << 8
    static let boundary:    UInt32 = 1 << 9

    // What player bullets hit
    static let playerBulletContact: UInt32 = enemyTank | enemyBullet | brickWall | steelWall | eagle | boundary
    // What enemy bullets hit
    static let enemyBulletContact: UInt32 = playerTank | playerBullet | brickWall | steelWall | eagle | boundary
    // What tanks collide with
    static let tankCollision: UInt32 = brickWall | steelWall | water | eagle | boundary
}
