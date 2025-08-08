import SpriteKit

final class OnboardingScene: SKScene {
    private var page = 0
    private let lines = [
        "Tap a weapon, stop the ring near the sweet spot, deal damage.",
        "Spend AP. Swipe up anywhere to end turn.",
        "Win fights, spin the slot, slot items, pick your path. Go for the boss."
    ]

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = .black
        ensureCamera()
        addChild(parallaxBackground())

        showPage()
    }

    private func showPage() {
        removeAllChildren()
        addChild(parallaxBackground())

        let t = makeLabel("How to play", size: 28)
        t.position = CGPoint(x: size.width/2, y: size.height*0.72)
        addChild(t)

        let body = makeLabel(lines[page], size: 18, color: .lightGray)
        body.position = CGPoint(x: size.width/2, y: size.height*0.58)
        addChild(body)

        let next = ButtonNode(text: page == lines.count-1 ? "Got it" : "Next", width: 220) { [weak self] in
            guard let self else { return }
            if self.page < self.lines.count-1 { self.page += 1; self.showPage() }
            else {
                let menu = MainMenuScene(size: self.size)
                menu.scaleMode = .resizeFill
                self.view?.presentScene(menu, transition: .fade(withDuration: 0.2))
            }
        }
        next.position = CGPoint(x: size.width/2, y: size.height*0.26)
        addChild(next)
    }
}
