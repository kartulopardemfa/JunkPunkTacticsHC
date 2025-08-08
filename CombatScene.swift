import SpriteKit

final class CombatScene: SKScene {
    private let game = Game.shared

    private let heroNode = SKSpriteNode(color: .systemGreen.withAlphaComponent(0.25), size: CGSize(width: 120, height: 120))
    private let enemyNode = SKSpriteNode(color: .systemRed.withAlphaComponent(0.25), size: CGSize(width: 140, height: 140))
    private let flash = SKSpriteNode(color: .white, size: .zero)
    private let damageLayer = SKNode()
    private let uiLayer = SKNode()

    private let heatBarBG = SKShapeNode(rectOf: CGSize(width: 220, height: 10), cornerRadius: 5)
    private let heatBarFG = SKShapeNode()
    private let playerHPBG = SKShapeNode(rectOf: CGSize(width: 200, height: 12), cornerRadius: 6)
    private let playerHPFG = SKShapeNode()
    private let enemyHPBG = SKShapeNode(rectOf: CGSize(width: 220, height: 12), cornerRadius: 6)
    private let enemyHPFG = SKShapeNode()

    private var comboValue: Double = 0
    private var overdrive: Bool = false

    private var targetOverlay: SKNode?
    private var pauseOverlay: SKNode?
    private var chosenWeapon: Weapon?

    private var apLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private var logLabel = SKLabelNode(fontNamed: "Avenir-Heavy")

    private var touchStart: CGPoint?
    private var isPausedGame = false

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        buildArena()
        buildUI()
        layoutForHand()
        game.motion.start()
        updateHPBars()
    }

    private func layoutForHand() {
        let leftHand = game.ux.handedness == .left
        let safe = game.safeInsets
        let bottomY = safe.bottom + 24

        if leftHand {
            heroNode.position = CGPoint(x: size.width * 0.78, y: size.height * 0.28)
            enemyNode.position = CGPoint(x: size.width * 0.25, y: size.height * 0.55)
        } else {
            heroNode.position = CGPoint(x: size.width * 0.22, y: size.height * 0.28)
            enemyNode.position = CGPoint(x: size.width * 0.75, y: size.height * 0.55)
        }

        if let btn1 = uiLayer.childNode(withName: "w1"), let btn2 = uiLayer.childNode(withName: "w2") {
            if leftHand {
                btn1.position = CGPoint(x: size.width*0.7, y: bottomY + 40)
                btn2.position = CGPoint(x: size.width*0.3, y: bottomY + 40)
            } else {
                btn1.position = CGPoint(x: size.width*0.3, y: bottomY + 40)
                btn2.position = CGPoint(x: size.width*0.7, y: bottomY + 40)
            }
        }

        apLabel.position = CGPoint(x: size.width*0.5, y: bottomY + 90)
        heatBarBG.position = CGPoint(x: size.width*0.5, y: bottomY + 70)
        heatBarFG.position = heatBarBG.position

        playerHPBG.position = CGPoint(x: size.width*0.5, y: bottomY + 120)
        playerHPFG.position = playerHPBG.position

        enemyHPBG.position = CGPoint(x: size.width*0.5, y: size.height - safe.top - 40)
        enemyHPFG.position = enemyHPBG.position

        logLabel.position = CGPoint(x: size.width*0.5, y: bottomY + 140)

        if let pause = uiLayer.childNode(withName: "pause") {
            let px = game.ux.handedness == .left ? size.width - 60 - safe.right : 60 + safe.left
            pause.position = CGPoint(x: px, y: size.height - safe.top - 26)
        }
    }

    private func buildArena() {
        flash.size = size
        flash.alpha = 0
        flash.zPosition = 1000
        addChild(flash)

        addChild(heroNode); addChild(enemyNode)
        addChild(damageLayer)
    }

    private func buildUI() {
        addChild(uiLayer)

        apLabel.text = "AP \(game.player.currentAP)"
        apLabel.fontSize = 20
        uiLayer.addChild(apLabel)

        heatBarBG.fillColor = .white.withAlphaComponent(0.06)
        heatBarBG.strokeColor = .clear
        uiLayer.addChild(heatBarBG)

        heatBarFG.strokeColor = .clear
        heatBarFG.fillColor = .systemGreen
        uiLayer.addChild(heatBarFG)

        playerHPBG.fillColor = .white.withAlphaComponent(0.06)
        playerHPBG.strokeColor = .clear
        uiLayer.addChild(playerHPBG)

        playerHPFG.strokeColor = .clear
        playerHPFG.fillColor = .systemGreen
        uiLayer.addChild(playerHPFG)

        enemyHPBG.fillColor = .white.withAlphaComponent(0.06)
        enemyHPBG.strokeColor = .clear
        uiLayer.addChild(enemyHPBG)

        enemyHPFG.strokeColor = .clear
        enemyHPFG.fillColor = .systemRed
        uiLayer.addChild(enemyHPFG)

        let w1 = buttonForWeapon(game.player.inventory.active[safe: 0]); w1.name = "w1"
        let w2 = buttonForWeapon(game.player.inventory.active[safe: 1]); w2.name = "w2"
        uiLayer.addChild(w1); uiLayer.addChild(w2)

        let endButton = ButtonNode(text: "End Turn", width: 240) { [weak self] in
            guard let self, !self.isPausedGame else { return }
            self.endPlayerTurn()
        }
        endButton.position = CGPoint(x: size.width*0.5, y: game.safeInsets.bottom + 16)
        uiLayer.addChild(endButton)

        let pause = ButtonNode(text: "Pause", width: 100, height: 44) { [weak self] in self?.showPauseOverlay() }
        pause.name = "pause"
        uiLayer.addChild(pause)

        logLabel.fontSize = 12
        logLabel.fontColor = .lightGray
        uiLayer.addChild(logLabel)

        layoutForHand()
        redrawHeatBar()
    }

    private func buttonForWeapon(_ w: Weapon?) -> ButtonNode {
        let name = w?.name ?? "—"
        return ButtonNode(text: "\(name)  \(w?.ap ?? 0)AP", width: 260) { [weak self] in
            guard let self, let w, !self.isPausedGame else { return }
            if self.game.player.currentAP >= w.ap {
                self.chosenWeapon = w
                self.showTargetMiniGame(baseAcc: self.game.player.baseAcc + w.acc + self.passiveAcc(),
                                        jamPenalty: self.game.run.enemy?.jamNext ?? 0)
            }
        }
    }

    private func passiveAcc() -> Double {
        var acc: Double = 0
        for p in game.player.inventory.slotted where p.kind == .passive {
            for t in p.tags { if t.hasPrefix("acc:") { acc += Double(t.split(separator: ":")[1]) ?? 0 } }
        }
        return acc
    }

    private func showTargetMiniGame(baseAcc: Double, jamPenalty: Double) {
        targetOverlay?.removeFromParent()

        let overlay = SKNode()
        overlay.zPosition = 50
        addChild(overlay)
        targetOverlay = overlay

        let cx = size.width*0.5
        let cy = game.safeInsets.bottom + 180
        let ring = SKShapeNode(circleOfRadius: 110)
        ring.strokeColor = .white.withAlphaComponent(0.15)
        ring.lineWidth = 2
        ring.position = CGPoint(x: cx, y: cy)
        overlay.addChild(ring)

        let sweetR: CGFloat = 50 + CGFloat(baseAcc * 30)
        let sweet = SKShapeNode(circleOfRadius: sweetR)
        sweet.fillColor = .systemGreen.withAlphaComponent(0.2)
        sweet.strokeColor = .systemGreen.withAlphaComponent(0.6)
        sweet.lineWidth = 3
        sweet.position = CGPoint(x: cx, y: cy)
        overlay.addChild(sweet)

        let cursor = SKShapeNode(circleOfRadius: 20)
        cursor.strokeColor = .white
        cursor.lineWidth = 4
        cursor.position = CGPoint(x: cx, y: cy)
        overlay.addChild(cursor)

        var grow = true
        let action = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                let r = cursor.frame.width / 2
                let minR: CGFloat = 20, maxR: CGFloat = 110
                let step: CGFloat = 2.8
                let next = r + (grow ? step : -step)
                cursor.path = CGPath(ellipseIn: CGRect(x: -next, y: -next, width: next*2, height: next*2), transform: nil)
                if next >= maxR { grow = false }
                if next <= minR { grow = true }
            },
            SKAction.wait(forDuration: 1.0/60.0)
        ]))
        cursor.run(action)

        let tap = ButtonNode(text: "Tap To Shoot", width: 220) { [weak self] in
            guard let self, let w = self.chosenWeapon else { return }
            let diff = abs((cursor.frame.width/2) - sweetR)
            let maxDiff: CGFloat = 110
            let score = max(0.0, 1.0 - Double(diff / maxDiff)).clamped(0, 1)
            self.resolveAttack(w, scoreBonus: score, jamPenalty: jamPenalty)
            overlay.removeFromParent()
            self.targetOverlay = nil
        }
        tap.position = CGPoint(x: cx, y: cy - 140)
        overlay.addChild(tap)
    }

    private func buildNumbers(for w: Weapon, score: Double) -> (acc: Double, crit: Double, mult: Double) {
        var acc = game.player.baseAcc + w.acc + score * 0.28 + game.meta.accBonus
        var crit = game.player.baseCrit + w.crit + score * 0.12 + game.meta.critBonus
        var mult = 1.0 + game.meta.dmgBonus
        for p in game.player.inventory.slotted where p.kind == .passive {
            for t in p.tags {
                if t.hasPrefix("acc:") { acc += Double(t.split(separator: ":")[1]) ?? 0 }
                if t.hasPrefix("crit:") { crit += Double(t.split(separator: ":")[1]) ?? 0 }
                if t.hasPrefix("dmg:") { mult += Double(t.split(separator: ":")[1]) ?? 0 }
            }
        }
        return (acc.clamped(0.05, 0.98), crit.clamped(0.0, 0.5), mult)
    }

    private func resolveAttack(_ w: Weapon, scoreBonus: Double, jamPenalty: Double) {
        guard var enemy = game.run.enemy else { return }
        guard game.player.currentAP >= w.ap else { return }
        let heroTraits = Game.shared.content.heroes[Game.shared.selectedHeroIndex].traits

        var (acc, crit, mult) = buildNumbers(for: w, score: scoreBonus)
        mult += overdrive ? 0.15 : comboValue * 0.1
        let finalAcc = max(0.05, acc - jamPenalty)
        game.player.currentAP -= w.ap
        apLabel.text = "AP \(game.player.currentAP)"

        let hit = Double.random(in: 0...1) < finalAcc
        if hit {
            let doCrit = Double.random(in: 0...1) < crit
            var dmg = w.rollDamage(crit: doCrit)
            dmg = Int(Double(dmg) * mult)

            if enemy.block > 0 {
                let absorbed = min(enemy.block, dmg)
                enemy.block -= absorbed
                dmg -= absorbed
            }
            if dmg < 0 { dmg = 0 }
            enemy.hp -= dmg

            pushNumber(dmg, crit: doCrit)
            shake(node: enemyNode, x: 12)
            if doCrit { hitFlash() }

            if let s = w.special {
                if s.hasPrefix("bleed:") { enemy.bleedTurns = max(enemy.bleedTurns, Int(s.split(separator: ":")[1]) ?? 0) }
                if s.hasPrefix("jam:") { enemy.jamNext = max(enemy.jamNext, Double(s.split(separator: ":")[1]) ?? 0) }
            }
            if let jam = heroTraits.first(where: { $0.hasPrefix("jamOnHit:") }) {
                enemy.jamNext = max(enemy.jamNext, Double(jam.split(separator: ":")[1]) ?? 0)
            }
            if let heal = heroTraits.first(where: { $0.hasPrefix("healOnHit:") }) {
                let v = Int(heal.split(separator: ":")[1]) ?? 0
                game.player.hp = min(game.player.maxHP, game.player.hp + v)
            }

            addHeat(0.2)
            game.run.enemy = enemy
            updateHPBars()

            if enemy.hp <= 0 {
                if let perk = heroTraits.first(where: { $0.hasPrefix("apPerKill:") }) {
                    game.player.currentAP += Int(perk.split(separator: ":")[1]) ?? 0
                    apLabel.text = "AP \(game.player.currentAP)"
                }
                if let perk = heroTraits.first(where: { $0.hasPrefix("healOnKill:") }) {
                    let v = Int(perk.split(separator: ":")[1]) ?? 0
                    game.player.hp = min(game.player.maxHP, game.player.hp + v)
                }
                enemyDiesCoinRain()
                game.run.state = .victory
                game.endCombat(victory: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
                    guard let self else { return }
                    let s = SlotScene(size: self.size)
                    s.scaleMode = .resizeFill
                    self.view?.presentScene(s, transition: .fade(withDuration: 0.25))
                }
                return
            }
        } else {
            addHeat(0.0)
        }

        if game.player.currentAP <= 0 {
            endPlayerTurn()
        }
    }

    private func endPlayerTurn() {
        game.run.state = .enemyTurn
        enemyActs()
    }

    private func enemyActs() {
        guard var enemy = game.run.enemy else { return }
        var log = ""
        if enemy.isCharging {
            let dmg = enemy.attack * 2
            playerTakes(dmg)
            enemy.isCharging = false
            log = "Charged \(dmg)"
        } else {
            let choice = Int.random(in: 0..<100)
            if choice < 50 {
                let dmg = enemy.attack + Int.random(in: -2...3)
                playerTakes(dmg); log = "Attacks \(dmg)"
            } else if choice < 70 {
                enemy.block += 10; log = "Raises plating"
            } else if choice < 85 {
                let heal = 8; enemy.hp = min(enemy.maxHP, enemy.hp + heal); log = "Welds \(heal)"
            } else {
                enemy.isCharging = true; log = "Begins charge"
            }
        }
        if enemy.bleedTurns > 0 { enemy.hp -= 2; enemy.bleedTurns -= 1; log += " Bleeds 2" }
        game.run.enemy = enemy
        updateHPBars()

        decayHeat(Game.shared.config.heatDecayOnEnemyTurn)

        if game.player.hp <= 0 {
            game.run.state = .defeat
            let s = GameOverScene(size: size)
            s.scaleMode = .resizeFill
            view?.presentScene(s, transition: .fade(withDuration: 0.25))
        } else {
            game.run.state = .playerTurn
            game.player.currentAP = game.player.baseAP
            apLabel.text = "AP \(game.player.currentAP)"
        }
        logLabel.text = log
    }

    private func playerTakes(_ raw: Int) {
        var dmg = raw
        if game.player.block > 0 {
            let absorb = min(game.player.block, dmg)
            game.player.block -= absorb; dmg -= absorb
        }
        game.player.hp -= max(0, dmg)
        if game.player.hp < 0 { game.player.hp = 0 }
        updateHPBars()
        shake(node: heroNode, x: 10)
        Game.shared.audio.hit()
    }

    private func pushNumber(_ n: Int, crit: Bool) {
        let l = makeLabel(crit ? "✦ \(n)" : "\(n)", size: crit ? 34 : 26, color: crit ? .orange : .yellow)
        l.position = CGPoint(x: enemyNode.position.x, y: enemyNode.position.y + 60)
        l.zPosition = 20
        damageLayer.addChild(l)
        let up = SKAction.moveBy(x: CGFloat.random(in: -18...18), y: 80, duration: 0.8)
        up.timingMode = .easeOut
        l.run(.group([up, .fadeOut(withDuration: 0.8)])) { l.removeFromParent() }
        if crit { Game.shared.audio.crit() } else { Game.shared.audio.hit() }
    }

    private func hitFlash() {
        if game.performance.lowEffects { return }
        flash.alpha = 0.35
        flash.run(.fadeOut(withDuration: 0.08))
        guard let r = enemyNode.copy() as? SKSpriteNode, let b = enemyNode.copy() as? SKSpriteNode else { return }
        r.color = .red; r.colorBlendFactor = 1
        b.color = .blue; b.colorBlendFactor = 1
        r.position.x += 1.2; b.position.x -= 1.2
        r.zPosition = enemyNode.zPosition + 0.5; b.zPosition = enemyNode.zPosition + 0.5
        addChild(r); addChild(b)
        r.run(.sequence([.wait(forDuration: 0.12), .removeFromParent()]))
        b.run(.sequence([.wait(forDuration: 0.12), .removeFromParent()]))
    }

    private func shake(node: SKNode, x: CGFloat) {
        let seq = SKAction.sequence([
            .moveBy(x:  x, y: 0, duration: 0.03),
            .moveBy(x: -x*2, y: 0, duration: 0.06),
            .moveBy(x:  x, y: 0, duration: 0.03)
        ])
        node.run(seq)
    }

    private func addHeat(_ v: Double) {
        comboValue = min(1.0, comboValue + v)
        overdrive = comboValue >= 1.0
        redrawHeatBar()
    }
    private func decayHeat(_ v: Double) {
        comboValue = max(0.0, comboValue - v)
        overdrive = comboValue >= 1.0
        redrawHeatBar()
    }
    private func redrawHeatBar() {
        let width = max(8, CGFloat(comboValue) * 220)
        heatBarFG.path = CGPath(rect: CGRect(x: -110, y: -5, width: width, height: 10), transform: nil)
        heatBarFG.fillColor = overdrive ? .orange : .systemGreen
    }

    private func updateHPBars() {
        let pRatio = CGFloat(Double(game.player.hp) / Double(max(1, game.player.maxHP)))
        playerHPFG.path = CGPath(roundedRect: CGRect(x: -100, y: -6, width: max(6, 200 * pRatio), height: 12), cornerWidth: 6, cornerHeight: 6, transform: nil)
        let e = game.run.enemy
        let eRatio = CGFloat(Double(e?.hp ?? 1) / Double(max(1, e?.maxHP ?? 1)))
        enemyHPFG.path = CGPath(roundedRect: CGRect(x: -110, y: -6, width: max(6, 220 * eRatio), height: 12), cornerWidth: 6, cornerHeight: 6, transform: nil)
    }

    private func enemyDiesCoinRain() {
        for _ in 0..<24 {
            let dot = SKShapeNode(circleOfRadius: 5)
            dot.fillColor = .yellow
            dot.strokeColor = .clear
            dot.position = enemyNode.position
            addChild(dot)
            let angle = CGFloat.random(in: 0...(.pi*2))
            let burst = CGVector(dx: cos(angle)*CGFloat.random(in: 80...160),
                                 dy: sin(angle)*CGFloat.random(in: 80...160))
            let travel = SKAction.move(by: burst, duration: 0.25)
            travel.timingMode = .easeOut
            dot.run(travel) { [weak self, weak dot] in
                guard let self, let dot else { return }
                let target = CGPoint(x: self.size.width - 40, y: self.size.height - 30)
                let suck = SKAction.move(to: target, duration: 0.6)
                suck.timingMode = .easeIn
                dot.run(suck) { dot.removeFromParent() }
            }
        }
    }

    private func showPauseOverlay() {
        if pauseOverlay != nil { return }
        isPausedGame = true

        let overlay = SKNode()
        overlay.zPosition = 999
        overlay.name = "pauseOverlay"
        addChild(overlay)
        pauseOverlay = overlay

        let dim = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        dim.fillColor = UIColor.black.withAlphaComponent(0.55)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.addChild(dim)

        let panel = SKShapeNode(rectOf: CGSize(width: size.width*0.8, height: 260), cornerRadius: 16)
        panel.fillColor = UIColor.white.withAlphaComponent(0.08)
        panel.strokeColor = UIColor.white.withAlphaComponent(0.12)
        panel.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.addChild(panel)

        let title = makeLabel("Paused", size: 22)
        title.position = CGPoint(x: panel.position.x, y: panel.position.y + 90)
        overlay.addChild(title)

        let resume = ButtonNode(text: "Resume", width: 200) { [weak self] in
            self?.isPausedGame = false
            self?.pauseOverlay?.removeFromParent()
            self?.pauseOverlay = nil
        }
        resume.position = CGPoint(x: panel.position.x, y: panel.position.y + 40)
        overlay.addChild(resume)

        let hand = ButtonNode(text: game.ux.handedness == .right ? "Right hand" : "Left hand", width: 200) { [weak self] in
            guard let self else { return }
            self.game.ux.handedness = self.game.ux.handedness == .right ? .left : .right
            self.game.save.saveUX(self.game.ux)
            (hand.children.compactMap{$0 as? SKLabelNode}.first)?.text = self.game.ux.handedness == .right ? "Right hand" : "Left hand"
            self.layoutForHand()
        }
        hand.position = CGPoint(x: panel.position.x, y: panel.position.y - 10)
        overlay.addChild(hand)

        let motion = ButtonNode(text: game.ux.reduceMotion ? "Motion off" : "Motion on", width: 200) { [weak self] in
            guard let self else { return }
            self.game.ux.reduceMotion.toggle()
            self.game.save.saveUX(self.game.ux)
            (motion.children.compactMap{$0 as? SKLabelNode}.first)?.text = self.game.ux.reduceMotion ? "Motion off" : "Motion on"
            if self.game.ux.reduceMotion { self.game.motion.stop() } else { self.game.motion.start() }
        }
        motion.position = CGPoint(x: panel.position.x, y: panel.position.y - 60)
        overlay.addChild(motion)

        let quit = ButtonNode(text: "Quit to Menu", width: 200) { [weak self] in
            guard let self else { return }
            self.isPausedGame = false
            let menu = MainMenuScene(size: self.size)
            menu.scaleMode = .resizeFill
            self.view?.presentScene(menu, transition: .fade(withDuration: 0.25))
        }
        quit.position = CGPoint(x: panel.position.x, y: panel.position.y - 110)
        overlay.addChild(quit)
    }

    override func update(_ currentTime: TimeInterval) {
        guard !(game.ux.reduceMotion || game.performance.lowEffects) else { return }
        camera?.position.x = CGFloat(game.motion.roll) * 16
        camera?.position.y = CGFloat(-game.motion.pitch) * 16
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { touchStart = touches.first?.location(in: self) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = touchStart, let e = touches.first?.location(in: self), pauseOverlay == nil else { return }
        let dy = e.y - s.y
        if dy > 60 { endPlayerTurn() }
        touchStart = nil
    }

    deinit { game.motion.stop() }
}

extension Array { subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil } }
