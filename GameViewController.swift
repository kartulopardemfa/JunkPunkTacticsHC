import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    private let skView = SKView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        view = skView
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 120
        presentInitialScene()

        NotificationCenter.default.addObserver(self, selector: #selector(appWillResign), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(thermalChanged), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        Game.shared.safeInsets = view.safeAreaInsets
    }

    private func presentInitialScene() {
        let scene = MainMenuScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene, transition: .fade(withDuration: 0.25))
    }

    @objc private func appWillResign() { skView.isPaused = true }
    @objc private func appDidBecomeActive() { skView.isPaused = false }
    @objc private func thermalChanged() { Game.shared.performance.updateThermalState() }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
