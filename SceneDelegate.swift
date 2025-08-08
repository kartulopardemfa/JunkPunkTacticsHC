import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let winScene = scene as? UIWindowScene else { return }
        let win = UIWindow(windowScene: winScene)
        win.rootViewController = GameViewController()
        win.makeKeyAndVisible()
        window = win
    }
}
