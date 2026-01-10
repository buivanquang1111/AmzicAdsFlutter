import 'package:amazic_ads_flutter/admob.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigKey {
  final String name;
  final dynamic defaultValue;
  final Type valueType;

  RemoteConfigKey({required this.name, required this.defaultValue, required this.valueType});
}

class RemoteConfig {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static final Map<String, RemoteConfigKey> _keyMap = {};

  /// Init remote config and fetch remote values
  static Future<void> init({
    required List<RemoteConfigKey> remoteConfigKeys,
    Duration fetchTimeout = const Duration(seconds: 30),
    Duration minimumFetchInterval = const Duration(seconds: 15),
  }) async {
    // Store keys
    for (final key in remoteConfigKeys) {
      _keyMap[key.name] = key;
    }

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(fetchTimeout: fetchTimeout, minimumFetchInterval: minimumFetchInterval),
    );

    // Set default values
    final defaultValues = {for (final key in _keyMap.values) key.name: key.defaultValue};
    await _remoteConfig.setDefaults(defaultValues);

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('⚠️ RemoteConfig fetch error: $e');
    }
  }

  /// Get String config value
  static String getString(String keyName) {
    return _remoteConfig.getString(keyName);
  }

  /// Get bool config value
  static bool getBool(String keyName) {
    if (Admob.instance.isAdUnitDetected(keyName) == true) {
      return false;
    }
    return _remoteConfig.getBool(keyName) && _remoteConfig.getBool('show_ads');
  }

  static bool getBoolDefault(String keyName) {
    return _remoteConfig.getBool(keyName);
  }

  /// Get int config value
  static int getInt(String keyName) {
    return _remoteConfig.getInt(keyName);
  }

  /// Get double config value
  static double getDouble(String keyName) {
    return _remoteConfig.getDouble(keyName);
  }

  /// Auto-get based on type defined in _keyMap
  static dynamic get(String keyName) {
    final key = _keyMap[keyName];
    if (key == null) return null;

    switch (key.valueType) {
      case String:
        return getString(keyName);
      case bool:
        return getBool(keyName);
      case int:
        return getInt(keyName);
      case double:
        return getDouble(keyName);
      default:
        return _remoteConfig.getValue(keyName).asString();
    }
  }

  /// Optional: Check if a key exists in the config
  static bool containsKey(String keyName) {
    return _keyMap.containsKey(keyName);
  }
}
