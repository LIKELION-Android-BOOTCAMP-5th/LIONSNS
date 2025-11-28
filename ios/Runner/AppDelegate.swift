import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Method Channel 설정
    let controller = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(
      name: "com.lionsns/widget",
      binaryMessenger: controller.binaryMessenger
    )
    
    widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "updateWidget":
        // 위젯 업데이트 요청
        WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        result(true)
      case "clearWidget":
        // 위젯 데이터 삭제
        WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
