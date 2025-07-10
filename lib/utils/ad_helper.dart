import 'dart:math';

enum AdsSplashType { inter, open, none }

class AdHelper {
  ///interval time between 2 inter show
  static int _intervalBetweenInter = 0;
  static int _lastTimeDismissInter = -1;

  ///interval time from start
  static int _intervalInterFromStart = 0;

  ///time start open app
  static int _timeStartApp = -1;

  ///config ads
  static bool _configAppOpen = true;
  static bool _configInter = true;
  static String _rateAoa = '0_100';

  static void init({
    required int intervalBetweenInter,
    required int intervalFromStart,
    required bool configAppOpen,
    required bool configInter,
    required String rateAoa,
  }) {
    _lastTimeDismissInter = -1;
    _timeStartApp = DateTime.now().millisecondsSinceEpoch;
    setIntervalBetweenInter(value: intervalBetweenInter);
    setIntervalFromStart(value: intervalFromStart);
    setConfigAppOpen(value: configAppOpen);
    setConfigInter(value: configInter);
    setRateAoa(rateAoa: rateAoa);
  }

  static void setConfigAppOpen({required bool value}) {
    _configAppOpen = value;
  }

  static void setConfigInter({required bool value}) {
    _configInter = value;
  }

  static void setRateAoa({required String rateAoa}) {
    _rateAoa = rateAoa;
  }

  static void setIntervalBetweenInter({required int value}) {
    _intervalBetweenInter = value;
  }

  static void setIntervalFromStart({required int value}) {
    _intervalInterFromStart = value;
  }

  static void setLastTimeDismissInter() {
    _lastTimeDismissInter = DateTime.now().millisecondsSinceEpoch;
  }

  static bool canShowNextInter() {
    if (_timeStartApp == -1) {
      return false;
    }

    final currentDatetime = DateTime.now();

    if ((currentDatetime.millisecondsSinceEpoch - _timeStartApp) < _intervalInterFromStart) {
      return false;
    }

    if (_lastTimeDismissInter == -1) {
      return true;
    }

    if ((currentDatetime.millisecondsSinceEpoch - _lastTimeDismissInter) >= _intervalBetweenInter) {
      return true;
    }

    return false;
  }

  static AdsSplashType get splashType {
    if (_configInter && _configAppOpen) {
      if (isValidFormat(rateAoa: _rateAoa)) {
        if (getRandomOpenAd(rateAoa: _rateAoa)) {
          if (_configAppOpen) {
            return AdsSplashType.open;
          } else {
            return AdsSplashType.none;
          }
        } else {
          if (_configInter) {
            return AdsSplashType.inter;
          } else {
            return AdsSplashType.none;
          }
        }
      } else {
        return AdsSplashType.none;
      }
    } else {
      if (_configAppOpen) {
        return AdsSplashType.open;
      }
      if (_configInter) {
        return AdsSplashType.inter;
      }
      return AdsSplashType.none;
    }
  }

  static bool isValidFormat({required String rateAoa}) {
    final split = rateAoa.split('_');
    final int openRate;
    final int interRate;

    if (split.length != 2) {
      openRate = 0;
      interRate = 100;
    } else {
      openRate = int.parse(split[0]) ?? 0;
      interRate = int.parse(split[1]) ?? 100;
    }
    return (openRate + interRate == 100) && openRate >= 0 && interRate >= 0;
  }

  static bool getRandomOpenAd({required String rateAoa}) {
    final split = rateAoa.split('_');
    final int appOpenRate;

    if (split.length != 2) {
      appOpenRate = 0;
    } else {
      appOpenRate = int.tryParse(split[0]) ?? 0;
    }

    Random random = Random();
    int randomNumber = random.nextInt(100);

    return randomNumber <= appOpenRate;
  }
}
