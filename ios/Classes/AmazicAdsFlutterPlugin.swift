import Flutter
import UIKit
import Network
import SystemConfiguration
import GoogleMobileAds

public class AmazicAdsFlutterPlugin: NSObject, FlutterPlugin {
  private static var monitor: NWPathMonitor?
  private static var isNetworkConnected: Bool = false
  private static let queue = DispatchQueue(label: "AmazicNetworkMonitor")

  private var channel: FlutterMethodChannel?
  private var interChannel: FlutterMethodChannel?
  private var appOpenChannel: FlutterMethodChannel?
  private var rewardChannel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AmazicAdsFlutterPlugin()

    let channel = FlutterMethodChannel(name: "amazic_ads_flutter", binaryMessenger: registrar.messenger())
    let interChannel = FlutterMethodChannel(name: "amazic_ads_inter", binaryMessenger: registrar.messenger())
    let appOpenChannel = FlutterMethodChannel(name: "amazic_ads_app_open", binaryMessenger: registrar.messenger())
    let rewardChannel = FlutterMethodChannel(name: "amazic_ads_reward", binaryMessenger: registrar.messenger())

    instance.channel = channel
    instance.interChannel = interChannel
    instance.appOpenChannel = appOpenChannel
    instance.rewardChannel = rewardChannel

    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: interChannel)
    registrar.addMethodCallDelegate(instance, channel: appOpenChannel)
    registrar.addMethodCallDelegate(instance, channel: rewardChannel)

    instance.setupChannelSenders()
    startMonitoring()
  }

  private func setupChannelSenders() {
    let sender: (String, String, String, [String: Any]?) -> Void = { [weak self] type, method, idAds, extras in
      guard let self = self else { return }
      var data: [String: Any] = ["id": idAds]
      if let extras = extras {
        for (key, value) in extras {
          data[key] = value
        }
      }

      DispatchQueue.main.async {
        switch type {
        case "inter":
          self.interChannel?.invokeMethod(method, arguments: data)
        case "app_open":
          self.appOpenChannel?.invokeMethod(method, arguments: data)
        case "reward":
          self.rewardChannel?.invokeMethod(method, arguments: data)
        default:
          break
        }
      }
    }

    InterManager.shared.setChannelSender(sender)
    AppOpenManager.shared.setChannelSender(sender)
    RewardManager.shared.setChannelSender(sender)
  }

  private static func startMonitoring() {
    let pathMonitor = NWPathMonitor()
    pathMonitor.pathUpdateHandler = { path in
      isNetworkConnected = (path.status == .satisfied)
    }
    pathMonitor.start(queue: queue)
    monitor = pathMonitor
  }

  public static var topViewController: UIViewController? {
    var keyWindow: UIWindow?
    if #available(iOS 13.0, *) {
      keyWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    } else {
      keyWindow = UIApplication.shared.keyWindow
    }

    var topController = keyWindow?.rootViewController
    while let presentedViewController = topController?.presentedViewController {
      topController = presentedViewController
    }
    return topController
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let idAds = args?["idAds"] as? String ?? ""
    let numberPreload = args?["numberPreload"] as? Int ?? 1

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

    // Interstitial Ads
    case "isAdAvailableInter":
      result(InterManager.shared.isAdAvailable(idAds: idAds))

    case "loadInterAdPreload":
      InterManager.shared.loadInterAdPreload(idAds: idAds, numberPreload: numberPreload)
      result(nil)

    case "showInterAdPreload":
      InterManager.shared.showInterAdPreload(idAds: idAds, rootVC: AmazicAdsFlutterPlugin.topViewController)
      result(nil)

    case "destroyInterAdPreload":
      InterManager.shared.destroy(idAds: idAds)
      result(nil)

    // App Open Ads
    case "isAdAvailableAppOpen":
      result(AppOpenManager.shared.isAdAvailable(idAds: idAds))

    case "loadAppOpenAdPreload":
      AppOpenManager.shared.loadAppOpenAdPreload(idAds: idAds, numberPreload: numberPreload)
      result(nil)

    case "showAppOpenAdPreload":
      AppOpenManager.shared.showAppOpenAdPreload(idAds: idAds, rootVC: AmazicAdsFlutterPlugin.topViewController)
      result(nil)

    case "destroyAppOpenAdPreload":
      AppOpenManager.shared.destroy(idAds: idAds)
      result(nil)

    // Rewarded Ads
    case "isAdAvailableReward":
      result(RewardManager.shared.isAdAvailable(idAds: idAds))

    case "loadRewardAdPreload":
      RewardManager.shared.loadRewardAdPreload(idAds: idAds, numberPreload: numberPreload)
      result(nil)

    case "showRewardAdPreload":
      RewardManager.shared.showRewardAdPreload(idAds: idAds, rootVC: AmazicAdsFlutterPlugin.topViewController)
      result(nil)

    case "destroyRewardAdPreload":
      RewardManager.shared.destroy(idAds: idAds)
      result(nil)

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
