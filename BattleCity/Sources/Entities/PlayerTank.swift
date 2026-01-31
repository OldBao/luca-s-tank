import SpriteKit

class PlayerTank: Tank {
    var tier: Int = 0  // 0-3 upgrade tiers
    var isShielded: Bool = false
    var shieldNode: SKSpriteNode?
    var shieldTimer: TimeInterval = 0
    var bulletCount: Int = 0
    var respawnInvincibleTimer: TimeInterval = 0
    var steelBreakerTimer: TimeInterval = 0

    var maxBullets: Int {
        tier >= 2 ? Constants.maxPlayerBulletsTier2 : Constants.maxPlayerBullets
    }

    var bulletSpeed: CGFloat {
        tier >= 1 ? Constants.bulletFastSpeed : Constants.bulletNormalSpeed
    }

    var canDestroySteel: Bool {
        tier >= 3 || steelBreakerTimer > 0
    }

    init() {
        let tex = SpriteManager.shared.playerTankTexture(direction: .up, frame: 0, tier: 0)
        super.init(texture: tex)
        self.moveSpeed = Constants.playerSpeed
        self.hp = 1

        // No SpriteKit physics - all collision handled manually in GameScene
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func reset() {
        tier = 0
        direction = .up
        bulletCount = 0
        isShielded = false
        shieldTimer = 0
        steelBreakerTimer = 0
        animFrame = 0
        isMoving = false
        updateTexture()
    }

    func spawnWithShield(duration: TimeInterval = 3.0) {
        isShielded = true
        shieldTimer = duration
        showShieldEffect()
    }

    func showShieldEffect() {
        shieldNode?.removeFromParent()
        let shield = SKSpriteNode(texture: SpriteManager.shared.shieldTexture(frame: 0))
        shield.size = CGSize(width: 18, height: 18)
        shield.zPosition = 1
        shield.name = "shield"
        self.addChild(shield)
        shieldNode = shield

        let anim = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                shield.texture = SpriteManager.shared.shieldTexture(frame: 0)
            },
            SKAction.wait(forDuration: 0.1),
            SKAction.run {
                shield.texture = SpriteManager.shared.shieldTexture(frame: 1)
            },
            SKAction.wait(forDuration: 0.1),
        ]))
        shield.run(anim, withKey: "shieldAnim")
    }

    func updateShield(dt: TimeInterval) {
        if isShielded {
            shieldTimer -= dt
            if shieldTimer <= 0 {
                isShielded = false
                shieldNode?.removeFromParent()
                shieldNode = nil
            }
        }
        if steelBreakerTimer > 0 {
            steelBreakerTimer -= dt
        }
    }

    override func updateTexture() {
        self.texture = SpriteManager.shared.playerTankTexture(direction: direction, frame: animFrame, tier: tier)
    }

    func canFire() -> Bool {
        return bulletCount < maxBullets
    }

    func upgradeTier() {
        tier = min(tier + 1, 3)
        updateTexture()
    }
}
