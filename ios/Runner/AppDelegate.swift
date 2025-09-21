import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Регистрация нативных плагинов
    if let controller = window?.rootViewController as? FlutterViewController {
      AnantaSoundPlugin.register(with: registrar(forPlugin: "AnantaSoundPlugin")!)
      MagentoNativePlugin.register(with: registrar(forPlugin: "MagentoNativePlugin")!)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

