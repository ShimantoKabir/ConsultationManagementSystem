import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:peopeo/Main.dart';
import 'package:peopeo/SocialSignIn.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {

  int userType = 0;
  bool needToShowUserTypeCheckBox = false;
  String confirmMsg;
  AuthResult authResult;
  FirebaseMessaging fm = new FirebaseMessaging();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/images/app_logo.jpeg'),
              SizedBox(height: 30),
              Visibility(
                visible: needToShowUserTypeCheckBox,
                child: Text(
                  '[Are you a customer or expert, please select]',
                  style: new TextStyle(
                      fontSize: 15.0,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Visibility(
                visible: needToShowUserTypeCheckBox,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Radio(
                        value: 1,
                        groupValue: userType,
                        onChanged: (int value) {
                          setState(() {
                            userType = value;
                            confirmMsg =
                                "You select 'Customer', Would you like to continue?";
                          });
                          confirmPopUp(context);
                        },
                      ),
                      Text(
                        'Customer',
                        style: new TextStyle(fontSize: 13.0),
                      ),
                      Radio(
                        value: 2,
                        groupValue: userType,
                        onChanged: (int value) {
                          setState(() {
                            userType = value;
                            confirmMsg =
                                "You select 'Expert', Would you like to continue?";
                          });
                          confirmPopUp(context);
                        },
                      ),
                      Text(
                        'Expert',
                        style: new TextStyle(
                          fontSize: 13.0,
                        ),
                      )
                    ]),
              ),
              Visibility(
                  visible: !needToShowUserTypeCheckBox,
                  child: googleSignInButton(context)),
              Visibility(
                visible: !needToShowUserTypeCheckBox,
                child: facebookSignInButton(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget googleSignInButton(BuildContext context) {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () {

        signInWithGoogle().then((val) {
          if (val.additionalUserInfo.isNewUser) {
            setState(() {
              needToShowUserTypeCheckBox = true;
              authResult = val;
            });
          } else {

            showAlertDialog(context, "Please wait, login processing!");
            Firestore.instance
                .collection("userInfoList")
                .document(val.user.uid)
                .get()
                .then((d) {

              fm.getToken().then((token) {

                print("fcm token in lp = $token");

                var data = {
                  'userType' : d.data['userType'],
                  'token' : token,
                  'displayName' : d.data['displayName'],
                  'photoUrl' : d.data['photoUrl']
                };

                setUserCredential(val,data).then((val) {
                  Phoenix.rebirth(context);
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return MyApp();
                      },
                    ),
                  );
                });

              }).catchError((err) {
                print("fcm token error whan google login.");
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                    msg: "Please try again.");
              });
            }).catchError((err) {
              print("user info fetch error when google login.");
              Navigator.of(context).pop();
              Fluttertoast.showToast(
                  msg: "Please try again.");
            });
          }
        }).catchError((err) {
          print("google login error.$err");
          Fluttertoast.showToast(msg: "Please try again.");
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
                image: AssetImage("assets/images/google_logo.png"),
                height: 15.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget facebookSignInButton(BuildContext context) {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () {
        signInWithFacebook().then((val) {

          if (val.additionalUserInfo.isNewUser) {
            setState(() {
              needToShowUserTypeCheckBox = true;
              authResult = val;
            });
          } else {
            showAlertDialog(context, "Please wait, login processing!");
            Firestore.instance
                .collection("userInfoList")
                .document(val.user.uid)
                .get()
                .then((d) {

              fm.getToken().then((token) {

                print("fcm token in lp = $token");

                setUserCredential(val,{
                  'userType' : d.data['userType'],
                  'token' : token,
                  'displayName' : d.data['displayName'],
                  'photoUrl' : d.data['photoUrl']
                }).then((val) {

                  Phoenix.rebirth(context);
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return MyApp();
                      },
                    ),
                  );
                });
              }).catchError((err) {
                print("fcm token error whan google login.");
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                    msg: "Please try again.");
              });

            }).catchError((err) {
              print("user info fetch error when google login.");
              Navigator.of(context).pop();
              Fluttertoast.showToast(
                  msg: "Please try again.");
            });
          }
        }).catchError((err) {
          print("facebook login error.");
          Fluttertoast.showToast(msg: "Please try again.");
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
                image: AssetImage("assets/images/facebook_logo.png"),
                height: 15.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with facebook',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void confirmPopUp(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert',
              style: TextStyle(
                  color: Colors.pink,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          content: Wrap(children: <Widget>[
            Text(
              confirmMsg,
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.normal),
            )
          ]),
          actions: <Widget>[
            FlatButton(
              child: Text('No',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Yes',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                processUserRegistration(context);
              },
            )
          ],
        );
      },
    );
  }

  showAlertDialog(BuildContext context, String msg) {
    AlertDialog alert = AlertDialog(
      content: ListTile(
        leading: CircularProgressIndicator(),
        title: Text("Loading"),
        subtitle: Text(msg),
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void processUserRegistration(BuildContext context) {
    showAlertDialog(context, "Please wait user registration processing.");
    fm.getToken().then((token) {

      print("fcm token in lp = $token");

      setUserCredential(authResult,{
        'userType' : userType,
        'token' : token
      }).then((val) {

        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Phoenix.rebirth(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MyApp();
            },
          ),
        );
      }).catchError((err) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Fluttertoast.showToast(msg: "Please try again.");
      });
    }).catchError((err) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Fluttertoast.showToast(msg: "Please try again.");
    });
  }

}
