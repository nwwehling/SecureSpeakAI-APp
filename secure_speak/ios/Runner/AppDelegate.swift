import UIKit
import Flutter
import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    lazy var headlessRunner = FlutterEngine(name: "io.flutter")

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Flutter engine
        headlessRunner.run()
        
        // Register the Flutter downloader plugin
        FlutterDownloaderPlugin.setPluginRegistrantCallback { registry in
            if !registry.hasPlugin("io.flutter.plugins.flutter_downloader") {
                FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "io.flutter.plugins.flutter_downloader")!)
            }
        }

        // Ensure plugins are registered
        GeneratedPluginRegistrant.register(with: self)

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

// Top-level function for plugin registration callback
private func registerPluginsCallback(registry: FlutterPluginRegistry) {
    if !registry.hasPlugin("GeneratedPluginRegistrant") {
        GeneratedPluginRegistrant.register(with: registry)
    }
}
