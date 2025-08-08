import SpriteKit

final class GameOverScene: SKScene {
    private let game = Game.shared
    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        let t = makeLabel("You are scrap", size: 30)
        t.position = CGPoint(x: size.width*0.5, y: size.height*0.7)
        addChild(t)

        let s = makeLabel("Gears \(game.meta.gears)  Scrap \(game.scrap)", size: 16, color: .lightGray)
        s.position = CGPoint(x: size.width*0.5, y: size.height*0.64)
        addChild(s)

        let workshop = ButtonNode(text: "Workshop", width: 220) { [weak self] in
            guard let self else { return }
            let m = MetaScene(size: self.size)
            m.scaleMode = .resizeFill
            self.view?.presentScene(m, transition: .fade(withDuration: 0.25))
        }
        workshop.position = CGPoint(x: size.width*0.5, y: size.height*0.48)
        addChild(workshop)

        let retry = ButtonNode(text: "Run it back", width: 220) { [weak self] in
            guard let self else { return }
            self.game.startNewRun()
            let map = MapScene(size: self.size)
            map.scaleMode = .resizeFill
            self.view?.presentScene(map, transition: .fade(withDuration: 0.25))
        }
        retry.position = CGPoint(x: size.width*0.5, y: size.height*0.38)
        addChild(retry)

        let menu = ButtonNode(text: "Menu", width: 220) { [weak self] in
            guard let self else { return }
            let m = MainMenuScene(size: self.size)
            m.scaleMode = .resizeFill
            self.view?.presentScene(m, transition: .fade(withDuration: 0.25))
        }
        menu.position = CGPoint(x: size.width*0.5, y: size.height*0.28)
        addChild(menu)
    }
}
