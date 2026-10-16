import Foundation
import UIKit
import GoogleMobileAds

class RewardManager: NSObject, FullScreenContentDelegate {
    static let shared = RewardManager()

    private var preloadedAds: [String: [RewardedAd]] = [:]
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

    func loadRewardAdPreload(idAds: String, numberPreload: Int) {
        let currentCount = preloadedAds[idAds]?.count ?? 0
        if currentCount >= numberPreload {
            self.pluginChannelSender?("reward", "onAdLoaded", idAds, nil)
            return
        }

        let needed = numberPreload - currentCount
        for _ in 0..<needed {
            let request = Request()
            RewardedAd.load(withAdUnitID: idAds, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    print("[RewardManager] Failed to load reward ad \(idAds): \(error.localizedDescription)")
                    self.pluginChannelSender?("reward", "onAdFailedToLoad", idAds, ["error": error.localizedDescription])
                    return
                }

                if let ad = ad {
                    print("[RewardManager] Preloaded reward ad for \(idAds)")
                    if self.preloadedAds[idAds] == nil {
                        self.preloadedAds[idAds] = []
                    }
                    self.preloadedAds[idAds]?.append(ad)
                    self.pluginChannelSender?("reward", "onAdLoaded", idAds, nil)
                }
            }
        }
    }

    func showRewardAdPreload(idAds: String, rootVC: UIViewController?) {
        guard let rootVC = rootVC else {
            print("[RewardManager] Root ViewController is nil")
            self.pluginChannelSender?("reward", "onAdDismissed", idAds, nil)
            return
        }

        guard var list = preloadedAds[idAds], !list.isEmpty else {
            print("[RewardManager] No ad available to show for \(idAds)")
            self.pluginChannelSender?("reward", "onAdDismissed", idAds, nil)
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

            self.pluginChannelSender?("reward", "onPaidEvent", idAds, [
                "network": network,
                "valueMicros": valueMicros,
                "currencyCode": currencyCode
            ])
        }

        ad.present(fromRootViewController: rootVC) { [weak self] in
            guard let self = self else { return }
            self.pluginChannelSender?("reward", "onUserEarned", idAds, nil)
        }
    }

    func destroy(idAds: String) {
        preloadedAds[idAds] = []
    }

    // MARK: - FullScreenContentDelegate
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("reward", "onAdImpression", idAds, nil)
        }
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("reward", "onAdClicked", idAds, nil)
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("reward", "onAdShowed", idAds, nil)
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("reward", "onAdFailedToShow", idAds, ["error": error.localizedDescription])
            pluginChannelSender?("reward", "onFailedToShow", idAds, ["error": error.localizedDescription])
            activeAds.removeValue(forKey: key)
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad)
        if let idAds = activeAds[key] {
            pluginChannelSender?("reward", "onAdDismissed", idAds, nil)
            activeAds.removeValue(forKey: key)
        }
    }
}
