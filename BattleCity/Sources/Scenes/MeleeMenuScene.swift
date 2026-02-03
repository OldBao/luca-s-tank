import SpriteKit

class MeleeMenuScene: SKScene {

    var meleeConfig: MeleeConfig!

    private enum Field {
        case mapSize
        case playerColor
        case totalTanks
        case basicCount
        case basicHP
        case fastCount
        case fastHP
        case powerCount
        case powerHP
        case armorCount
        case armorHP
        case start
    }

    private let fields: [Field] = [
        .mapSize,
        .playerColor,
        .totalTanks,
        .basicCount,
        .basicHP,
        .fastCount,
        .fastHP,
        .powerCount,
        .powerHP,
        .armorCount,
        .armorHP,
        .start
    ]

    private var selectedFieldIndex = 0
    private var cursorNode: SKLabelNode!

    private var mapSizeLabel: SKLabelNode!
    private var colorLabel: SKLabelNode!
    private var totalLabel: SKLabelNode!
    private var remainingLabel: SKLabelNode!
    private var countLabels: [EnemyType: SKLabelNode] = [:]
    private var hpLabels: [EnemyType: SKLabelNode] = [:]

    private var lastEditedType: EnemyType?

    private let labelX: CGFloat = 30
    private let valueX: CGFloat = 130
    private let hpValueX: CGFloat = 190
    private let cursorXLeft: CGFloat = 20
    private let cursorXRight: CGFloat = 160

    private let yMap: CGFloat = 80
    private let yColor: CGFloat = 92
    private let yTotal: CGFloat = 104
    private let yHeader: CGFloat = 118
    private let yBasic: CGFloat = 132
    private let yFast: CGFloat = 144
    private let yPower: CGFloat = 156
    private let yArmor: CGFloat = 168
    private let yStart: CGFloat = 186

    private var fieldPositions: [Field: CGPoint] = [:]

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit

        if meleeConfig == nil {
            meleeConfig = MeleeConfig()
        }

        let orange = SKColor(red: 252/255, green: 152/255, blue: 56/255, alpha: 1)

        // Title
        let title = SKLabelNode(text: "MELEE MODE")
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = orange
        title.position = CGPoint(x: Constants.logicalWidth / 2, y: 50)
        title.horizontalAlignmentMode = .center
        self.addChild(title)

        // Field labels
        addLabel(text: "MAP SIZE:", x: labelX, y: yMap)
        addLabel(text: "YOUR COLOR:", x: labelX, y: yColor)
        addLabel(text: "TOTAL TANKS:", x: labelX, y: yTotal)

        let header = SKLabelNode(text: "YOUR TEAM (MIRRORED TO AI)")
        header.fontName = "Courier-Bold"
        header.fontSize = 6
        header.fontColor = SKColor(white: 0.8, alpha: 1)
        header.position = CGPoint(x: labelX, y: yHeader)
        header.horizontalAlignmentMode = .left
        self.addChild(header)

        addLabel(text: "BASIC:", x: labelX, y: yBasic)
        addLabel(text: "FAST:", x: labelX, y: yFast)
        addLabel(text: "POWER:", x: labelX, y: yPower)
        addLabel(text: "ARMOR:", x: labelX, y: yArmor)
        addLabel(text: "START BATTLE", x: labelX, y: yStart)

        // Value labels
        mapSizeLabel = valueLabel(text: meleeConfig.mapSize.label, x: valueX, y: yMap)
        colorLabel = valueLabel(text: meleeConfig.playerColor.name, x: valueX, y: yColor)
        totalLabel = valueLabel(text: "\(meleeConfig.totalTanks)", x: valueX, y: yTotal)
        remainingLabel = valueLabel(text: "Remaining: \(meleeConfig.remainingTanks)",
                                     x: hpValueX - 20, y: yTotal)

        createTankRowLabels(type: .basic, y: yBasic)
        createTankRowLabels(type: .fast, y: yFast)
        createTankRowLabels(type: .power, y: yPower)
        createTankRowLabels(type: .armor, y: yArmor)

        // Cursor positions
        fieldPositions = [
            .mapSize: CGPoint(x: cursorXLeft, y: yMap),
            .playerColor: CGPoint(x: cursorXLeft, y: yColor),
            .totalTanks: CGPoint(x: cursorXLeft, y: yTotal),
            .basicCount: CGPoint(x: cursorXLeft, y: yBasic),
            .basicHP: CGPoint(x: cursorXRight, y: yBasic),
            .fastCount: CGPoint(x: cursorXLeft, y: yFast),
            .fastHP: CGPoint(x: cursorXRight, y: yFast),
            .powerCount: CGPoint(x: cursorXLeft, y: yPower),
            .powerHP: CGPoint(x: cursorXRight, y: yPower),
            .armorCount: CGPoint(x: cursorXLeft, y: yArmor),
            .armorHP: CGPoint(x: cursorXRight, y: yArmor),
            .start: CGPoint(x: cursorXLeft, y: yStart)
        ]

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
        instr.position = CGPoint(x: Constants.logicalWidth / 2, y: 204)
        instr.horizontalAlignmentMode = .center
        self.addChild(instr)
    }

    private func addLabel(text: String, x: CGFloat, y: CGFloat) {
        let label = SKLabelNode(text: text)
        label.fontName = "Courier-Bold"
        label.fontSize = 7
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.horizontalAlignmentMode = .left
        self.addChild(label)
    }

    private func valueLabel(text: String, x: CGFloat, y: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Courier-Bold"
        label.fontSize = 7
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.horizontalAlignmentMode = .left
        self.addChild(label)
        return label
    }

    private func createTankRowLabels(type: EnemyType, y: CGFloat) {
        let countLabel = valueLabel(text: "\(count(for: type))", x: valueX, y: y)
        let hpLabel = valueLabel(text: "HP: \(hp(for: type))", x: hpValueX, y: y)
        countLabels[type] = countLabel
        hpLabels[type] = hpLabel
    }

    private func count(for type: EnemyType) -> Int {
        meleeConfig.teamConfig.tanks[type]?.count ?? 0
    }

    private func hp(for type: EnemyType) -> Int {
        meleeConfig.teamConfig.tanks[type]?.hp ?? 1
    }

    private func updateCursor() {
        let field = fields[selectedFieldIndex]
        if let pos = fieldPositions[field] {
            cursorNode.position = pos
        }
    }

    private func updateValueLabels() {
        mapSizeLabel.text = meleeConfig.mapSize.label
        colorLabel.text = meleeConfig.playerColor.name
        totalLabel.text = "\(meleeConfig.totalTanks)"
        remainingLabel.text = "Remaining: \(meleeConfig.remainingTanks)"

        for type in [EnemyType.basic, .fast, .power, .armor] {
            countLabels[type]?.text = "\(count(for: type))"
            hpLabels[type]?.text = "HP: \(hp(for: type))"
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            let scene = MenuScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
            self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))

        case 36: // Enter
            if fields[selectedFieldIndex] == .start {
                let playArea = CGFloat(meleeConfig.mapSize.tiles) * Constants.tileSize
                let scene = MeleeGameScene(size: CGSize(width: playArea, height: playArea))
                scene.meleeConfig = meleeConfig
                self.view?.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.5))
            }

        case 126: // Up
            selectedFieldIndex = max(0, selectedFieldIndex - 1)
            updateCursor()

        case 125: // Down
            selectedFieldIndex = min(fields.count - 1, selectedFieldIndex + 1)
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
        switch fields[selectedFieldIndex] {
        case .mapSize:
            let cases = MapSize.allCases
            if let idx = cases.firstIndex(of: meleeConfig.mapSize) {
                let newIdx = (idx + delta + cases.count) % cases.count
                meleeConfig.mapSize = cases[newIdx]
            }
        case .playerColor:
            let cases = TeamColor.allCases
            if let idx = cases.firstIndex(of: meleeConfig.playerColor) {
                let newIdx = (idx + delta + cases.count) % cases.count
                meleeConfig.setPlayerColor(cases[newIdx])
            }
        case .totalTanks:
            meleeConfig.adjustTotalTanks(to: meleeConfig.totalTanks + delta, lastEdited: lastEditedType)
        case .basicCount:
            if meleeConfig.adjustCount(for: .basic, delta: delta) { lastEditedType = .basic }
        case .basicHP:
            meleeConfig.adjustHP(for: .basic, delta: delta)
        case .fastCount:
            if meleeConfig.adjustCount(for: .fast, delta: delta) { lastEditedType = .fast }
        case .fastHP:
            meleeConfig.adjustHP(for: .fast, delta: delta)
        case .powerCount:
            if meleeConfig.adjustCount(for: .power, delta: delta) { lastEditedType = .power }
        case .powerHP:
            meleeConfig.adjustHP(for: .power, delta: delta)
        case .armorCount:
            if meleeConfig.adjustCount(for: .armor, delta: delta) { lastEditedType = .armor }
        case .armorHP:
            meleeConfig.adjustHP(for: .armor, delta: delta)
        case .start:
            break
        }
        updateValueLabels()
    }
}
