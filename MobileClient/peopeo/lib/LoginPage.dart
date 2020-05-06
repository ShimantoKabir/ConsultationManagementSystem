import 'package:cloud_firestore/cloud_firestore.dart';
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
                  child: googleSignInButton()),
              Visibility(
                visible: !needToShowUserTypeCheckBox,
                child: facebookSignInButton(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget googleSignInButton() {
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

                var data = {
                  'userType' : d.data['userType'],
                  'token' : token,
                  'displayName' : d.data['displayName'],
                  'photoUrl' : d.data['photoUrl']
                };

                setUserCredential(val,data).then((val) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
                Navigator.pop(context);
                Fluttertoast.showToast(
                    msg: "Something went wrong, please try again!");
              });
            }).catchError((err) {
              Fluttertoast.showToast(
                  msg: "Something went wrong, please try again!");
            });
          }
        }).catchError((err) {
          print(err);
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Something went wrong, please try again!");
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

  Widget facebookSignInButton() {
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

                setUserCredential(val,{
                  'userType' : d.data['userType'],
                  'token' : token,
                  'displayName' : d.data['displayName'],
                  'photoUrl' : d.data['photoUrl']
                }).then((val) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
                Navigator.pop(context);
                Fluttertoast.showToast(
                    msg: "Something went wrong, please try again!");
              });
            }).catchError((err) {
              Navigator.pop(context);
              Fluttertoast.showToast(
                  msg: "Something went wrong, please try again!");
            });
          }
        }).catchError((err) {
          Fluttertoast.showToast(msg: "Something went wrong, please try again!");
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
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('Yes',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                processUserRegistration();
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

  void processUserRegistration() {
    showAlertDialog(context, "Please wait user registration processing.");
    fm.getToken().then((token) {

      setUserCredential(authResult,{
        'userType' : userType,
        'token' : token
      }).then((val) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MyApp();
            },
          ),
        );
      }).catchError((err) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Something went wrong, please try again!");
      });
    }).catchError((err) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Something went wrong, please try again!");
    });
  }

}
