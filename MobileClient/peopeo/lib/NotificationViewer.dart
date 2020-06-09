import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:peopeo/AuthManager.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/ConsultantProfile.dart';

class NotificationViewer extends StatefulWidget {
  final String uid;

  NotificationViewer({Key key, @required this.uid}) : super(key: key);

  @override
  NotificationViewerState createState() =>
      new NotificationViewerState(uid: uid);
}

class NotificationViewerState extends State<NotificationViewer> {
  NotificationViewerState({Key key, @required this.uid});

  String uid;
  TextEditingController payPalEmailTECtl = TextEditingController();
  bool isUiEnable = true;
  String alertMsg = 'Loading...';

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isUiEnable,
      child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.black),
            backgroundColor: Colors.white,
            title: new Text('Notifications',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: StreamBuilder(
              stream: Firestore.instance
                  .collection('notificationList')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder:
                  (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  List<Map<String, dynamic>> nList = [];

                  snapshot.data.documents.forEach((f) {
                    nList.add({
                      'title': f['title'],
                      'fcmRegistrationToken': f['fcmRegistrationToken'],
                      'uid': f['uid'],
                      'body': f['body'],
                      'invitationSenderUid': f['invitationSenderUid'],
                      'seenStatus': f['seenStatus'],
                      'timeStamp': f['timeStamp'],
                      'startTime': f['startTime'],
                      'endTime': f['endTime'],
                      'topic': f['topic'],
                      'type': f['type'],
                      'docId': f.documentID,
                      'planId': f['planId'],
                      'amount': f['amount'],
                      'payPalEmail': f['payPalEmail'],
                      'isPaid': f['isPaid'],
                    });
                  });

                  Comparator<Map<String, dynamic>> x =
                      (b, a) => a['timeStamp'].compareTo(b['timeStamp']);

                  nList.sort(x);

                  nList.forEach((f) {
                    print("timeStamp = ${f['timeStamp']}, title = ${f['title']}");
                  });

                  if (nList.length > 0) {
                    return ListView.builder(
                      itemBuilder: (context, index) =>
                          buildItem(context, nList[index]),
                      itemCount: nList.length,
                    );
                  } else {
                    return Center(
                      child: Text("[No message found]",
                          style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Armata',
                              fontWeight: FontWeight.bold)),
                    );
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  );
                }
              }),
          bottomNavigationBar: Visibility(
            visible: !isUiEnable,
            child: Container(
              color: Colors.white,
              height: 50.0,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        strokeWidth: 1.0,
                      )),
                  SizedBox(width: 10),
                  Text(alertMsg,
                      style: TextStyle(
                        fontSize: 17.0,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Armata',
                      ))
                ],
              ),
            ),
          )
      )
    );
  }

  buildItem(BuildContext context, document) {
    return Card(
      color: document['seenStatus'] == 1 ? Colors.white : Colors.white30,
      child: ListTile(
        leading: document['seenStatus'] == 1
            ? Icon(Icons.notifications, size: 40.0)
            : Icon(Icons.notifications_none, size: 40.0),
        title: Text(document['title'],
            style: getTextStyle(Colors.red, FontWeight.bold, 15.0)),
        subtitle: Wrap(
          // 1 = booking request (start time, end time, topic, body , title)
          // 2 = booking request cancellation (start time, end time, topic, body , title)
          // 3 = booking request acceptation (start time, end time, topic, body , title)
          // 4 = chat session reminder (start time, end time, topic, body , title)
          // 5 = payment reminder (start time, end time, topic, body , title)
          // 6 = expert send invitation to customer (title, body, invitation sender id)
          // 7 = payment received (title, body, amount, email, plan id)

          children: <Widget>[
            Visibility(
              visible: document['type'] == 6 || document['type'] == 7,
              child: Text(document['body'],
                  style: getTextStyle(Colors.black, FontWeight.normal, 14.0)),
            ),
            Visibility(
              visible: document['type'] == 1 ||
                  document['type'] == 2 ||
                  document['type'] == 3 ||
                  document['type'] == 4 ||
                  document['type'] == 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      document['topic'] == null
                          ? "empty"
                          : "Topic ${document['topic']}",
                      style: getTextStyle(Colors.black, FontWeight.bold, 14.0)),
                  Text(
                      document['startTime'] == null
                          ? "empty"
                          : "Start at ${document['startTime']}",
                      style:
                          getTextStyle(Colors.black, FontWeight.normal, 11.0)),
                  Text(
                      document['endTime'] == null
                          ? "empty"
                          : "End at ${document['endTime']}",
                      style:
                          getTextStyle(Colors.black, FontWeight.normal, 11.0)),
                ],
              ),
            ),
            Visibility(
              visible: document['type'] == 6,
              child: OutlineButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ConsultantProfile(
                            uid: document['invitationSenderUid']);
                      },
                    ),
                  );
                },
                child: Text("See My Profile".toUpperCase(),
                    style: TextStyle(fontSize: 14)),
              ),
            ),
            Visibility(
              visible: document['type'] == 7,
              child: OutlineButton(
                onPressed: () {
                  if (document['isPaid'] == null) {
                    if (document['payPalEmail'] == null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: new Text('Paypal Email',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Armata',
                              )),
                          content: TextField(
                              decoration: InputDecoration(
                                  contentPadding:
                                      EdgeInsets.fromLTRB(15.0, 5.0, 5.0, 5.0),
                                  border: OutlineInputBorder()),
                              controller: payPalEmailTECtl,
                              keyboardType: TextInputType.emailAddress),
                          actions: <Widget>[
                            FlatButton(
                                child: Text('Close',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Armata',
                                        fontWeight: FontWeight.bold)),
                                onPressed: () =>
                                    Navigator.of(context).pop(false)),
                            FlatButton(
                                child: Text('Save',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontFamily: 'Armata',
                                        fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  Navigator.of(context).pop(false);

                                  if (payPalEmailTECtl.text.trim().isEmpty) {
                                    Fluttertoast.showToast(
                                        msg: "Email address required!",
                                        toastLength: Toast.LENGTH_SHORT);
                                  } else {
                                    try {
                                      Firestore.instance
                                          .collection('userInfoList')
                                          .document(uid)
                                          .updateData({
                                        "payPalEmail":
                                            payPalEmailTECtl.text.trim()
                                      }).then((s) {
                                        Firestore.instance
                                            .collection('notificationList')
                                            .where('type', isEqualTo: 7)
                                            .where('uid', isEqualTo: uid)
                                            .getDocuments()
                                            .then((nDocs) {
                                          nDocs.documents.forEach((nDoc) {
                                            Firestore.instance
                                                .collection('notificationList')
                                                .document(nDoc.documentID)
                                                .updateData({
                                              "payPalEmail":
                                                  payPalEmailTECtl.text.trim()
                                            });
                                          });
                                        });
                                      });

                                      var request = {
                                        'planId': document['planId'],
                                        'email': payPalEmailTECtl.text.trim(),
                                        'amount': document['amount']
                                      };

                                      setState(() {
                                        isUiEnable = false;
                                        alertMsg = "Payment precessing...";
                                      });

                                      payout(request, document, context).whenComplete((){

                                        setState(() {
                                          isUiEnable = true;
                                        });

                                      });



                                    } catch (e) {
                                      Fluttertoast.showToast(
                                          msg: "Something went wrong!");
                                    }
                                  }
                                })
                          ],
                        ),
                      );
                    } else {
                      var request = {
                        'planId': document['planId'],
                        'email': document['payPalEmail'],
                        'amount': document['amount']
                      };

                      setState(() {
                        isUiEnable = false;
                        alertMsg = "Payment precessing...";
                      });

                      payout(request, document, context).whenComplete((){

                        setState(() {
                          isUiEnable = true;
                        });

                      });
                    }
                  } else {
                    Fluttertoast.showToast(msg: "Already paid!");
                  }
                },
                child: Text(showPayPalEmailBtnTxt(document),
                    style: TextStyle(fontSize: 14)),
              ),
            )
          ],
        ),
        trailing: InkWell(
          child: Icon(Icons.delete),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => new AlertDialog(
                title: new Text('Alert',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Armata',
                    )),
                content: new Text('Do you want to delete?',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Armata',
                    )),
                actions: <Widget>[
                  FlatButton(
                      child: Text('No',
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Armata',
                              fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.of(context).pop(false)),
                  FlatButton(
                      child: Text('Yes',
                          style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'Armata',
                              fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        Firestore.instance
                            .collection('notificationList')
                            .document(document['docId'])
                            .delete()
                            .then((res) {
                          Fluttertoast.showToast(
                              msg: "Delete successful!",
                              toastLength: Toast.LENGTH_LONG);
                        }).catchError((err) {
                          Fluttertoast.showToast(
                              msg: "Delete unsuccessful!",
                              toastLength: Toast.LENGTH_LONG);
                        });
                      })
                ],
              ),
            );
          },
        ),
        isThreeLine: true,
        onTap: () {
          Firestore.instance
              .collection('notificationList')
              .document(document['docId'])
              .updateData({"seenStatus": 1});
        },
      ),
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

  Future<int> payout(data, document, BuildContext context) async {
    int res;
    String authId = await AuthManager.init();

    if (authId == null) {
      Fluttertoast.showToast(msg: "Auth initialization error.");
      res = 404;
    } else {
      String url = serverBaseUrl + '/pg/payout';
      Map<String, String> headers = {"Content-type": "application/json"};

      var request = {
        'planId': data['planId'],
        'email': data['email'],
        'amount': data['amount'],
        'authId': authId,
        'uid': uid
      };

      Response response =
          await post(url, headers: headers, body: json.encode(request));

      if (response.statusCode == 200) {
        var body = json.decode(response.body);

        if (body['code'] == 200) {
          print("response body = ${body['code']}");

          await Firestore.instance
              .collection('notificationList')
              .document(document['docId'])
              .updateData({"isPaid": true});
        } else {
          Fluttertoast.showToast(msg: "Something went wrong!");
        }

        res = 200;
      } else {
        Fluttertoast.showToast(msg: "Something went wrong!");
        res = 404;
      }
    }

    return res;
  }

  TextStyle getTextStyle(Color color, FontWeight fontWeight, double fs) {
    return TextStyle(
        color: color,
        fontFamily: 'Armata',
        fontWeight: fontWeight,
        fontSize: fs);
  }

  String showPayPalEmailBtnTxt(document) {
    String btnTxt;

    if (document['payPalEmail'] == null) {
      btnTxt = "Set Paypal Email Address".toUpperCase();
    } else {
      if (document['isPaid'] == null) {
        btnTxt = "Get your payment".toUpperCase();
      } else {
        btnTxt = "Paid".toUpperCase();
      }
    }

    return btnTxt;
  }
}
