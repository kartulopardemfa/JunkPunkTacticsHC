import UIKit // Import UIKit to manage UI elements

class SceneDelegate: UIResponder, UIWindowSceneDelegate { // Manages window-level events
    var window: UIWindow? // Reference to the main app window

    func scene(_ scene: UIScene, // Called when connecting a new scene
               willConnectTo session: UISceneSession, // The session being connected
               options connectionOptions: UIScene.ConnectionOptions) { // Additional options
        guard let winScene = scene as? UIWindowScene else { return } // Ensure the scene can host a window
        let win = UIWindow(windowScene: winScene) // Create a window for this scene
        win.rootViewController = GameViewController() // Set game view controller as root
        win.makeKeyAndVisible() // Display the window
        window = win // Keep a reference to the window
    }
} // End of SceneDelegate
