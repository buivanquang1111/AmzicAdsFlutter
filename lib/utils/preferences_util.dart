import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtil {
  static SharedPreferences? _pref;

  static Future<void> init() async {
    _pref ??= await SharedPreferences.getInstance();
  }

  static int getCountOpenApp(){
    return _pref?.getInt("count_open_app")?? 0;
  }
  static void increaseCountOpenApp(){
    var count = getCountOpenApp();
    count++;
    _pref?.setInt("count_open_app", count);
  }
}