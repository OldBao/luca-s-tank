//
//  SpriteManager.swift
//  BattleCity
//
//  Programmatic sprite/texture manager for Battle City (NES) recreation.
//  All textures are generated using Core Graphics - no image assets required.
//
//  Game uses 256x224 logical resolution. Tiles are 16x16, sub-tiles 8x8.
//

import SpriteKit
import CoreGraphics

// Enums are defined in Direction.swift

// MARK: - NES Color Palette

/// NES-accurate color approximations used throughout the game.
struct NESColors {
    // Player tank
    static let playerBody    = CGColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
    static let playerBarrel  = CGColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
    static let playerTread   = CGColor(red: 180/255, green: 108/255, blue: 36/255, alpha: 1)
    static let playerDetail  = CGColor(red: 200/255, green: 120/255, blue: 40/255, alpha: 1)

    // Enemy tanks
    static let enemySilver   = CGColor(red: 188/255, green: 188/255, blue: 188/255, alpha: 1)
    static let enemyDark     = CGColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1)
    static let enemyGreen    = CGColor(red: 0/255, green: 148/255, blue: 0/255, alpha: 1)
    static let enemyGold     = CGColor(red: 252/255, green: 188/255, blue: 0/255, alpha: 1)
    static let flashRed      = CGColor(red: 252/255, green: 56/255, blue: 56/255, alpha: 1)
    static let flashWhite    = CGColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)

    // Tiles
    static let brick         = CGColor(red: 156/255, green: 72/255, blue: 8/255, alpha: 1)
    static let brickDark     = CGColor(red: 108/255, green: 48/255, blue: 0/255, alpha: 1)
    static let brickLight    = CGColor(red: 200/255, green: 100/255, blue: 24/255, alpha: 1)
    static let steel         = CGColor(red: 188/255, green: 188/255, blue: 188/255, alpha: 1)
    static let steelHighlight = CGColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
    static let steelDark     = CGColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
    static let water         = CGColor(red: 0/255, green: 56/255, blue: 252/255, alpha: 1)
    static let waterLight    = CGColor(red: 60/255, green: 100/255, blue: 252/255, alpha: 1)
    static let trees         = CGColor(red: 0/255, green: 148/255, blue: 0/255, alpha: 1)
    static let treesDark     = CGColor(red: 0/255, green: 100/255, blue: 0/255, alpha: 1)
    static let ice           = CGColor(red: 188/255, green: 188/255, blue: 252/255, alpha: 1)
    static let iceHighlight  = CGColor(red: 224/255, green: 224/255, blue: 252/255, alpha: 1)

    // Eagle
    static let eagleBody     = CGColor(red: 188/255, green: 188/255, blue: 188/255, alpha: 1)
    static let eagleWing     = CGColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
    static let eagleRed      = CGColor(red: 200/255, green: 56/255, blue: 0/255, alpha: 1)

    // Team colors for melee mode
    static let teamYellowBody  = CGColor(red: 252/255, green: 200/255, blue: 56/255, alpha: 1)
    static let teamYellowDark  = CGColor(red: 200/255, green: 152/255, blue: 36/255, alpha: 1)
    static let teamRedBody     = CGColor(red: 252/255, green: 56/255, blue: 56/255, alpha: 1)
    static let teamRedDark     = CGColor(red: 180/255, green: 36/255, blue: 36/255, alpha: 1)
    static let teamBlueBody    = CGColor(red: 56/255, green: 100/255, blue: 252/255, alpha: 1)
    static let teamBlueDark    = CGColor(red: 36/255, green: 72/255, blue: 200/255, alpha: 1)
    static let teamGreenBody   = CGColor(red: 56/255, green: 200/255, blue: 56/255, alpha: 1)
    static let teamGreenDark   = CGColor(red: 36/255, green: 148/255, blue: 36/255, alpha: 1)

    // General
    static let black         = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    static let white         = CGColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
    static let yellow        = CGColor(red: 252/255, green: 252/255, blue: 0/255, alpha: 1)
    static let red           = CGColor(red: 252/255, green: 56/255, blue: 56/255, alpha: 1)
    static let orange        = CGColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
    static let green         = CGColor(red: 0/255, green: 200/255, blue: 0/255, alpha: 1)
    static let blue          = CGColor(red: 56/255, green: 56/255, blue: 252/255, alpha: 1)
    static let gray          = CGColor(red: 148/255, green: 148/255, blue: 148/255, alpha: 1)
    static let clear         = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
}

// MARK: - SpriteManager

class SpriteManager {

    static let shared = SpriteManager()

    private var textureCache: [String: SKTexture] = [:]

    private init() {
        preloadAllTextures()
    }

    // MARK: - Public Accessors

    /// Player tank texture for given direction, animation frame (0 or 1), and tier (0-3).
    func playerTankTexture(direction: Direction, frame: Int, tier: Int) -> SKTexture {
        let key = "player_d\(direction.rawValue)_f\(frame)_t\(tier)"
        return textureCache[key] ?? generatePlayerTankTexture(direction: direction, frame: frame, tier: tier)
    }

    /// Enemy tank texture. `isFlashing` toggles between red/white for power-up carriers.
    /// `armorHP` applies only to armor type (4=silver, 3=gold, 2=green, 1=flashing).
    func enemyTankTexture(type: EnemyType, direction: Direction, frame: Int,
                          isFlashing: Bool = false, armorHP: Int = 4) -> SKTexture {
        let key = "enemy_\(type.rawValue)_d\(direction.rawValue)_f\(frame)_fl\(isFlashing ? 1 : 0)_hp\(armorHP)"
        return textureCache[key] ?? generateEnemyTankTexture(type: type, direction: direction,
                                                              frame: frame, isFlashing: isFlashing,
                                                              armorHP: armorHP)
    }

    func bulletTexture(direction: Direction) -> SKTexture {
        let key = "bullet_d\(direction.rawValue)"
        return textureCache[key]!
    }

    func tileTexture(type: TileType, variant: Int = 0) -> SKTexture {
        // For brick type, variant 0 maps to full brick (bitmask 15)
        let v = (type == .brick && variant == 0) ? 15 : variant
        let key = "tile_\(type.rawValue)_v\(v)"
        return textureCache[key] ?? textureCache["tile_\(type.rawValue)_v0"] ?? SKTexture()
    }

    func powerUpTexture(type: PowerUpType) -> SKTexture {
        let key = "powerup_\(type.rawValue)"
        return textureCache[key]!
    }

    func explosionTexture(size: ExplosionSize, frame: Int) -> SKTexture {
        let key = "explosion_\(size == .small ? "s" : "l")_f\(frame)"
        return textureCache[key]!
    }

    func shieldTexture(frame: Int) -> SKTexture {
        let key = "shield_f\(frame)"
        return textureCache[key]!
    }

    func spawnTexture(frame: Int) -> SKTexture {
        let key = "spawn_f\(frame)"
        return textureCache[key]!
    }

    func eagleTexture(alive: Bool) -> SKTexture {
        let key = alive ? "eagle_alive" : "eagle_dead"
        return textureCache[key]!
    }

    func hudEnemyIcon() -> SKTexture {
        return textureCache["hud_enemy"]!
    }

    func hudLifeIcon() -> SKTexture {
        return textureCache["hud_life"]!
    }

    func hudHeartIcon() -> SKTexture {
        return textureCache["hud_heart"]!
    }

    func hudFlagIcon() -> SKTexture {
        return textureCache["hud_flag"]!
    }

    /// Melee mode team tank texture — draws a tank in the team's color.
    func meleeTeamTankTexture(type: EnemyType, direction: Direction, frame: Int,
                              teamColor: TeamColor, armorHP: Int = 4) -> SKTexture {
        let key = "melee_\(teamColor.rawValue)_\(type.rawValue)_d\(direction.rawValue)_f\(frame)_hp\(armorHP)"
        if let cached = textureCache[key] { return cached }

        let bodyColor: CGColor
        let treadColor: CGColor
        switch teamColor {
        case .yellow:
            bodyColor = NESColors.teamYellowBody
            treadColor = NESColors.teamYellowDark
        case .red:
            bodyColor = NESColors.teamRedBody
            treadColor = NESColors.teamRedDark
        case .blue:
            bodyColor = NESColors.teamBlueBody
            treadColor = NESColors.teamBlueDark
        case .green:
            bodyColor = NESColors.teamGreenBody
            treadColor = NESColors.teamGreenDark
        }

        var hasFat = false
        var hasDouble = false
        var hasLarger = false
        var hasArmor = false
        switch type {
        case .basic: break
        case .fast: break
        case .power:
            hasFat = true
            hasDouble = true
        case .armor:
            hasFat = true
            hasLarger = true
            hasArmor = true
        }

        let tex = generateTankTexture(
            bodyColor: bodyColor,
            barrelColor: NESColors.white,
            treadColor: treadColor,
            detailColor: treadColor,
            direction: direction,
            frame: frame,
            hasFatBarrel: hasFat,
            hasDoubleBarrel: hasDouble,
            hasLargerTurret: hasLarger,
            hasArmorPlates: hasArmor)
        textureCache[key] = tex
        return tex
    }

    // MARK: - Preload All Textures

    private func preloadAllTextures() {
        // Player tanks: 4 directions x 2 frames x 4 tiers
        for tier in 0..<4 {
            for dir in Direction.allCases {
                for frame in 0..<2 {
                    let key = "player_d\(dir.rawValue)_f\(frame)_t\(tier)"
                    textureCache[key] = generatePlayerTankTexture(direction: dir, frame: frame, tier: tier)
                }
            }
        }

        // Enemy tanks: 4 types x 4 directions x 2 frames x flashing variants
        for type in EnemyType.allCases {
            for dir in Direction.allCases {
                for frame in 0..<2 {
                    for flash in [false, true] {
                        if type == .armor {
                            for hp in 1...4 {
                                let key = "enemy_\(type.rawValue)_d\(dir.rawValue)_f\(frame)_fl\(flash ? 1 : 0)_hp\(hp)"
                                textureCache[key] = generateEnemyTankTexture(
                                    type: type, direction: dir, frame: frame,
                                    isFlashing: flash, armorHP: hp)
                            }
                        } else {
                            let key = "enemy_\(type.rawValue)_d\(dir.rawValue)_f\(frame)_fl\(flash ? 1 : 0)_hp\(4)"
                            textureCache[key] = generateEnemyTankTexture(
                                type: type, direction: dir, frame: frame,
                                isFlashing: flash, armorHP: 4)
                        }
                    }
                }
            }
        }

        // Bullets: 4 directions
        for dir in Direction.allCases {
            let key = "bullet_d\(dir.rawValue)"
            textureCache[key] = generateBulletTexture(direction: dir)
        }

        // Tiles
        // Brick: variant is a bitmask of alive sub-bricks (bit 0=TL, 1=TR, 2=BL, 3=BR)
        // 0 = none alive, 15 = all alive, etc.
        for v in 0...15 {
            let key = "tile_\(TileType.brick.rawValue)_v\(v)"
            textureCache[key] = generateBrickTextureBitmask(variant: v)
        }
        // Also store variant 0 as "full" for initial tile creation
        textureCache["tile_\(TileType.brick.rawValue)_v0"] = generateBrickTextureBitmask(variant: 15)
        // Steel
        textureCache["tile_\(TileType.steel.rawValue)_v0"] = generateSteelTexture()
        // Water: 2 animation frames
        for v in 0..<2 {
            let key = "tile_\(TileType.water.rawValue)_v\(v)"
            textureCache[key] = generateWaterTexture(frame: v)
        }
        // Trees
        textureCache["tile_\(TileType.trees.rawValue)_v0"] = generateTreesTexture()
        // Ice
        textureCache["tile_\(TileType.ice.rawValue)_v0"] = generateIceTexture()

        // Power-ups
        for type in PowerUpType.allCases {
            let key = "powerup_\(type.rawValue)"
            textureCache[key] = generatePowerUpTexture(type: type)
        }

        // Explosions
        for frame in 0..<2 {
            textureCache["explosion_s_f\(frame)"] = generateExplosionTexture(size: .small, frame: frame)
        }
        for frame in 0..<3 {
            textureCache["explosion_l_f\(frame)"] = generateExplosionTexture(size: .large, frame: frame)
        }

        // Shield
        for frame in 0..<2 {
            textureCache["shield_f\(frame)"] = generateShieldTexture(frame: frame)
        }

        // Spawn
        for frame in 0..<4 {
            textureCache["spawn_f\(frame)"] = generateSpawnTexture(frame: frame)
        }

        // Eagle
        textureCache["eagle_alive"] = generateEagleTexture(alive: true)
        textureCache["eagle_dead"] = generateEagleTexture(alive: false)

        // HUD
        textureCache["hud_enemy"] = generateHUDEnemyIcon()
        textureCache["hud_life"] = generateHUDLifeIcon()
        textureCache["hud_heart"] = generateHUDHeartIcon()
        textureCache["hud_flag"] = generateHUDFlagIcon()
    }

    // MARK: - Texture Creation Helpers

    /// Create a CGContext for pixel drawing with given size.
    private func createContext(width: Int, height: Int) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    /// Convert CGContext to SKTexture with nearest-neighbor filtering.
    private func textureFromContext(_ ctx: CGContext) -> SKTexture {
        guard let image = ctx.makeImage() else {
            return SKTexture()
        }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .nearest
        return texture
    }

    /// Set a single pixel in the context.
    private func setPixel(_ ctx: CGContext, x: Int, y: Int, color: CGColor) {
        ctx.setFillColor(color)
        ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
    }

    /// Fill a rectangle in the context.
    private func fillRect(_ ctx: CGContext, x: Int, y: Int, w: Int, h: Int, color: CGColor) {
        ctx.setFillColor(color)
        ctx.fill(CGRect(x: x, y: y, width: w, height: h))
    }

    // MARK: - Tank Drawing

    /// Draws a generic tank body facing UP in a 16x16 context, then rotates for other directions.
    /// Returns the final texture.
    ///
    /// Tank anatomy (facing up, 16x16 grid):
    /// - Treads: columns 1-2 and 13-14, rows 1-14 (2px wide strips on each side)
    /// - Body: columns 3-12, rows 2-13 (10x12 center block)
    /// - Barrel: columns 7-8, rows 0-2 (2px wide extending from top of body upward)
    /// - Turret: columns 5-10, rows 4-9 (circular/square turret in center)
    private func generateTankTexture(
        bodyColor: CGColor,
        barrelColor: CGColor,
        treadColor: CGColor,
        detailColor: CGColor,
        direction: Direction,
        frame: Int,
        hasFatBarrel: Bool = false,
        hasDoubleBarrel: Bool = false,
        hasLargerTurret: Bool = false,
        hasArmorPlates: Bool = false
    ) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }

        // Clear to transparent
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // We draw the tank facing UP, then the final image is rotated.
        // CGContext origin is bottom-left; we draw with y=0 at bottom.
        // For "facing up" in NES terms (screen y=0 at top), we draw barrel at top (high y in CG).

        // --- Treads ---
        // Left tread: x=1..2, y=1..14
        // Right tread: x=13..14, y=1..14
        let treadPatternA: [Bool] = [true, false, true, false, true, false, true,
                                      false, true, false, true, false, true, false]
        let treadPatternB: [Bool] = [false, true, false, true, false, true, false,
                                      true, false, true, false, true, false, true]
        let pattern = (frame == 0) ? treadPatternA : treadPatternB

        for i in 0..<14 {
            let ty = 1 + i
            let tColor = pattern[i] ? treadColor : detailColor
            // Left tread
            fillRect(ctx, x: 1, y: ty, w: 2, h: 1, color: tColor)
            // Right tread
            fillRect(ctx, x: 13, y: ty, w: 2, h: 1, color: tColor)
        }

        // Tread edges (darker outline)
        fillRect(ctx, x: 0, y: 1, w: 1, h: 14, color: detailColor)
        fillRect(ctx, x: 3, y: 1, w: 1, h: 14, color: detailColor)
        fillRect(ctx, x: 12, y: 1, w: 1, h: 14, color: detailColor)
        fillRect(ctx, x: 15, y: 1, w: 1, h: 14, color: detailColor)

        // Tread caps (top and bottom of treads)
        fillRect(ctx, x: 1, y: 0, w: 2, h: 1, color: treadColor)
        fillRect(ctx, x: 13, y: 0, w: 2, h: 1, color: treadColor)
        fillRect(ctx, x: 1, y: 15, w: 2, h: 1, color: treadColor)
        fillRect(ctx, x: 13, y: 15, w: 2, h: 1, color: treadColor)

        // --- Body ---
        // Main body block: x=4..11, y=2..13
        fillRect(ctx, x: 4, y: 2, w: 8, h: 12, color: bodyColor)

        // --- Turret ---
        // Center turret: x=5..10, y=5..10 (6x6 block)
        let turretSize = hasLargerTurret ? 8 : 6
        let turretOffset = hasLargerTurret ? 4 : 5
        fillRect(ctx, x: turretOffset, y: turretOffset, w: turretSize, h: turretSize, color: detailColor)
        // Inner turret highlight
        let innerOff = hasLargerTurret ? 5 : 6
        let innerSize = hasLargerTurret ? 6 : 4
        fillRect(ctx, x: innerOff, y: innerOff, w: innerSize, h: innerSize, color: bodyColor)

        // Armor plates (extra detail squares on body corners)
        if hasArmorPlates {
            fillRect(ctx, x: 4, y: 2, w: 2, h: 2, color: detailColor)
            fillRect(ctx, x: 10, y: 2, w: 2, h: 2, color: detailColor)
            fillRect(ctx, x: 4, y: 12, w: 2, h: 2, color: detailColor)
            fillRect(ctx, x: 10, y: 12, w: 2, h: 2, color: detailColor)
        }

        // --- Barrel ---
        // Barrel facing up: from turret center upward
        // Normal barrel: x=7..8, y=12..15 (top of tank in CG coords, since y increases upward)
        let barrelWidth = hasFatBarrel ? 4 : 2
        let barrelX = hasFatBarrel ? 6 : 7
        fillRect(ctx, x: barrelX, y: 12, w: barrelWidth, h: 4, color: barrelColor)

        if hasDoubleBarrel {
            fillRect(ctx, x: 6, y: 12, w: 1, h: 4, color: barrelColor)
            fillRect(ctx, x: 9, y: 12, w: 1, h: 4, color: barrelColor)
        }

        // Now rotate the image based on direction.
        guard let baseImage = ctx.makeImage() else { return SKTexture() }
        let rotatedImage = rotateImage(baseImage, direction: direction)

        let texture = SKTexture(cgImage: rotatedImage)
        texture.filteringMode = .nearest
        return texture
    }

    /// Rotate a 16x16 CGImage to face a given direction.
    /// The base image faces UP. We rotate: right=90CW, down=180, left=90CCW.
    private func rotateImage(_ image: CGImage, direction: Direction) -> CGImage {
        let size = 16
        guard let ctx = createContext(width: size, height: size) else { return image }

        ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

        let center = CGFloat(size) / 2.0
        ctx.translateBy(x: center, y: center)

        switch direction {
        case .up:
            break // no rotation
        case .right:
            ctx.rotate(by: -.pi / 2)
        case .down:
            ctx.rotate(by: .pi)
        case .left:
            ctx.rotate(by: .pi / 2)
        }

        ctx.translateBy(x: -center, y: -center)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))

        return ctx.makeImage() ?? image
    }

    /// Rotate an image of arbitrary size.
    private func rotateImageSized(_ image: CGImage, direction: Direction, size: Int) -> CGImage {
        guard let ctx = createContext(width: size, height: size) else { return image }
        ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

        let center = CGFloat(size) / 2.0
        ctx.translateBy(x: center, y: center)

        switch direction {
        case .up:    break
        case .right: ctx.rotate(by: -.pi / 2)
        case .down:  ctx.rotate(by: .pi)
        case .left:  ctx.rotate(by: .pi / 2)
        }

        ctx.translateBy(x: -center, y: -center)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        return ctx.makeImage() ?? image
    }

    // MARK: - Player Tank Textures

    private func generatePlayerTankTexture(direction: Direction, frame: Int, tier: Int) -> SKTexture {
        let tex: SKTexture
        switch tier {
        case 0:
            // Basic player tank
            tex = generateTankTexture(
                bodyColor: NESColors.playerBody,
                barrelColor: NESColors.playerBarrel,
                treadColor: NESColors.playerTread,
                detailColor: NESColors.playerDetail,
                direction: direction,
                frame: frame)
        case 1:
            // Faster - slightly different detail
            tex = generateTankTexture(
                bodyColor: NESColors.playerBody,
                barrelColor: NESColors.playerBarrel,
                treadColor: NESColors.playerTread,
                detailColor: NESColors.playerDetail,
                direction: direction,
                frame: frame,
                hasFatBarrel: true)
        case 2:
            // Power shot - double barrel
            tex = generateTankTexture(
                bodyColor: NESColors.playerBody,
                barrelColor: NESColors.playerBarrel,
                treadColor: NESColors.playerTread,
                detailColor: NESColors.playerDetail,
                direction: direction,
                frame: frame,
                hasDoubleBarrel: true)
        default:
            // Max upgrade - larger turret + armor
            tex = generateTankTexture(
                bodyColor: NESColors.playerBody,
                barrelColor: NESColors.playerBarrel,
                treadColor: NESColors.playerTread,
                detailColor: NESColors.playerDetail,
                direction: direction,
                frame: frame,
                hasFatBarrel: true,
                hasLargerTurret: true,
                hasArmorPlates: true)
        }
        let key = "player_d\(direction.rawValue)_f\(frame)_t\(tier)"
        textureCache[key] = tex
        return tex
    }

    // MARK: - Enemy Tank Textures

    private func generateEnemyTankTexture(type: EnemyType, direction: Direction,
                                           frame: Int, isFlashing: Bool, armorHP: Int) -> SKTexture {
        // Determine colors based on type and state
        var bodyColor: CGColor
        var barrelColor: CGColor
        var treadColor: CGColor
        var detailColor: CGColor

        if isFlashing {
            // Flashing power-up carrier: alternate red/white
            bodyColor = NESColors.flashRed
            barrelColor = NESColors.flashWhite
            treadColor = NESColors.flashRed
            detailColor = NESColors.flashWhite
        } else {
            switch type {
            case .basic:
                bodyColor = NESColors.enemySilver
                barrelColor = NESColors.white
                treadColor = NESColors.enemyDark
                detailColor = NESColors.gray
            case .fast:
                bodyColor = NESColors.enemySilver
                barrelColor = NESColors.white
                treadColor = NESColors.enemyDark
                detailColor = NESColors.gray
            case .power:
                bodyColor = NESColors.enemyGreen
                barrelColor = NESColors.white
                treadColor = NESColors.enemyDark
                detailColor = NESColors.enemyGreen
            case .armor:
                switch armorHP {
                case 4:
                    bodyColor = NESColors.enemySilver
                    barrelColor = NESColors.white
                    treadColor = NESColors.enemyDark
                    detailColor = NESColors.gray
                case 3:
                    bodyColor = NESColors.enemyGold
                    barrelColor = NESColors.white
                    treadColor = NESColors.enemyDark
                    detailColor = NESColors.enemyGold
                case 2:
                    bodyColor = NESColors.enemyGreen
                    barrelColor = NESColors.white
                    treadColor = NESColors.enemyDark
                    detailColor = NESColors.enemyGreen
                default: // 1 HP: flashing between silver and white
                    bodyColor = NESColors.white
                    barrelColor = NESColors.enemySilver
                    treadColor = NESColors.gray
                    detailColor = NESColors.white
                }
            }
        }

        var hasFat = false
        var hasDouble = false
        var hasLarger = false
        var hasArmor = false

        switch type {
        case .basic:
            break
        case .fast:
            // Slightly sleeker - use same base but no extra features
            break
        case .power:
            hasFat = true
            hasDouble = true
        case .armor:
            hasFat = true
            hasLarger = true
            hasArmor = true
        }

        let tex = generateTankTexture(
            bodyColor: bodyColor,
            barrelColor: barrelColor,
            treadColor: treadColor,
            detailColor: detailColor,
            direction: direction,
            frame: frame,
            hasFatBarrel: hasFat,
            hasDoubleBarrel: hasDouble,
            hasLargerTurret: hasLarger,
            hasArmorPlates: hasArmor)

        let key = "enemy_\(type.rawValue)_d\(direction.rawValue)_f\(frame)_fl\(isFlashing ? 1 : 0)_hp\(armorHP)"
        textureCache[key] = tex
        return tex
    }

    // MARK: - Bullet Texture (4x4)

    private func generateBulletTexture(direction: Direction) -> SKTexture {
        guard let ctx = createContext(width: 4, height: 4) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 4, height: 4))

        // Bullet: bright yellow/white core
        fillRect(ctx, x: 0, y: 0, w: 4, h: 4, color: NESColors.orange)
        fillRect(ctx, x: 1, y: 1, w: 2, h: 2, color: NESColors.white)

        // Add directional tip
        switch direction {
        case .up:
            fillRect(ctx, x: 1, y: 3, w: 2, h: 1, color: NESColors.white)
        case .down:
            fillRect(ctx, x: 1, y: 0, w: 2, h: 1, color: NESColors.white)
        case .left:
            fillRect(ctx, x: 0, y: 1, w: 1, h: 2, color: NESColors.white)
        case .right:
            fillRect(ctx, x: 3, y: 1, w: 1, h: 2, color: NESColors.white)
        }

        return textureFromContext(ctx)
    }

    // MARK: - Tile Textures

    /// Brick tile with bitmask variant.
    /// Bits: 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight (1 = alive)
    private func generateBrickTextureBitmask(variant: Int) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Sub-bricks in CG coords (y=0 is bottom):
        // bit 0 = topLeft => CG (0, 8)
        // bit 1 = topRight => CG (8, 8)
        // bit 2 = bottomLeft => CG (0, 0)
        // bit 3 = bottomRight => CG (8, 0)
        let subBricks: [(x: Int, y: Int, bit: Int)] = [
            (0, 8, 0),  // topLeft
            (8, 8, 1),  // topRight
            (0, 0, 2),  // bottomLeft
            (8, 0, 3),  // bottomRight
        ]

        for sb in subBricks {
            if variant & (1 << sb.bit) != 0 {
                drawBrickSubTile(ctx, x: sb.x, y: sb.y)
            }
        }

        return textureFromContext(ctx)
    }

    /// Draw an 8x8 brick sub-tile at the given position.
    /// NES brick pattern: alternating rows of offset bricks.
    private func drawBrickSubTile(_ ctx: CGContext, x: Int, y: Int) {
        // Fill background
        fillRect(ctx, x: x, y: y, w: 8, h: 8, color: NESColors.brick)

        // Brick pattern: horizontal lines (mortar) and vertical offsets
        // Row 0-2: two bricks side by side
        fillRect(ctx, x: x, y: y + 7, w: 8, h: 1, color: NESColors.brickLight) // top highlight
        fillRect(ctx, x: x, y: y + 4, w: 8, h: 1, color: NESColors.brickDark) // mortar line
        fillRect(ctx, x: x, y: y, w: 8, h: 1, color: NESColors.brickDark) // bottom mortar

        // Vertical mortar lines (offset between rows)
        fillRect(ctx, x: x + 3, y: y + 5, w: 1, h: 3, color: NESColors.brickDark)
        fillRect(ctx, x: x + 7, y: y + 5, w: 1, h: 3, color: NESColors.brickDark)
        fillRect(ctx, x: x, y: y + 1, w: 1, h: 3, color: NESColors.brickDark)
        fillRect(ctx, x: x + 5, y: y + 1, w: 1, h: 3, color: NESColors.brickDark)

        // Highlights on bricks
        fillRect(ctx, x: x, y: y + 6, w: 3, h: 1, color: NESColors.brickLight)
        fillRect(ctx, x: x + 4, y: y + 6, w: 3, h: 1, color: NESColors.brickLight)
        fillRect(ctx, x: x + 1, y: y + 3, w: 4, h: 1, color: NESColors.brickLight)
        fillRect(ctx, x: x + 6, y: y + 3, w: 1, h: 1, color: NESColors.brickLight)
    }

    /// Steel tile: metallic gray with highlight pattern.
    private func generateSteelTexture() -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Base steel color
        fillRect(ctx, x: 0, y: 0, w: 16, h: 16, color: NESColors.steel)

        // Grid pattern: 4x4 riveted steel plates
        for row in 0..<2 {
            for col in 0..<2 {
                let bx = col * 8
                let by = row * 8

                // Dark border (bottom and right edges)
                fillRect(ctx, x: bx, y: by, w: 8, h: 1, color: NESColors.steelDark)
                fillRect(ctx, x: bx + 7, y: by, w: 1, h: 8, color: NESColors.steelDark)

                // Highlight (top and left edges)
                fillRect(ctx, x: bx, y: by + 7, w: 8, h: 1, color: NESColors.steelHighlight)
                fillRect(ctx, x: bx, y: by, w: 1, h: 8, color: NESColors.steelHighlight)

                // Center rivet highlight
                fillRect(ctx, x: bx + 3, y: by + 3, w: 2, h: 2, color: NESColors.steelHighlight)
            }
        }

        return textureFromContext(ctx)
    }

    /// Water tile with animation. frame 0 and 1 have shifted wave pattern.
    private func generateWaterTexture(frame: Int) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Base water
        fillRect(ctx, x: 0, y: 0, w: 16, h: 16, color: NESColors.water)

        // Wave pattern: horizontal lighter lines that shift between frames
        let offset = frame * 2
        for row in 0..<8 {
            let y = row * 2 + offset
            if y < 16 {
                // Wave crests
                for col in 0..<4 {
                    let wx = col * 4 + (row % 2 == 0 ? 0 : 2)
                    if wx < 16 && wx + 2 <= 16 {
                        fillRect(ctx, x: wx, y: y, w: 2, h: 1, color: NESColors.waterLight)
                    }
                }
            }
        }

        return textureFromContext(ctx)
    }

    /// Trees/forest tile: green canopy pattern.
    private func generateTreesTexture() -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Base dark green
        fillRect(ctx, x: 0, y: 0, w: 16, h: 16, color: NESColors.treesDark)

        // Leaf clusters: overlapping circles approximated as filled rects
        let leaves: [(x: Int, y: Int, w: Int, h: Int)] = [
            (1, 1, 5, 5), (8, 0, 6, 5), (0, 7, 5, 5), (6, 6, 6, 6),
            (11, 8, 5, 5), (3, 11, 5, 5), (9, 12, 5, 4),
            (0, 13, 4, 3), (13, 2, 3, 4), (5, 3, 3, 3),
        ]
        for leaf in leaves {
            fillRect(ctx, x: leaf.x, y: leaf.y, w: leaf.w, h: leaf.h, color: NESColors.trees)
        }

        // Some lighter spots for depth
        let highlights: [(x: Int, y: Int)] = [
            (2, 3), (9, 2), (1, 9), (7, 8), (12, 10), (4, 13), (10, 14), (14, 4)
        ]
        let lightGreen = CGColor(red: 56/255, green: 200/255, blue: 56/255, alpha: 1)
        for h in highlights {
            fillRect(ctx, x: h.x, y: h.y, w: 2, h: 2, color: lightGreen)
        }

        return textureFromContext(ctx)
    }

    /// Ice tile: light blue smooth surface.
    private func generateIceTexture() -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Base ice color
        fillRect(ctx, x: 0, y: 0, w: 16, h: 16, color: NESColors.ice)

        // Shine highlights
        fillRect(ctx, x: 1, y: 12, w: 4, h: 2, color: NESColors.iceHighlight)
        fillRect(ctx, x: 8, y: 5, w: 3, h: 2, color: NESColors.iceHighlight)
        fillRect(ctx, x: 3, y: 3, w: 2, h: 1, color: NESColors.iceHighlight)
        fillRect(ctx, x: 11, y: 11, w: 3, h: 1, color: NESColors.iceHighlight)

        // Subtle surface lines
        let lineColor = CGColor(red: 160/255, green: 160/255, blue: 230/255, alpha: 1)
        fillRect(ctx, x: 0, y: 8, w: 16, h: 1, color: lineColor)
        fillRect(ctx, x: 6, y: 0, w: 1, h: 16, color: lineColor)

        return textureFromContext(ctx)
    }

    // MARK: - Power-Up Textures (16x16)

    private func generatePowerUpTexture(type: PowerUpType) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Background: dark rounded rect
        fillRect(ctx, x: 1, y: 1, w: 14, h: 14, color: NESColors.black)

        switch type {
        case .star:
            drawStar(ctx)
        case .tank:
            drawTankIcon(ctx)
        case .shield:
            drawShieldIcon(ctx)
        case .bomb:
            drawBombIcon(ctx)
        case .clock:
            drawClockIcon(ctx)
        case .shovel:
            drawShovelIcon(ctx)
        case .steelBreaker:
            drawSteelBreakerIcon(ctx)
        }

        return textureFromContext(ctx)
    }

    private func drawStar(_ ctx: CGContext) {
        // 5-pointed star in yellow
        let c = NESColors.yellow
        // Simplified pixelated star
        fillRect(ctx, x: 7, y: 12, w: 2, h: 2, color: c)  // top point
        fillRect(ctx, x: 5, y: 10, w: 6, h: 2, color: c)   // upper body
        fillRect(ctx, x: 3, y: 8, w: 10, h: 2, color: c)    // middle (widest)
        fillRect(ctx, x: 5, y: 6, w: 6, h: 2, color: c)     // lower body
        fillRect(ctx, x: 3, y: 3, w: 3, h: 3, color: c)     // left foot
        fillRect(ctx, x: 10, y: 3, w: 3, h: 3, color: c)    // right foot
    }

    private func drawTankIcon(_ ctx: CGContext) {
        // Small tank icon (extra life)
        let c = NESColors.green
        fillRect(ctx, x: 3, y: 3, w: 2, h: 10, color: c)  // left tread
        fillRect(ctx, x: 11, y: 3, w: 2, h: 10, color: c) // right tread
        fillRect(ctx, x: 5, y: 4, w: 6, h: 8, color: c)   // body
        fillRect(ctx, x: 7, y: 12, w: 2, h: 2, color: NESColors.white) // barrel
    }

    private func drawShieldIcon(_ ctx: CGContext) {
        // Shield shape
        let c = NESColors.white
        fillRect(ctx, x: 4, y: 8, w: 8, h: 5, color: c)   // top half
        fillRect(ctx, x: 5, y: 5, w: 6, h: 3, color: c)    // middle
        fillRect(ctx, x: 6, y: 3, w: 4, h: 2, color: c)    // lower
        fillRect(ctx, x: 7, y: 2, w: 2, h: 1, color: c)    // bottom point
        // Inner detail
        fillRect(ctx, x: 6, y: 8, w: 4, h: 3, color: NESColors.blue)
    }

    private func drawBombIcon(_ ctx: CGContext) {
        // Grenade/bomb
        let c = NESColors.red
        fillRect(ctx, x: 5, y: 3, w: 6, h: 8, color: c)   // body
        fillRect(ctx, x: 4, y: 4, w: 8, h: 6, color: c)    // body wider
        fillRect(ctx, x: 7, y: 11, w: 2, h: 2, color: NESColors.gray)  // fuse cap
        fillRect(ctx, x: 7, y: 13, w: 2, h: 1, color: NESColors.yellow) // spark
    }

    private func drawClockIcon(_ ctx: CGContext) {
        // Clock/timer
        let c = NESColors.white
        // Circular face
        fillRect(ctx, x: 5, y: 3, w: 6, h: 10, color: c)
        fillRect(ctx, x: 4, y: 4, w: 8, h: 8, color: c)
        fillRect(ctx, x: 3, y: 5, w: 10, h: 6, color: c)
        // Inner face
        fillRect(ctx, x: 5, y: 5, w: 6, h: 6, color: NESColors.blue)
        // Hands
        fillRect(ctx, x: 7, y: 8, w: 3, h: 1, color: NESColors.white) // hour
        fillRect(ctx, x: 7, y: 8, w: 1, h: 3, color: NESColors.white) // minute
    }

    private func drawShovelIcon(_ ctx: CGContext) {
        // Shovel
        let handle = NESColors.orange
        let blade = NESColors.gray
        // Handle
        fillRect(ctx, x: 7, y: 8, w: 2, h: 6, color: handle)
        // Blade
        fillRect(ctx, x: 5, y: 3, w: 6, h: 5, color: blade)
        fillRect(ctx, x: 6, y: 2, w: 4, h: 1, color: blade)
        // Blade edge highlight
        fillRect(ctx, x: 5, y: 3, w: 6, h: 1, color: NESColors.white)
    }

    private func drawSteelBreakerIcon(_ ctx: CGContext) {
        // Bullet piercing through steel wall
        let bullet = NESColors.yellow
        let steel = NESColors.steel
        // Steel block
        fillRect(ctx, x: 3, y: 3, w: 10, h: 10, color: steel)
        fillRect(ctx, x: 4, y: 4, w: 8, h: 8, color: NESColors.steelDark)
        // Crack lines
        fillRect(ctx, x: 7, y: 3, w: 2, h: 10, color: NESColors.black)
        fillRect(ctx, x: 3, y: 7, w: 10, h: 2, color: NESColors.black)
        // Bright bullet
        fillRect(ctx, x: 6, y: 11, w: 4, h: 4, color: bullet)
        fillRect(ctx, x: 7, y: 12, w: 2, h: 2, color: NESColors.red)
    }

    // MARK: - Explosion Textures

    private func generateExplosionTexture(size: ExplosionSize, frame: Int) -> SKTexture {
        let dim = size == .small ? 16 : 32
        guard let ctx = createContext(width: dim, height: dim) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: dim, height: dim))

        let center = dim / 2

        if size == .small {
            if frame == 0 {
                // Small explosion frame 0: compact burst
                fillRect(ctx, x: center - 3, y: center - 3, w: 6, h: 6, color: NESColors.yellow)
                fillRect(ctx, x: center - 2, y: center - 2, w: 4, h: 4, color: NESColors.white)
                // Cross pattern
                fillRect(ctx, x: center - 1, y: center - 5, w: 2, h: 10, color: NESColors.orange)
                fillRect(ctx, x: center - 5, y: center - 1, w: 10, h: 2, color: NESColors.orange)
            } else {
                // Small explosion frame 1: slightly larger
                fillRect(ctx, x: center - 4, y: center - 4, w: 8, h: 8, color: NESColors.orange)
                fillRect(ctx, x: center - 3, y: center - 3, w: 6, h: 6, color: NESColors.yellow)
                fillRect(ctx, x: center - 2, y: center - 2, w: 4, h: 4, color: NESColors.white)
                // Diagonal sparks
                setPixel(ctx, x: center - 6, y: center - 6, color: NESColors.yellow)
                setPixel(ctx, x: center + 5, y: center - 6, color: NESColors.yellow)
                setPixel(ctx, x: center - 6, y: center + 5, color: NESColors.yellow)
                setPixel(ctx, x: center + 5, y: center + 5, color: NESColors.yellow)
            }
        } else {
            // Large explosion (32x32)
            if frame == 0 {
                // Large burst
                fillRect(ctx, x: center - 8, y: center - 8, w: 16, h: 16, color: NESColors.orange)
                fillRect(ctx, x: center - 6, y: center - 6, w: 12, h: 12, color: NESColors.yellow)
                fillRect(ctx, x: center - 4, y: center - 4, w: 8, h: 8, color: NESColors.white)
                // Cross extensions
                fillRect(ctx, x: center - 2, y: center - 12, w: 4, h: 24, color: NESColors.orange)
                fillRect(ctx, x: center - 12, y: center - 2, w: 24, h: 4, color: NESColors.orange)
                // Diagonal sparks
                fillRect(ctx, x: center - 10, y: center - 10, w: 3, h: 3, color: NESColors.yellow)
                fillRect(ctx, x: center + 8, y: center - 10, w: 3, h: 3, color: NESColors.yellow)
                fillRect(ctx, x: center - 10, y: center + 8, w: 3, h: 3, color: NESColors.yellow)
                fillRect(ctx, x: center + 8, y: center + 8, w: 3, h: 3, color: NESColors.yellow)
            } else {
                // Even larger, more dissipated
                fillRect(ctx, x: center - 10, y: center - 10, w: 20, h: 20, color: NESColors.orange)
                fillRect(ctx, x: center - 8, y: center - 8, w: 16, h: 16, color: NESColors.yellow)
                fillRect(ctx, x: center - 5, y: center - 5, w: 10, h: 10, color: NESColors.white)
                // Extended cross
                fillRect(ctx, x: center - 2, y: center - 14, w: 4, h: 28, color: NESColors.orange)
                fillRect(ctx, x: center - 14, y: center - 2, w: 28, h: 4, color: NESColors.orange)
                // More sparks at extremes
                for dx in [-13, 12] {
                    for dy in [-13, 12] {
                        fillRect(ctx, x: center + dx, y: center + dy, w: 2, h: 2, color: NESColors.yellow)
                    }
                }
            }
        }

        return textureFromContext(ctx)
    }

    // MARK: - Shield Texture (16x16 overlay around tank)

    private func generateShieldTexture(frame: Int) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        let shieldColor = frame == 0 ? NESColors.white : NESColors.blue

        // Draw a hollow rectangle (shield outline) around the tank area
        // Top edge
        fillRect(ctx, x: 2, y: 15, w: 12, h: 1, color: shieldColor)
        // Bottom edge
        fillRect(ctx, x: 2, y: 0, w: 12, h: 1, color: shieldColor)
        // Left edge
        fillRect(ctx, x: 0, y: 2, w: 1, h: 12, color: shieldColor)
        // Right edge
        fillRect(ctx, x: 15, y: 2, w: 1, h: 12, color: shieldColor)
        // Corners
        setPixel(ctx, x: 1, y: 14, color: shieldColor)
        setPixel(ctx, x: 14, y: 14, color: shieldColor)
        setPixel(ctx, x: 1, y: 1, color: shieldColor)
        setPixel(ctx, x: 14, y: 1, color: shieldColor)

        // Additional shimmer on alternating frame
        if frame == 0 {
            setPixel(ctx, x: 4, y: 15, color: NESColors.blue)
            setPixel(ctx, x: 8, y: 15, color: NESColors.blue)
            setPixel(ctx, x: 12, y: 15, color: NESColors.blue)
            setPixel(ctx, x: 0, y: 4, color: NESColors.blue)
            setPixel(ctx, x: 0, y: 8, color: NESColors.blue)
            setPixel(ctx, x: 0, y: 12, color: NESColors.blue)
        } else {
            setPixel(ctx, x: 2, y: 15, color: NESColors.white)
            setPixel(ctx, x: 6, y: 15, color: NESColors.white)
            setPixel(ctx, x: 10, y: 15, color: NESColors.white)
            setPixel(ctx, x: 15, y: 4, color: NESColors.white)
            setPixel(ctx, x: 15, y: 8, color: NESColors.white)
            setPixel(ctx, x: 15, y: 12, color: NESColors.white)
        }

        return textureFromContext(ctx)
    }

    // MARK: - Spawn Effect (16x16, 4 frames)

    /// Spawn animation: sparkle/diamond that starts large and contracts.
    private func generateSpawnTexture(frame: Int) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        let c = NESColors.white
        let center = 8 // center of 16x16

        // Diamond shapes of decreasing size
        switch frame {
        case 0:
            // Largest diamond
            drawDiamond(ctx, cx: center, cy: center, radius: 7, color: c)
        case 1:
            // Medium diamond
            drawDiamond(ctx, cx: center, cy: center, radius: 5, color: c)
        case 2:
            // Small diamond
            drawDiamond(ctx, cx: center, cy: center, radius: 3, color: c)
        default:
            // Smallest / twinkle
            drawDiamond(ctx, cx: center, cy: center, radius: 1, color: c)
            // Plus small dots at corners
            setPixel(ctx, x: center - 3, y: center, color: c)
            setPixel(ctx, x: center + 3, y: center, color: c)
            setPixel(ctx, x: center, y: center - 3, color: c)
            setPixel(ctx, x: center, y: center + 3, color: c)
        }

        return textureFromContext(ctx)
    }

    /// Draw a diamond (rotated square) outline at center (cx, cy) with given radius.
    private func drawDiamond(_ ctx: CGContext, cx: Int, cy: Int, radius: Int, color: CGColor) {
        for i in 0...radius {
            let j = radius - i
            setPixel(ctx, x: cx + i, y: cy + j, color: color) // top-right edge
            setPixel(ctx, x: cx - i, y: cy + j, color: color) // top-left edge
            setPixel(ctx, x: cx + i, y: cy - j, color: color) // bottom-right edge
            setPixel(ctx, x: cx - i, y: cy - j, color: color) // bottom-left edge
        }
        // Fill interior with slightly dimmer version
        let inner = CGColor(red: 200/255, green: 200/255, blue: 252/255, alpha: 0.5)
        for dy in -radius...radius {
            let width = radius - abs(dy)
            for dx in -width...width {
                let px = cx + dx
                let py = cy + dy
                if px >= 0 && px < 16 && py >= 0 && py < 16 {
                    setPixel(ctx, x: px, y: py, color: inner)
                }
            }
        }
        // Redraw outline on top
        for i in 0...radius {
            let j = radius - i
            setPixel(ctx, x: cx + i, y: cy + j, color: color)
            setPixel(ctx, x: cx - i, y: cy + j, color: color)
            setPixel(ctx, x: cx + i, y: cy - j, color: color)
            setPixel(ctx, x: cx - i, y: cy - j, color: color)
        }
    }

    // MARK: - Eagle Texture (16x16)

    private func generateEagleTexture(alive: Bool) -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        if alive {
            // Eagle/phoenix shape - stylized bird
            // Body center
            fillRect(ctx, x: 6, y: 3, w: 4, h: 8, color: NESColors.eagleBody)
            // Wings spread
            fillRect(ctx, x: 2, y: 6, w: 4, h: 5, color: NESColors.eagleWing)
            fillRect(ctx, x: 10, y: 6, w: 4, h: 5, color: NESColors.eagleWing)
            // Wing tips
            fillRect(ctx, x: 1, y: 8, w: 1, h: 3, color: NESColors.eagleWing)
            fillRect(ctx, x: 14, y: 8, w: 1, h: 3, color: NESColors.eagleWing)
            // Head
            fillRect(ctx, x: 6, y: 11, w: 4, h: 3, color: NESColors.eagleWing)
            fillRect(ctx, x: 7, y: 14, w: 2, h: 1, color: NESColors.eagleWing)
            // Beak
            fillRect(ctx, x: 7, y: 13, w: 2, h: 1, color: NESColors.eagleRed)
            // Eyes
            setPixel(ctx, x: 6, y: 12, color: NESColors.black)
            setPixel(ctx, x: 9, y: 12, color: NESColors.black)
            // Tail
            fillRect(ctx, x: 5, y: 2, w: 6, h: 1, color: NESColors.eagleRed)
            fillRect(ctx, x: 6, y: 1, w: 4, h: 1, color: NESColors.eagleRed)
            // Legs
            fillRect(ctx, x: 6, y: 2, w: 1, h: 2, color: NESColors.eagleRed)
            fillRect(ctx, x: 9, y: 2, w: 1, h: 2, color: NESColors.eagleRed)
        } else {
            // Destroyed eagle: broken rubble
            let rubble = NESColors.gray
            let dark = NESColors.enemyDark
            // Scattered debris
            fillRect(ctx, x: 3, y: 2, w: 3, h: 2, color: rubble)
            fillRect(ctx, x: 8, y: 1, w: 4, h: 3, color: rubble)
            fillRect(ctx, x: 5, y: 4, w: 5, h: 3, color: dark)
            fillRect(ctx, x: 2, y: 5, w: 3, h: 2, color: rubble)
            fillRect(ctx, x: 10, y: 5, w: 3, h: 2, color: dark)
            fillRect(ctx, x: 4, y: 7, w: 7, h: 4, color: rubble)
            fillRect(ctx, x: 6, y: 11, w: 3, h: 2, color: dark)
            // Some orange/red for fire remnants
            fillRect(ctx, x: 5, y: 8, w: 2, h: 2, color: NESColors.orange)
            fillRect(ctx, x: 9, y: 6, w: 2, h: 2, color: NESColors.orange)
            setPixel(ctx, x: 7, y: 10, color: NESColors.red)
        }

        return textureFromContext(ctx)
    }

    // MARK: - HUD Icons

    /// Small enemy indicator icon for the sidebar (8x8).
    private func generateHUDEnemyIcon() -> SKTexture {
        guard let ctx = createContext(width: 8, height: 8) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 8, height: 8))

        let c = NESColors.black
        // Simple tank silhouette
        fillRect(ctx, x: 1, y: 1, w: 1, h: 6, color: c)  // left tread
        fillRect(ctx, x: 6, y: 1, w: 1, h: 6, color: c)   // right tread
        fillRect(ctx, x: 2, y: 2, w: 4, h: 4, color: c)    // body
        fillRect(ctx, x: 3, y: 6, w: 2, h: 2, color: c)    // barrel

        return textureFromContext(ctx)
    }

    /// Player life icon (8x8): small player tank.
    private func generateHUDLifeIcon() -> SKTexture {
        guard let ctx = createContext(width: 8, height: 8) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 8, height: 8))

        let c = NESColors.playerBody
        fillRect(ctx, x: 1, y: 1, w: 1, h: 6, color: c)
        fillRect(ctx, x: 6, y: 1, w: 1, h: 6, color: c)
        fillRect(ctx, x: 2, y: 2, w: 4, h: 4, color: c)
        fillRect(ctx, x: 3, y: 6, w: 2, h: 2, color: NESColors.white)

        return textureFromContext(ctx)
    }

    /// HP heart icon (6x6).
    private func generateHUDHeartIcon() -> SKTexture {
        guard let ctx = createContext(width: 6, height: 6) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 6, height: 6))

        let red = NESColors.red
        fillRect(ctx, x: 1, y: 3, w: 1, h: 1, color: red)
        fillRect(ctx, x: 4, y: 3, w: 1, h: 1, color: red)
        fillRect(ctx, x: 0, y: 2, w: 2, h: 2, color: red)
        fillRect(ctx, x: 4, y: 2, w: 2, h: 2, color: red)
        fillRect(ctx, x: 1, y: 1, w: 4, h: 2, color: red)
        fillRect(ctx, x: 2, y: 0, w: 2, h: 1, color: red)

        return textureFromContext(ctx)
    }


    /// Flag/level indicator icon (16x16).
    private func generateHUDFlagIcon() -> SKTexture {
        guard let ctx = createContext(width: 16, height: 16) else { return SKTexture() }
        ctx.clear(CGRect(x: 0, y: 0, width: 16, height: 16))

        // Flag pole
        fillRect(ctx, x: 10, y: 1, w: 1, h: 14, color: NESColors.black)
        // Flag (waving rectangle)
        fillRect(ctx, x: 3, y: 9, w: 7, h: 5, color: NESColors.red)
        // Flag detail
        fillRect(ctx, x: 4, y: 10, w: 5, h: 3, color: NESColors.orange)
        // Pole base
        fillRect(ctx, x: 8, y: 1, w: 5, h: 2, color: NESColors.black)

        return textureFromContext(ctx)
    }
}
