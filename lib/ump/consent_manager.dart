import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../admob.dart';

class ConsentManager {
  static ConsentManager instance = ConsentManager._();

  ConsentManager._();

  static bool _canRequestAds = false;

  bool get canRequestAds => _canRequestAds;

  bool debugUmp = false;
  List<String>? testIdentifiers;

  ConsentDebugSettings get _debugSettings => ConsentDebugSettings(
    debugGeography: DebugGeography.debugGeographyEea,
    testIdentifiers: testIdentifiers,
  );

  static void setCanRequestAds(bool value) {
    _canRequestAds = value;
  }

  Future<void> handleRequestUmp({VoidCallback? onPostExecute}) async {
    print('ump: start request');
    if (_canRequestAds) {
      onPostExecute?.call();
      print('ump: _canRequestAds= $_canRequestAds');
      return;
    }
    final params = ConsentRequestParameters(
      consentDebugSettings: debugUmp ? _debugSettings : null,
    );

    bool? consentResult = await Admob.instance.getConsentResult();

    print('ump: consentResult = $consentResult');
    if (consentResult != null) {
      ConsentManager.setCanRequestAds(consentResult);
      print('ump: set can request ads');
      if (_canRequestAds) {
        print('ump: start init Admob');
        await Admob.instance.initAdmob();
      }
      onPostExecute?.call();
      return;
    }

    ///===========================================
    print('ump: start requestConsentInfoUpdate');
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
          () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ///form available, try to show it
          print('ump: _loadAndShowUmpForm');
          _loadAndShowUmpForm(onPostExecute);
        } else {
          print('ump: init Admob Fun successListener');
          ConsentManager.setCanRequestAds(true);

          await Admob.instance.initAdmob();
          onPostExecute?.call();
        }
      },
          (FormError error) async {
            print('ump: init Admob failedListener');
        ConsentManager.setCanRequestAds(true);

        await Admob.instance.initAdmob();
        onPostExecute?.call();
      },
    );
  }

  void _loadAndShowUmpForm(VoidCallback? onPostExecute) {
    ConsentForm.loadConsentForm(
          (ConsentForm consentForm) async {
        //show the form
        var consentResult = await Admob.instance.getConsentResult();
        if (consentResult != null) {
          ConsentManager.setCanRequestAds(consentResult);
          if (_canRequestAds) {
            await Admob.instance.initAdmob();
          }

          onPostExecute?.call();
        } else {
          consentForm.show((formError) async {
            ConsentManager.setCanRequestAds(await Admob.instance.getConsentResult() ?? true);
            if (_canRequestAds) {
              await Admob.instance.initAdmob();
            }

            onPostExecute?.call();
          });
        }
      },
          (FormError formError) async {
        ConsentManager.setCanRequestAds(await Admob.instance.getConsentResult() ?? true);
        if (_canRequestAds) {
          await Admob.instance.initAdmob();
        }

        onPostExecute?.call();
      },
    );
  }
}
