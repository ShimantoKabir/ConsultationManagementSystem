import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:uuid/uuid.dart';

class AuthManager{

  static Future<String> init() async {

    try{

      String authId = new Uuid().v1();
      var ui;

      var userInfo = await MySharedPreferences.getStringValue("userInfo");

      ui = jsonDecode(userInfo);
      print("auth init uid = ${ui['uid']}");
      print("auth init authId = $authId");

      await Firestore.instance
          .collection("userInfoList")
          .document(ui['uid'])
          .updateData({"authId" : authId});

      print("auth init authId = $authId");

      return Future.value(authId);

    }catch (e) {
      print(e);
      Fluttertoast.showToast(
          msg: "Something went wrong when auth manager try to initiate.");
      return Future.value(null);
    }

  }

}