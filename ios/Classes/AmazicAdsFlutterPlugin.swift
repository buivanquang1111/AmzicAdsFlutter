import Flutter
import UIKit
import Network
import SystemConfiguration

public class AmazicAdsFlutterPlugin: NSObject, FlutterPlugin {
  private static var monitor: NWPathMonitor?
  private static var isNetworkConnected: Bool = false
  private static let queue = DispatchQueue(label: "AmazicNetworkMonitor")

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "amazic_ads_flutter", binaryMessenger: registrar.messenger())
    let instance = AmazicAdsFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    startMonitoring()
  }

  private static func startMonitoring() {
    let pathMonitor = NWPathMonitor()
    pathMonitor.pathUpdateHandler = { path in
      isNetworkConnected = (path.status == .satisfied)
    }
    pathMonitor.start(queue: queue)
    monitor = pathMonitor
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "hasConsentPurposeOne":
      let purposeConsents = UserDefaults.standard.string(forKey: "IABTCF_PurposeConsents") ?? ""
      if !purposeConsents.isEmpty {
        let hasConsent = purposeConsents.first == "1"
        result(hasConsent)
      } else {
        result(nil)
      }

    case "isNetworkActive":
      result(AmazicAdsFlutterPlugin.isNetworkActive())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func isNetworkActive() -> Bool {
    if let monitor = monitor {
      if monitor.currentPath.status == .satisfied {
        return true
      }
    }
    if isNetworkConnected {
      return true
    }
    return checkNetworkViaReachability()
  }

  private static func checkNetworkViaReachability() -> Bool {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)

    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }) else {
      return false
    }

    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
      return false
    }

    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)

    return isReachable && !needsConnection
  }
}
