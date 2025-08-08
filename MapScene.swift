import SpriteKit

final class MapScene: SKScene {
    private let game = Game.shared
    private var nodes: [ButtonNode] = []

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        let title = makeLabel("Choose your path", size: 20)
        title.position = CGPoint(x: size.width/2, y: size.height*0.8)
        addChild(title)

        if !game.run.flavor.isEmpty {
            let f = makeLabel(game.run.flavor, size: 14, color: .lightGray)
            f.position = CGPoint(x: size.width/2, y: size.height*0.74)
            addChild(f)
        }

        buildNodes()
    }

    private func buildNodes() {
        nodes.forEach { $0.removeFromParent() }
        nodes.removeAll()

        let spacing: CGFloat = 70
        let startY = size.height*0.6
        for (i, node) in game.run.nodes.enumerated() {
            let b = ButtonNode(text: titleFor(node.type), width: 260) { [weak self] in
                self?.selectNode(index: i, node: node)
            }
            b.position = CGPoint(x: size.width/2, y: startY - CGFloat(i)*spacing)
            addChild(b)
            nodes.append(b)
        }
    }

    private func selectNode(index: Int, node: MapNode) {
        game.run.cursor = index + 1
        switch node.type {
        case .combat:
            game.beginCombat(boss: false)
            let s = CombatScene(size: size)
            s.scaleMode = .resizeFill
            view?.presentScene(s, transition: .fade(withDuration: 0.2))
        case .boss:
            game.beginCombat(boss: true)
            let s = CombatScene(size: size)
            s.scaleMode = .resizeFill
            view?.presentScene(s, transition: .fade(withDuration: 0.2))
        case .shop:
            let s = InventoryScene(size: size)
            s.scaleMode = .resizeFill
            view?.presentScene(s, transition: .fade(withDuration: 0.2))
        case .repair:
            let heal = Int(Double(game.player.maxHP) * 0.3)
            game.player.hp = min(game.player.maxHP, game.player.hp + heal)
            runBack()
        case .mystery:
            let roll = Int.random(in: 0..<3)
            if roll == 0 { game.scrap += 25 }
            if roll == 1 { game.player.inventory.maxSlots += 1 }
            if roll == 2, let item = game.content.items.randomElement() { game.player.inventory.bag.append(item) }
            runBack()
        }
    }

    private func runBack() {
        game.nextMap()
        let m = MapScene(size: size)
        m.scaleMode = .resizeFill
        view?.presentScene(m, transition: .fade(withDuration: 0.2))
    }

    private func titleFor(_ t: NodeType) -> String {
        switch t {
        case .combat: return "Scrap Skirmish"
        case .shop: return "Shady Shop"
        case .mystery: return "Odd Encounter"
        case .repair: return "Repair Station"
        case .boss: return "Boss"
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !(game.ux.reduceMotion || game.performance.lowEffects) else { return }
        camera?.position.x = CGFloat(game.motion.roll) * 16
        camera?.position.y = CGFloat(-game.motion.pitch) * 16
    }
}
