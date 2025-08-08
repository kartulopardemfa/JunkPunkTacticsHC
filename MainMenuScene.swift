import SpriteKit

final class MainMenuScene: SKScene {
    private let services = Game.shared
    private let title = SKLabelNode(fontNamed: "Avenir-Black")
    private var heroButtons: [ButtonNode] = []

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        title.text = "JUNK PUNK"
        title.fontSize = 42
        title.position = CGPoint(x: size.width/2, y: size.height*0.72)
        addChild(title)

        buildHeroCarousel()
        buildSettingsRow()
        buildInfoRow()

        let start = ButtonNode(text: "Start Run", width: 220) { [weak self] in
            guard let self else { return }
            self.services.startNewRun()
            let map = MapScene(size: self.size)
            map.scaleMode = .resizeFill
            self.view?.presentScene(map, transition: .fade(withDuration: 0.25))
        }
        start.position = CGPoint(x: size.width/2, y: size.height*0.28)
        addChild(start)

        let meta = ButtonNode(text: "Workshop", width: 220) { [weak self] in
            guard let self else { return }
            let s = MetaScene(size: self.size)
            s.scaleMode = .resizeFill
            self.view?.presentScene(s, transition: .fade(withDuration: 0.25))
        }
        meta.position = CGPoint(x: size.width/2, y: size.height*0.18)
        addChild(meta)

        if services.ux.reduceMotion { services.motion.stop() } else { services.motion.start() }

        if !services.save.firstRunShown() {
            services.save.setFirstRunShown()
            let t = OnboardingScene(size: size)
            t.scaleMode = .resizeFill
            view?.presentScene(t, transition: .fade(withDuration: 0.2))
        }
    }

    private func buildHeroCarousel() {
        let heroes = services.content.heroes
        heroButtons.forEach { $0.removeFromParent() }
        heroButtons.removeAll()

        let startX = size.width*0.5 - CGFloat(heroes.count-1) * 100 * 0.5
        for (i,h) in heroes.enumerated() {
            let b = ButtonNode(text: h.name, width: 180, height: 64) { [weak self] in
                self?.services.selectedHeroIndex = i
                self?.highlightHero(i)
            }
            b.position = CGPoint(x: startX + CGFloat(i)*100, y: size.height*0.5)
            addChild(b)
            heroButtons.append(b)
        }
        highlightHero(services.selectedHeroIndex)
    }

    private func buildSettingsRow() {
        let hand = ButtonNode(text: services.ux.handedness == .right ? "Right hand" : "Left hand", width: 160, height: 44) { [weak self] in
            guard let self else { return }
            self.services.ux.handedness = self.services.ux.handedness == .right ? .left : .right
            (hand.children.compactMap{$0 as? SKLabelNode}.first)?.text = self.services.ux.handedness == .right ? "Right hand" : "Left hand"
            self.services.save.saveUX(self.services.ux)
        }
        hand.position = CGPoint(x: size.width*0.35, y: size.height*0.36)
        addChild(hand)

        let motion = ButtonNode(text: services.ux.reduceMotion ? "Motion off" : "Motion on", width: 160, height: 44) { [weak self] in
            guard let self else { return }
            self.services.ux.reduceMotion.toggle()
            (motion.children.compactMap{$0 as? SKLabelNode}.first)?.text = self.services.ux.reduceMotion ? "Motion off" : "Motion on"
            self.services.save.saveUX(self.services.ux)
            if self.services.ux.reduceMotion { self.services.motion.stop() } else { self.services.motion.start() }
        }
        motion.position = CGPoint(x: size.width*0.65, y: size.height*0.36)
        addChild(motion)
    }

    private func buildInfoRow() {
        let how = ButtonNode(text: "How to play", width: 160, height: 44) { [weak self] in
            guard let self else { return }
            let t = OnboardingScene(size: self.size)
            t.scaleMode = .resizeFill
            self.view?.presentScene(t, transition: .fade(withDuration: 0.2))
        }
        how.position = CGPoint(x: size.width*0.5, y: size.height*0.08)
        addChild(how)
    }

    private func highlightHero(_ index: Int) {
        for (i,b) in heroButtons.enumerated() {
            let on = (i == index)
            (b.children.first as? SKShapeNode)?.fillColor = on ? UIColor.systemGreen.withAlphaComponent(0.25) : UIColor.white.withAlphaComponent(0.08)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !services.ux.reduceMotion else { return }
        camera?.position.x = CGFloat(services.motion.roll) * 16
        camera?.position.y = CGFloat(-services.motion.pitch) * 16
    }

    deinit { services.motion.stop() }
}
