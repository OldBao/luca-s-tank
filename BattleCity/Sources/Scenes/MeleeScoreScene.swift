import SpriteKit

// Stub — will be fully implemented in Task 10
class MeleeScoreScene: SKScene {
    var matchResult: MeleeMatchResult!
    var meleeConfig: MeleeConfig!

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        let label = SKLabelNode(text: "MATCH RESULTS")
        label.fontName = "Courier-Bold"
        label.fontSize = 14
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        self.addChild(label)
    }
}
