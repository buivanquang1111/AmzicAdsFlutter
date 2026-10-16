import Foundation
import UIKit
import GoogleMobileAds

class AppOpenManager: NSObject, GADFullScreenContentDelegate {
    static let shared = AppOpenManager()

    private var preloadedAds: [String: [GADAppOpenAd]] = [:]
    private var activeAds: [ObjectIdentifier: String] = [:]
    private var pluginChannelSender: ((String, String, String, [String: Any]?) -> Void)?

    func setChannelSender(_ sender: @escaping (String, String, String, [String: Any]?) -> Void) {
        self.pluginChannelSender = sender
    }

    func isAdAvailable(idAds: String) -> Bool {
        if let list = preloadedAds[idAds], !list.isEmpty {
            return true
        }
        return false
    }

    func loadAppOpenAdPreload(idAds: String, numberPreload: Int) {
        let currentCount = preloadedAds[idAds]?.count ?? 0
        if currentCount >= numberPreload {
            self.pluginChannelSender?("app_open", "onAdLoaded", idAds, nil)
            return
        }

        let needed = numberPreload - currentCount
        for _ in 0..<needed {
            let request = GADRequest()
            GADAppOpenAd.load(withAdUnitID: idAds, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    print("[AppOpenManager] Failed to load app open ad \(idAds): \(error.localizedDescription)")
                    self.pluginChannelSender?("app_open", "onAdFailedToLoad", idAds, ["error": error.localizedDescription])
                    return
                }

                if let ad = ad {
                    print("[AppOpenManager] Preloaded app open ad for \(idAds)")
                    if self.preloadedAds[idAds] == nil {
                        self.preloadedAds[idAds] = []
                    }
                    self.preloadedAds[idAds]?.append(ad)
                    self.pluginChannelSender?("app_open", "onAdLoaded", idAds, nil)
                }
            }
        }
    }

    func showAppOpenAdPreload(idAds: String, rootVC: UIViewController?) {
        guard let rootVC = rootVC else {
            print("[AppOpenManager] Root ViewController is nil")
            self.pluginChannelSender?("app_open", "onAdDismissed", idAds, nil)
            return
        }

        guard var list = preloadedAds[idAds], !list.isEmpty else {
            print("[AppOpenManager] No ad available to show for \(idAds)")
            self.pluginChannelSender?("app_open", "onAdDismissed", idAds, nil)
            return
        }

        let ad = list.removeFirst()
        preloadedAds[idAds] = list

        let adKey = ObjectIdentifier(ad)
        activeAds[adKey] = idAds

        ad.fullScreenContentDelegate = self

        ad.paidEventHandler = { [weak self] adValue in
            guard let self = self else { return }
            let network = ad.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName ?? ""
            let valueMicros = Double(truncating: adValue.value) * 1_000_000.0
            let currencyCode = adValue.currencyCode

            self.pluginChannelSender?("app_open", "onPaidEvent", idAds, [
                "network": network,
                "valueMicros": valueMicros,
                "currencyCode": currencyCode
            ])
        }

        ad.present(fromRootViewController: rootVC)
    }

    func destroy(idAds: String) {
        preloadedAds[idAds] = []
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("app_open", "onAdImpression", idAds, nil)
        }
    }

    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("app_open", "onAdClicked", idAds, nil)
        }
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("app_open", "onAdShowed", idAds, nil)
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("app_open", "onAdFailedToShow", idAds, ["error": error.localizedDescription])
            pluginChannelSender?("app_open", "onFailedToShow", idAds, ["error": error.localizedDescription])
            activeAds.removeValue(forKey: key)
        }
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("app_open", "onAdDismissed", idAds, nil)
            activeAds.removeValue(forKey: key)
        }
    }
}
