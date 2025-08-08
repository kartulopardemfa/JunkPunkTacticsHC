import SpriteKit

final class InventoryScene: SKScene {
    private let game = Game.shared

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        let title = makeLabel("Loadout", size: 24)
        title.position = CGPoint(x: size.width*0.5, y: size.height*0.82)
        addChild(title)

        buildWeapons()
        buildItems()

        let back = ButtonNode(text: "Back to Map", width: 240) { [weak self] in
            guard let self else { return }
            if self.game.run.enemyIsBoss { self.game.afterBoss() }
            self.game.nextMap()
            let m = MapScene(size: self.size)
            m.scaleMode = .resizeFill
            self.view?.presentScene(m, transition: .fade(withDuration: 0.25))
        }
        back.position = CGPoint(x: size.width*0.5, y: size.height*0.12)
        addChild(back)
    }

    private func buildWeapons() {
        let label = makeLabel("Active Weapons", size: 18)
        label.position = CGPoint(x: size.width*0.5, y: size.height*0.72)
        addChild(label)

        for (idx, w) in game.player.inventory.active.enumerated() {
            let b = ButtonNode(text: "\(w.name) \(w.minDmg)-\(w.maxDmg) \(w.ap)AP", width: 300) { [weak self] in
                guard let self else { return }
                if let other = self.game.content.weapons.filter({ !self.game.player.inventory.active.contains($0) }).randomElement() {
                    self.game.player.inventory.active[idx] = other
                    if let v = self.view {
                        let fresh = InventoryScene(size: self.size)
                        fresh.scaleMode = .resizeFill
                        v.presentScene(fresh, transition: .fade(withDuration: 0.15))
                    }
                }
            }
            b.position = CGPoint(x: size.width*0.5, y: size.height*(0.64 - CGFloat(idx)*0.08))
            addChild(b)
        }
    }

    private func buildItems() {
        let bagLabel = makeLabel("Bag", size: 18)
        bagLabel.position = CGPoint(x: size.width*0.5, y: size.height*0.52)
        addChild(bagLabel)

        let startY = size.height*0.46
        var x: CGFloat = size.width*0.15
        var y: CGFloat = startY

        for it in game.player.inventory.bag {
            let b = ButtonNode(text: chipText(it), width: 180, height: 48) { [weak self] in
                self?.game.player.inventory.toggle(it)
                if let v = self?.view {
                    let fresh = InventoryScene(size: self!.size)
                    fresh.scaleMode = .resizeFill
                    v.presentScene(fresh, transition: .fade(withDuration: 0.15))
                }
            }
            b.position = CGPoint(x: x, y: y)
            addChild(b)
            x += 190
            if x > size.width*0.85 {
                x = size.width*0.15
                y -= 58
            }
        }

        let slLabel = makeLabel("Slotted \(game.player.inventory.slotted.count)/\(game.player.inventory.maxSlots)", size: 18)
        slLabel.position = CGPoint(x: size.width*0.5, y: y - 30)
        addChild(slLabel)
    }

    private func chipText(_ item: Item) -> String {
        "\(item.kind == .consumable ? "💉" : "🛠") \(item.name)"
    }
}
