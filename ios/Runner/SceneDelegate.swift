import Flutter
import UIKit
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  private var widgetChannel: FlutterMethodChannel?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return
    }
    let messenger = flutterViewController.binaryMessenger

    let timezoneChannel = FlutterMethodChannel(
      name: "com.texapp.atensia/timezone",
      binaryMessenger: messenger
    )
    timezoneChannel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result(TimeZone.current.identifier)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    widgetChannel = FlutterMethodChannel(
      name: "com.texapp.atensia/widget",
      binaryMessenger: messenger
    )
    widgetChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "updateMood": SceneDelegate.handleUpdateMood(call.arguments, result: result)
      case "readMood":   SceneDelegate.handleReadMood(result: result)
      default:           result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Widget channel handlers

  private static let kAppGroup   = "group.com.texapp.atensia"
  private static let kValenceKey = "widget_valence"
  private static let kArousalKey = "widget_arousal"
  private static let kDateKey    = "widget_date"

  private static func handleUpdateMood(_ arguments: Any?, result: FlutterResult) {
    let args     = arguments as? [String: Any]
    let defaults = UserDefaults(suiteName: kAppGroup)
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
    defaults?.set(f.string(from: Date()), forKey: kDateKey)
    if let v = args?["valence"] as? Double {
      defaults?.set(v, forKey: kValenceKey)
    } else {
      defaults?.removeObject(forKey: kValenceKey)
    }
    if let a = args?["arousal"] as? Double {
      defaults?.set(a, forKey: kArousalKey)
    } else {
      defaults?.removeObject(forKey: kArousalKey)
    }
    if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
    result(nil)
  }

  private static func handleReadMood(result: FlutterResult) {
    let defaults = UserDefaults(suiteName: kAppGroup)
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
    let today = f.string(from: Date())
    guard defaults?.string(forKey: kDateKey) == today else { result(nil); return }
    var map: [String: Any] = [:]
    if let v = defaults?.object(forKey: kValenceKey) as? Double { map["valence"] = v }
    if let a = defaults?.object(forKey: kArousalKey) as? Double { map["arousal"] = a }
    result(map.isEmpty ? nil : map)
  }
}
