import UIKit // Import the UIKit framework for app-level functionality

@main // Indicates this is the program entry point
class AppDelegate: UIResponder, UIApplicationDelegate { // Handles high-level app events
    func application(_ application: UIApplication, // Called when the app has finished launching
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool { // Launch parameters
        Game.shared.boot() // Initialize core game services
        return true // Signal successful launch
    }

    func application(_ application: UIApplication, // Called when creating a new scene session
                     configurationForConnecting connectingSceneSession: UISceneSession, // The session to configure
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration { // Additional creation options
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role) // Return default scene setup
    }
} // End of AppDelegate
