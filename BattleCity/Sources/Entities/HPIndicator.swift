import SpriteKit

final class HPIndicator: SKNode {
    private var hearts: [SKSpriteNode] = []

    func update(hp: Int) {
        let count = max(0, min(5, hp))
        if hearts.count != count {
            hearts.forEach { $0.removeFromParent() }
            hearts = []
            for i in 0..<count {
                let heart = SKSpriteNode(texture: SpriteManager.shared.hudHeartIcon())
                heart.size = CGSize(width: 6, height: 6)
                heart.position = CGPoint(x: CGFloat(i) * 7, y: 0)
                addChild(heart)
                hearts.append(heart)
            }
        }
    }
}
