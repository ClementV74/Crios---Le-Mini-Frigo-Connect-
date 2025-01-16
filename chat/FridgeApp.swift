import SwiftUI

@main
struct FridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // Utilisation d'AppDelegate pour gérer les orientations
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.light) // Peut être modifié selon les préférences de l'utilisateur
        }
    }
}

// MARK: - AppDelegate to lock orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait // Forcer l'application en mode portrait
    }
}

// MARK: - MainView with TabView
struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Analyse", systemImage: "thermometer")
                }
            
            ContentView()
                .tabItem {
                    Label("AI", systemImage: "brain.head.profile")
                }
        }
    }
}
