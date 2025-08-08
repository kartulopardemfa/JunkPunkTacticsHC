import SpriteKit
import UIKit

final class ReelColumn: SKNode {
    private let tileSize = CGSize(width: 90, height: 90)
    private let bg: SKShapeNode
    private let curr: SKSpriteNode
    private let next: SKSpriteNode
    private let symbols: [String]
    private(set) var index: Int = 0

    init(symbols: [String]) {
        self.symbols = symbols
        bg = SKShapeNode(rectOf: CGSize(width: 90, height: 90), cornerRadius: 10)
        bg.fillColor = .white.withAlphaComponent(0.06)
        bg.strokeColor = .clear

        curr = SKSpriteNode(color: .clear, size: tileSize)
        next = SKSpriteNode(color: .clear, size: tileSize)

        super.init()
        isUserInteractionEnabled = false

        addChild(bg)
        addChild(curr)
        addChild(next)

        curr.position = .zero
        next.position = CGPoint(x: 0, y: -tileSize.height)

        apply(symbol: symbols.first ?? "🔧", to: curr)
        apply(symbol: symbols[safe: 1] ?? "💉", to: next)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var currentSymbol: String { symbols[index] }

    func spin(steps: Int, interval: Double, completion: @escaping () -> Void) {
        guard steps > 0 else { completion(); return }
        let one = SKAction.sequence([
            .run { [weak self] in self?.tick() },
            .wait(forDuration: interval)
        ])
        let spin = SKAction.repeat(one, count: steps)
        run(spin) { [weak self] in
            guard let self else { completion(); return }
            let bounce = SKAction.sequence([
                .moveBy(x: 0, y: 4, duration: 0.06),
                .moveBy(x: 0, y: -4, duration: 0.06)
            ])
            self.curr.run(bounce)
            completion()
        }
    }

    private func tick() {
        index = (index + 1) % symbols.count
        let nextSym = symbols[index]
        apply(symbol: nextSym, to: next)

        let up = SKAction.moveBy(x: 0, y: tileSize.height, duration: 0.085)
        up.timingMode = .easeOut

        curr.run(up)
        next.run(up) { [weak self] in
            guard let self else { return }
            self.curr.texture = self.next.texture
            self.curr.color = self.next.color
            self.curr.removeAllChildren()
            for kid in self.next.children { self.curr.addChild(kid.copy() as! SKNode) }
            self.curr.position = .zero
            self.next.position = CGPoint(x: 0, y: -self.tileSize.height)
            self.next.texture = nil
            self.next.color = .clear
            self.next.removeAllChildren()
        }
    }

    private func apply(symbol: String, to node: SKSpriteNode) {
        let map: [String:String] = [
            "🔧":"reel_wrench","💉":"reel_med","🎯":"reel_target","⚡️":"reel_bolt",
            "🧪":"reel_chem","🧲":"reel_magnet","🛡️":"reel_shield","💥":"reel_boom"
        ]
        if let name = map[symbol], let tex = TextureService.shared.texture(named: name) {
            node.texture = tex
            node.color = .clear
            node.removeAllChildren()
        } else {
            node.texture = nil
            node.color = .white.withAlphaComponent(0.06)
            node.removeAllChildren()
            let l = SKLabelNode(fontNamed: "Avenir-Heavy")
            l.text = symbol
            l.fontSize = 40
            l.fontColor = .white
            l.verticalAlignmentMode = .center
            l.position = .zero
            node.addChild(l)
        }
    }
}

final class SlotScene: SKScene {
    private let game = Game.shared

    private var reelsSymbols: [[String]] = [
        ["🔧","💉","🎯","⚡️","🧪","🧲","🛡️","💥"],
        ["🔧","💉","🎯","⚡️","🧪","🧲","🛡️","💥"],
        ["🔧","💉","🎯","⚡️","🧪","🧲","🛡️","💥"]
    ]

    private var columns: [ReelColumn] = []
    private var spinning = false
    private var pulls = 1

    private let header = SKLabelNode(fontNamed: "Avenir-Heavy")

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        header.text = "Slot pulls \(pulls)"
        header.fontSize = 20
        header.position = CGPoint(x: size.width*0.5, y: size.height*0.78)
        addChild(header)

        let y = size.height*0.58
        let startX = size.width*0.35
        for i in 0..<3 {
            let col = ReelColumn(symbols: reelsSymbols[i])
            col.position = CGPoint(x: startX + CGFloat(i)*100, y: y)
            addChild(col)
            columns.append(col)
        }

        let spin = ButtonNode(text: "Spin", width: 240) { [weak self] in self?.spin() }
        spin.position = CGPoint(x: size.width*0.5, y: size.height*0.32)
        addChild(spin)

        let cont = ButtonNode(text: "Continue", width: 240) { [weak self] in
            guard let self else { return }
            let inv = InventoryScene(size: self.size)
            inv.scaleMode = .resizeFill
            self.view?.presentScene(inv, transition: .fade(withDuration: 0.25))
        }
        cont.position = CGPoint(x: size.width*0.5, y: size.height*0.18)
        addChild(cont)
    }

    private func spin() {
        guard pulls > 0, !spinning else { return }
        pulls -= 1
        header.text = "Slot pulls \(pulls)"
        spinning = true

        columns[0].spin(steps: Int.random(in: 16...24), interval: 0.06) { [weak self] in
            guard let self else { return }
            self.columns[1].spin(steps: Int.random(in: 20...28), interval: 0.08) { [weak self] in
                guard let self else { return }
                self.columns[2].spin(steps: Int.random(in: 24...34), interval: 0.10) { [weak self] in
                    self?.spinning = false
                    self?.grantPrize()
                }
            }
        }
    }

    private func grantPrize() {
        let s0 = columns[0].currentSymbol
        let s1 = columns[1].currentSymbol
        let s2 = columns[2].currentSymbol
        let symbols = [s0, s1, s2]
        let counts = Dictionary(grouping: symbols, by: { $0 }).mapValues { $0.count }
        var pay = 10
        if let top = counts.max(by: { $0.value < $1.value }), top.value >= 2 {
            pay = 20
            if let it = game.content.items.randomElement() { game.player.inventory.bag.append(it) }
        }
        game.scrap += pay
        let msg = makeLabel("+\(pay) scrap", size: 16, color: .yellow)
        msg.position = CGPoint(x: size.width*0.5, y: size.height*0.44)
        addChild(msg)
        msg.run(.sequence([.fadeIn(withDuration: 0.1), .wait(forDuration: 0.8), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    override func update(_ currentTime: TimeInterval) {
        guard !(game.ux.reduceMotion || game.performance.lowEffects) else { return }
        camera?.position.x = CGFloat(game.motion.roll) * 16
        camera?.position.y = CGFloat(-game.motion.pitch) * 16
    }
}

private extension Array { subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil } }
