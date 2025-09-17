import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Регистрация AnantaSound плагина
    if let controller = window?.rootViewController as? FlutterViewController {
      AnantaSoundPlugin.register(with: registrar(forPlugin: "AnantaSoundPlugin")!)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

