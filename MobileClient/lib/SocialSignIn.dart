import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
final databaseReference = Firestore.instance;
final DateFormat df = new DateFormat('dd-MM-yyyy hh:mm:ss a');
SharedPreferences prefs;
String facebookAccessToken;

Future<AuthResult> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;
  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );
  return await auth.signInWithCredential(credential);
}

Future<AuthResult> signInWithFacebook() async {
  var facebookLogin = new FacebookLogin();
  facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
  var res = await facebookLogin.logIn(['email']);

  facebookAccessToken = res.accessToken.token;

  if (res.status == FacebookLoginStatus.loggedIn) {
    final AuthCredential credential = FacebookAuthProvider.getCredential(
      accessToken: res.accessToken.token,
    );
    return await auth.signInWithCredential(credential);
  } else {
    return null;
  }
}

Future<bool> setUserCredential(
    AuthResult authResult,Map<String, dynamic> data) async {

  prefs = await SharedPreferences.getInstance();
  FirebaseUser user = authResult.user;

  await prefs.setString('uid', user.uid);
  await prefs.setString('email', user.email);
  await prefs.setInt('userType', data['userType']);

  print('set user credential = $data');

  if (authResult.additionalUserInfo.isNewUser) {

    print("new user");
    await prefs.setString('displayName', user.displayName);
    await prefs.setString('photoUrl', user.photoUrl);
    String photoUrl;

    if(facebookAccessToken != null){

      print("facebook access token = $facebookAccessToken");
      final graphResponse = await get(
          'https://graph.facebook.com/v2.12/me?fields=picture.height(961)&access_token=$facebookAccessToken');

      final profile = jsonDecode(graphResponse.body);

      photoUrl = profile["picture"]["data"]["url"];

    }else {

      photoUrl = user.photoUrl;

    }

    var ui = {
      'uid' : user.uid,
      'email' : user.email,
      'userType' : data['userType'],
      'displayName' : user.displayName,
      'photoUrl' : photoUrl
    };

    MySharedPreferences.setStringValue('userInfo',jsonEncode(ui));

    return createUser(user,data,photoUrl);

  }else{

    print("old user");
    await prefs.setString('displayName', data['displayName']);
    await prefs.setString('photoUrl', data['photoUrl']);

    var ui = {
      'uid' : user.uid,
      'email' : user.email,
      'userType' : data['userType'],
      'displayName' : data['displayName'],
      'photoUrl' : data['photoUrl']
    };

    MySharedPreferences.setStringValue('userInfo',jsonEncode(ui));

    print("fcm token = ${data['token']}");

    databaseReference
        .collection("userInfoList")
        .document(user.uid)
        .updateData({"fcmRegistrationToken": data['token']}).then((res) {
      print('fcm registration token update successfully!');
    });

    return null;

  }

}

Future<bool> createUser(FirebaseUser user,Map<String, dynamic> data,String photoUrl) async {
  
  String hashTag = user.displayName;
  hashTag = (user.email != null) ?  hashTag + user.email : hashTag;
  hashTag = hashTag.replaceAll(' ', '');

  String timeZone = await FlutterNativeTimezone.getLocalTimezone();

  await databaseReference
      .collection("userInfoList")
      .document(user.uid)
      .setData({
    'displayName': user.displayName,
    'email': user.email,
    'phoneNumber': user.phoneNumber,
    'photoUrl': photoUrl,
    'uid': user.uid,
    'userType': data['userType'],
    'hourlyRate': null,
    'like': null,
    'shortDescription': null,
    'longDescription': null,
    'freeMinutesForNewCustomer': null,
    'fcmRegistrationToken': data['token'],
    'rating': null,
    'hashTag': hashTag,
    'coronavirusExperience' : null,
    'isOnline' : true,
    "lastOnlineAt": df.format(DateTime.now()),
    'timeZone' : timeZone
  });

  return Future.value(true);
}

Future<bool> logOut() async {

  SharedPreferences preferences =
      await SharedPreferences.getInstance();
  preferences.getKeys();
  for (String key in preferences.getKeys()) {
    preferences.remove(key);
  }

  bool isSignInWithGoogle = await googleSignIn.isSignedIn();

  if(isSignInWithGoogle){
    await googleSignIn.disconnect();
  }

  await FacebookLogin().logOut();
  await FirebaseAuth.instance.signOut();
  await FirebaseMessaging().deleteInstanceID();

  return Future.value(true);

}
