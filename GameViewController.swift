import UIKit // UI framework for iOS apps
import SpriteKit // 2D game framework used for rendering

final class GameViewController: UIViewController { // Hosts the SpriteKit view
    private let skView = SKView(frame: .zero) // Main view for rendering scenes

    override func viewDidLoad() { // Called after the view loads
        super.viewDidLoad() // Call parent implementation
        view = skView // Replace root view with SpriteKit view
        skView.ignoresSiblingOrder = true // Optimization for rendering nodes
        skView.preferredFramesPerSecond = 120 // Target high frame rate
        presentInitialScene() // Show the first scene

        NotificationCenter.default.addObserver(self, selector: #selector(appWillResign), name: UIApplication.willResignActiveNotification, object: nil) // Pause when app resigns
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil) // Resume when active
        NotificationCenter.default.addObserver(self, selector: #selector(thermalChanged), name: ProcessInfo.thermalStateDidChangeNotification, object: nil) // React to thermal changes
    }

    override func viewSafeAreaInsetsDidChange() { // Respond to safe area changes
        super.viewSafeAreaInsetsDidChange() // Call parent implementation
        Game.shared.safeInsets = view.safeAreaInsets // Store current safe area
    }

    private func presentInitialScene() { // Present the main menu at start
        let scene = MainMenuScene(size: view.bounds.size) // Create menu with current size
        scene.scaleMode = .resizeFill // Adjust to fill view
        skView.presentScene(scene, transition: .fade(withDuration: 0.25)) // Show with fade transition
    }

    @objc private func appWillResign() { skView.isPaused = true } // Pause when backgrounded
    @objc private func appDidBecomeActive() { skView.isPaused = false } // Resume when foregrounded
    @objc private func thermalChanged() { Game.shared.performance.updateThermalState() } // Update performance settings

    override var prefersStatusBarHidden: Bool { true } // Hide status bar
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait } // Only portrait mode
} // End of GameViewController
