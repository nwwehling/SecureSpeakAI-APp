import UIKit
import Flutter
import receive_sharing_intent

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Initialize the Receive Sharing Intent
        ReceiveSharingIntentPlugin.register(with: self.registrar(forPlugin: "receive_sharing_intent")!)
        
        // Set up App Groups for shared data
        UserDefaults(suiteName: "group.com.example.securespeak")?.synchronize()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle URL schemes if necessary
        return super.application(app, open: url, options: options)
    }
    
    override func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        // Handle URL schemes if necessary
        return super.application(application, handleOpen: url)
    }
}
