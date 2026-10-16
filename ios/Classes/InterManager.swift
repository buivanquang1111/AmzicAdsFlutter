import Foundation
import UIKit
import GoogleMobileAds

class InterManager: NSObject, FullScreenContentDelegate {
    static let shared = InterManager()

    private var preloadedAds: [String: [InterstitialAd]] = [:]
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

    func loadInterAdPreload(idAds: String, numberPreload: Int) {
        let currentCount = preloadedAds[idAds]?.count ?? 0
        if currentCount >= numberPreload {
            self.pluginChannelSender?("inter", "onAdLoaded", idAds, nil)
            return
        }

        let needed = numberPreload - currentCount
        for _ in 0..<needed {
            let request = Request()
            InterstitialAd.load(with: idAds, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    print("[InterManager] Failed to load inter ad \(idAds): \(error.localizedDescription)")
                    self.pluginChannelSender?("inter", "onAdFailedToLoad", idAds, ["error": error.localizedDescription])
                    return
                }

                if let ad = ad {
                    print("[InterManager] Preloaded inter ad for \(idAds)")
                    if self.preloadedAds[idAds] == nil {
                        self.preloadedAds[idAds] = []
                    }
                    self.preloadedAds[idAds]?.append(ad)
                    self.pluginChannelSender?("inter", "onAdLoaded", idAds, nil)
                }
            }
        }
    }

    func showInterAdPreload(idAds: String, rootVC: UIViewController?) {
        guard let rootVC = rootVC else {
            print("[InterManager] Root ViewController is nil")
            self.pluginChannelSender?("inter", "onAdDismissed", idAds, nil)
            return
        }

        guard var list = preloadedAds[idAds], !list.isEmpty else {
            print("[InterManager] No ad available to show for \(idAds)")
            self.pluginChannelSender?("inter", "onAdDismissed", idAds, nil)
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

            self.pluginChannelSender?("inter", "onPaidEvent", idAds, [
                "network": network,
                "valueMicros": valueMicros,
                "currencyCode": currencyCode
            ])
        }

        ad.present(from: rootVC)
    }

    func destroy(idAds: String) {
        preloadedAds[idAds] = []
    }

    // MARK: - FullScreenContentDelegate
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("inter", "onAdImpression", idAds, nil)
        }
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("inter", "onAdClicked", idAds, nil)
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("inter", "onAdShowed", idAds, nil)
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("inter", "onAdFailedToShow", idAds, ["error": error.localizedDescription])
            pluginChannelSender?("inter", "onFailedToShow", idAds, ["error": error.localizedDescription])
            activeAds.removeValue(forKey: key)
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("inter", "onAdDismissed", idAds, nil)
            activeAds.removeValue(forKey: key)
        }
    }
}
