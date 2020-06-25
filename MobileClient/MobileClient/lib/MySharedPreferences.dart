import 'package:shared_preferences/shared_preferences.dart';

class MySharedPreferences{

  static SharedPreferences preferences;

  static Future<String> getStringValue(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  static Future<bool> setStringValue(String key,String val) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.setString(key,val);
  }

  static Future<int> getIntegerValue(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getInt(key);
  }

  static Future<bool> getBooleanValue(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getBool(key);
  }

  static Future<bool> setBooleanValue(String key,bool val) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.setBool(key,val);
  }

  static Future<List<String>> getStringList(String key) async {
    preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(key);
  }

}