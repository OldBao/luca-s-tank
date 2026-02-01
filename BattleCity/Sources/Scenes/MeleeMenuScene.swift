import SpriteKit

class MeleeMenuScene: SKScene {

    var meleeConfig: MeleeConfig!

    private var selectedField = 0
    private var fieldCount = 5
    private var cursorNode: SKLabelNode!

    // Labels that need updating
    private var mapSizeLabel: SKLabelNode!
    private var colorLabel: SKLabelNode!
    private var tanksLabel: SKLabelNode!
    private var hpLabel: SKLabelNode!

    // Simplified config values
    private var tanksPerTeam: Int = 5
    private var tankHP: Int = 3

    // Field Y positions (NES-style, origin at top-left, but SpriteKit Y=0 at bottom)
    // We'll use SpriteKit coords directly
    private let fieldYPositions: [CGFloat] = [70, 88, 106, 124, 152]
    private let fieldLabels = ["MAP SIZE:", "YOUR COLOR:", "TANKS/TEAM:", "TANK HP:", "START BATTLE"]

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit

        if meleeConfig == nil {
            meleeConfig = MeleeConfig()
        }

        // Sync simplified values from config
        tanksPerTeam = meleeConfig.teams[0].totalTanks
        if tanksPerTeam == 0 { tanksPerTeam = 5 }
        if let firstType = meleeConfig.teams[0].tanks.values.first {
            tankHP = firstType.hp
        }

        let orange = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)

        // Title
        let title = SKLabelNode(text: "MELEE MODE")
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = orange
        title.position = CGPoint(x: Constants.logicalWidth / 2, y: 40)
        title.horizontalAlignmentMode = .center
        self.addChild(title)

        // Fields
        let labelX: CGFloat = 30
        let valueX: CGFloat = 170

        for i in 0..<fieldCount {
            let label = SKLabelNode(text: fieldLabels[i])
            label.fontName = "Courier-Bold"
            label.fontSize = 7
            label.fontColor = .white
            label.position = CGPoint(x: labelX, y: fieldYPositions[i])
            label.horizontalAlignmentMode = .left
            self.addChild(label)
        }

        // Value labels
        mapSizeLabel = SKLabelNode(text: meleeConfig.mapSize.label)
        mapSizeLabel.fontName = "Courier-Bold"
        mapSizeLabel.fontSize = 7
        mapSizeLabel.fontColor = .white
        mapSizeLabel.position = CGPoint(x: valueX, y: fieldYPositions[0])
        mapSizeLabel.horizontalAlignmentMode = .left
        self.addChild(mapSizeLabel)

        colorLabel = SKLabelNode(text: meleeConfig.playerColor.name)
        colorLabel.fontName = "Courier-Bold"
        colorLabel.fontSize = 7
        colorLabel.fontColor = .white
        colorLabel.position = CGPoint(x: valueX, y: fieldYPositions[1])
        colorLabel.horizontalAlignmentMode = .left
        self.addChild(colorLabel)

        tanksLabel = SKLabelNode(text: "\(tanksPerTeam)")
        tanksLabel.fontName = "Courier-Bold"
        tanksLabel.fontSize = 7
        tanksLabel.fontColor = .white
        tanksLabel.position = CGPoint(x: valueX, y: fieldYPositions[2])
        tanksLabel.horizontalAlignmentMode = .left
        self.addChild(tanksLabel)

        hpLabel = SKLabelNode(text: "\(tankHP)")
        hpLabel.fontName = "Courier-Bold"
        hpLabel.fontSize = 7
        hpLabel.fontColor = .white
        hpLabel.position = CGPoint(x: valueX, y: fieldYPositions[3])
        hpLabel.horizontalAlignmentMode = .left
        self.addChild(hpLabel)

        // Cursor
        cursorNode = SKLabelNode(text: "\u{25B8}")
        cursorNode.fontName = "Courier-Bold"
        cursorNode.fontSize = 8
        cursorNode.fontColor = orange
        cursorNode.horizontalAlignmentMode = .center
        updateCursor()
        self.addChild(cursorNode)

        // Instructions
        let instr = SKLabelNode(text: "\u{2191}\u{2193} SELECT  \u{2190}\u{2192} ADJUST  ENTER START  ESC BACK")
        instr.fontName = "Courier"
        instr.fontSize = 5
        instr.fontColor = SKColor(white: 0.5, alpha: 1)
        instr.position = CGPoint(x: Constants.logicalWidth / 2, y: 180)
        instr.horizontalAlignmentMode = .center
        self.addChild(instr)
    }

    private func updateCursor() {
        cursorNode.position = CGPoint(x: 20, y: fieldYPositions[selectedField])
    }

    private func updateValueLabels() {
        mapSizeLabel.text = meleeConfig.mapSize.label
        colorLabel.text = meleeConfig.playerColor.name
        tanksLabel.text = "\(tanksPerTeam)"
        hpLabel.text = "\(tankHP)"
    }

    private func applySimplifiedConfig() {
        // Distribute tanks evenly: basic gets extra if not divisible
        let perType = tanksPerTeam / 4
        let remainder = tanksPerTeam % 4
        let types: [EnemyType] = [.basic, .fast, .power, .armor]

        for i in 0..<4 {
            var tankDict: [EnemyType: TankTypeConfig] = [:]
            for (j, t) in types.enumerated() {
                let count = perType + (j < remainder ? 1 : 0)
                tankDict[t] = TankTypeConfig(count: count, hp: tankHP)
            }
            meleeConfig.teams[i].tanks = tankDict
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            let scene = MenuScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
            self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))

        case 36: // Enter
            if selectedField == 4 {
                applySimplifiedConfig()
                let scene = MeleeGameScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
                scene.meleeConfig = meleeConfig
                self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
            }

        case 126: // Up
            selectedField = max(0, selectedField - 1)
            updateCursor()

        case 125: // Down
            selectedField = min(fieldCount - 1, selectedField + 1)
            updateCursor()

        case 123: // Left
            adjustField(delta: -1)

        case 124: // Right
            adjustField(delta: 1)

        default:
            break
        }
    }

    private func adjustField(delta: Int) {
        switch selectedField {
        case 0: // Map size
            let cases = MapSize.allCases
            if let idx = cases.firstIndex(of: meleeConfig.mapSize) {
                let newIdx = (idx + delta + cases.count) % cases.count
                meleeConfig.mapSize = cases[newIdx]
            }
        case 1: // Player color
            let cases = TeamColor.allCases
            if let idx = cases.firstIndex(of: meleeConfig.playerColor) {
                let newIdx = (idx + delta + cases.count) % cases.count
                meleeConfig.setPlayerColor(cases[newIdx])
            }
        case 2: // Tanks per team
            tanksPerTeam = max(1, min(9, tanksPerTeam + delta))
        case 3: // Tank HP
            tankHP = max(1, min(9, tankHP + delta))
        default:
            break
        }
        updateValueLabels()
    }
}
