import SpriteKit

class MenuScene: SKScene {

    private var selectedOption = 0
    private var cursorNode: SKLabelNode!
    private var stageNumber = 1
    private var stageLabel: SKLabelNode!
    private let maxStage = 888

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit

        // Title
        let title = SKLabelNode(text: "BATTLE CITY")
        title.fontName = "Courier-Bold"
        title.fontSize = 16
        title.fontColor = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
        title.position = CGPoint(x: Constants.logicalWidth / 2, y: 60)
        title.horizontalAlignmentMode = .center
        self.addChild(title)

        // Menu options
        let opt1 = SKLabelNode(text: "1 PLAYER")
        opt1.fontName = "Courier-Bold"
        opt1.fontSize = 10
        opt1.fontColor = .white
        opt1.position = CGPoint(x: Constants.logicalWidth / 2 + 10, y: 110)
        opt1.horizontalAlignmentMode = .center
        self.addChild(opt1)

        // Stage selector
        stageLabel = SKLabelNode(text: "STAGE  \(stageNumber)")
        stageLabel.fontName = "Courier-Bold"
        stageLabel.fontSize = 10
        stageLabel.fontColor = .white
        stageLabel.position = CGPoint(x: Constants.logicalWidth / 2 + 10, y: 130)
        stageLabel.horizontalAlignmentMode = .center
        self.addChild(stageLabel)

        // Stage arrows hint
        let arrows = SKLabelNode(text: "◂              ▸")
        arrows.fontName = "Courier-Bold"
        arrows.fontSize = 8
        arrows.fontColor = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 0.6)
        arrows.position = CGPoint(x: Constants.logicalWidth / 2 + 10, y: 130)
        arrows.horizontalAlignmentMode = .center
        self.addChild(arrows)

        // Cursor
        cursorNode = SKLabelNode(text: "▸")
        cursorNode.fontName = "Courier-Bold"
        cursorNode.fontSize = 10
        cursorNode.fontColor = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)
        cursorNode.position = CGPoint(x: Constants.logicalWidth / 2 - 40, y: 110)
        cursorNode.horizontalAlignmentMode = .center
        self.addChild(cursorNode)

        // Instructions
        let instr = SKLabelNode(text: "↑↓ SELECT  ←→ STAGE  ENTER START")
        instr.fontName = "Courier"
        instr.fontSize = 5
        instr.fontColor = SKColor(white: 0.6, alpha: 1)
        instr.position = CGPoint(x: Constants.logicalWidth / 2, y: 160)
        instr.horizontalAlignmentMode = .center
        self.addChild(instr)

        // Namco / credit
        let credit = SKLabelNode(text: "© 1985 NAMCO")
        credit.fontName = "Courier"
        credit.fontSize = 6
        credit.fontColor = SKColor(white: 0.4, alpha: 1)
        credit.position = CGPoint(x: Constants.logicalWidth / 2, y: 200)
        credit.horizontalAlignmentMode = .center
        self.addChild(credit)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36: // Enter
            startGame()
        case 126: // Up arrow
            selectedOption = 0
            updateCursor()
        case 125: // Down arrow
            selectedOption = 1
            updateCursor()
        case 123: // Left arrow
            if selectedOption == 1 {
                let step = event.modifierFlags.contains(.shift) ? 10 : 1
                stageNumber = max(1, stageNumber - step)
                updateStageLabel()
            }
        case 124: // Right arrow
            if selectedOption == 1 {
                let step = event.modifierFlags.contains(.shift) ? 10 : 1
                stageNumber = min(maxStage, stageNumber + step)
                updateStageLabel()
            }
        default:
            break
        }
    }

    private func updateCursor() {
        let y: CGFloat = selectedOption == 0 ? 110 : 130
        cursorNode.position = CGPoint(x: Constants.logicalWidth / 2 - 40, y: y)
    }

    private func updateStageLabel() {
        stageLabel.text = "STAGE  \(stageNumber)"
    }

    func startGame() {
        let stageScene = StageIntroScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
        stageScene.stageNumber = stageNumber
        stageScene.gameState = GameState()
        self.view?.presentScene(stageScene, transition: SKTransition.fade(with: .black, duration: 0.5))
    }
}
