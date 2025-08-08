import SpriteKit

final class MetaScene: SKScene {
    private let game = Game.shared

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        let title = makeLabel("Workshop", size: 28)
        title.position = CGPoint(x: size.width*0.5, y: size.height*0.78)
        addChild(title)

        let gears = makeLabel("Gears \(game.meta.gears)", size: 18)
        gears.position = CGPoint(x: size.width*0.5, y: size.height*0.72)
        addChild(gears)

        var y = size.height*0.62
        addUpgradeRow(name: "Spare Battery", desc: "+1 AP on turn one.", cost: 1, owned: game.meta.apTurnOne > 0, y: y) { [weak self] in
            guard let self else { return }
            if self.game.meta.gears >= 1 && self.game.meta.apTurnOne == 0 {
                self.game.meta.gears -= 1; self.game.meta.apTurnOne = 1; self.game.save.save(self.game.meta); self.didMove(to: self.view!)
            }
        }
        y -= 70
        addUpgradeRow(name: "Extra Plating", desc: "+10 Max HP.", cost: 2, owned: game.meta.hpBonus > 0, y: y) { [weak self] in
            guard let self else { return }
            if self.game.meta.gears >= 2 && self.game.meta.hpBonus == 0 {
                self.game.meta.gears -= 2; self.game.meta.hpBonus = 10; self.game.save.save(self.game.meta); self.didMove(to: self.view!)
            }
        }
        y -= 70
        addUpgradeRow(name: "Tool Belt", desc: "+1 item slot.", cost: 2, owned: game.meta.extraSlots > 0, y: y) { [weak self] in
            guard let self else { return }
            if self.game.meta.gears >= 2 && self.game.meta.extraSlots == 0 {
                self.game.meta.gears -= 2; self.game.meta.extraSlots = 1; self.game.save.save(self.game.meta); self.didMove(to: self.view!)
            }
        }

        let back = ButtonNode(text: "Back", width: 220) { [weak self] in
            guard let self else { return }
            let menu = MainMenuScene(size: self.size)
            menu.scaleMode = .resizeFill
            self.view?.presentScene(menu, transition: .fade(withDuration: 0.25))
        }
        back.position = CGPoint(x: size.width*0.5, y: size.height*0.14)
        addChild(back)
    }

    private func addUpgradeRow(name: String, desc: String, cost: Int, owned: Bool, y: CGFloat, tap: @escaping()->Void) {
        let title = makeLabel(name, size: 18)
        title.position = CGPoint(x: size.width*0.35, y: y)
        addChild(title)
        let d = makeLabel(desc, size: 12, color: .lightGray)
        d.position = CGPoint(x: size.width*0.35, y: y - 18)
        addChild(d)
        let c = makeLabel(owned ? "Owned" : "Cost \(cost)", size: 12, color: owned ? .systemGreen : .systemYellow)
        c.position = CGPoint(x: size.width*0.35, y: y - 34)
        addChild(c)
        let buy = ButtonNode(text: owned ? "—" : "Buy", width: 120, height: 40, action: tap)
        buy.position = CGPoint(x: size.width*0.7, y: y - 12)
        addChild(buy)
    }
}
