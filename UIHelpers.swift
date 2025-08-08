import SpriteKit

extension SKScene {
    func ensureCamera() {
        if camera == nil {
            let c = SKCameraNode()
            camera = c
            addChild(c)
        }
    }

    func makeLabel(_ text: String, size: CGFloat = 16, color: UIColor = .white) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "Avenir-Heavy")
        l.text = text
        l.fontSize = size
        l.fontColor = color
        l.verticalAlignmentMode = .center
        return l
    }

    func parallaxBackground() -> SKNode {
        let bg = SKNode()
        let grad = SKShapeNode(rectOf: CGSize(width: size.width * 1.2, height: size.height * 1.2))
        grad.fillColor = UIColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1.0)
        grad.strokeColor = .clear
        grad.zPosition = -20
        bg.addChild(grad)
        for i in stride(from: -Int(size.width), through: Int(size.width), by: 80) {
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: size.height*1.4))
            line.fillColor = .systemMint.withAlphaComponent(0.08)
            line.strokeColor = .clear
            line.position = CGPoint(x: CGFloat(i), y: 0)
            line.zPosition = -5
            bg.addChild(line)
        }
        return bg
    }
}

final class ButtonNode: SKNode {
    private let bg: SKShapeNode
    private let label: SKLabelNode
    private var action: (() -> Void)?

    init(text: String, width: CGFloat = 200, height: CGFloat = 56, action: (() -> Void)? = nil) {
        bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = .white.withAlphaComponent(0.08)
        bg.strokeColor = .white.withAlphaComponent(0.15)
        label = SKLabelNode(fontNamed: "Avenir-Heavy")
        label.text = text
        label.fontSize = 18
        label.verticalAlignmentMode = .center
        label.fontColor = .white
        self.action = action
        super.init()
        isUserInteractionEnabled = true
        addChild(bg)
        addChild(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { bg.run(.scale(to: 0.98, duration: 0.05)) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { bg.run(.scale(to: 1.0, duration: 0.05)) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { bg.run(.scale(to: 1.0, duration: 0.05)); action?() }

    func setText(_ t: String) { label.text = t }
}
