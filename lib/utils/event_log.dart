import 'package:firebase_analytics/firebase_analytics.dart';

class EventLog {
  static final FirebaseAnalytics _log = FirebaseAnalytics.instance;

  static void logEvent(String name, {Map<String, Object>? parameters}) {
    String safeName = name.length > 40 ? name.substring(0, 40) : name;
    _log.logEvent(name: safeName, parameters: parameters);
  }
}
