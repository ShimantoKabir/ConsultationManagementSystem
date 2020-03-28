import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peopeo/Const.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
final databaseReference = Firestore.instance;
SharedPreferences prefs;

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
  var res = await facebookLogin.logIn(['email']);
  if (res.status == FacebookLoginStatus.loggedIn) {
    final AuthCredential credential = FacebookAuthProvider.getCredential(
      accessToken: res.accessToken.token,
    );
    return await auth.signInWithCredential(credential);
  } else {
    return null;
  }
}

Future<Response> setUserCredential(
    AuthResult authResult, int ut, String token) async {
  prefs = await SharedPreferences.getInstance();
  FirebaseUser user = authResult.user;
  await prefs.setString('uid', user.uid);
  await prefs.setString('displayName', user.displayName);
  await prefs.setString('photoUrl', user.photoUrl);
  await prefs.setString('email', user.email);
  await prefs.setInt('userType', ut);

  List<String> userInfo = [
    user.uid,
    user.displayName,
    user.photoUrl,
    user.email,
    ut.toString()
  ];

  await prefs.setStringList('userInfo', userInfo);

  if (authResult.additionalUserInfo.isNewUser) {
    return createUser(user, ut, token);
  }
  {
    databaseReference
        .collection("userInfoList")
        .document(user.uid)
        .updateData({"fcmRegistrationToken": token}).then((res) {
      print('Fcm Registration token update successfully!');
    });

    return null;
  }
}

Future<Response> createUser(FirebaseUser user, int ut, String token) async {
  await databaseReference
      .collection("userInfoList")
      .document(user.uid)
      .setData({
    'displayName': user.displayName,
    'email': user.email,
    'phoneNumber': user.phoneNumber,
    'photoUrl': user.photoUrl,
    'uid': user.uid,
    'userType': ut,
    'hourlyRate': null,
    'like': null,
    'shortDescription': null,
    'longDescription': null,
    'freeMinutesForNewCustomer': null,
    'fcmRegistrationToken': token,
    'rating': null,
  });
  return createCustomerInBrainTree(user);
}

Future<Response> createCustomerInBrainTree(FirebaseUser user) async {
  String url = serverBaseUrl + '/pg/create-customer';
  Map<String, String> headers = {"Content-type": "application/json"};
  var request = {
    'userInfo': {
      'firstName': user.displayName,
      'email': user.email,
      'phone': user.phoneNumber,
      'customerId': user.uid
    }
  };
  Response response =
      await post(url, headers: headers, body: json.encode(request));
  print(response.body);
  return response;
}
