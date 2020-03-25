import 'package:shared_preferences/shared_preferences.dart';

class MySharedPreferences{

  static SharedPreferences preferences;

  static Future<String> getStringValue(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  static Future<int> getIntegerValue(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getInt(key);
  }

  static Future<List<String>> getStringList(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(key);
  }

}