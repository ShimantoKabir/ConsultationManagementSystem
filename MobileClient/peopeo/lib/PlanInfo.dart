import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:side_header_list_view/side_header_list_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:peopeo/Chat.dart';
import 'package:peopeo/Plan.dart';

class PlanInfo extends StatefulWidget {
  final String uid;
  final int userType;

  PlanInfo({Key key, @required this.uid, @required this.userType})
      : super(key: key);

  @override
  PlanInfoState createState() =>
      new PlanInfoState(uid: uid, userType: userType);
}

class PlanInfoState extends State<PlanInfo> {
  String uid;
  int userType;

  PlanInfoState({Key key, @required this.uid, @required this.userType});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          title: Text('Schedules',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          centerTitle: true),
      body: Container(
        child: FutureBuilder<List<Plan>>(
            future: getPlanList(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: Text(
                  "No schedules found",
                  style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.red,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold),
                ));
              } else {
                return SideHeaderListView(
                  itemCount: snapshot.data.length,
                  padding: new EdgeInsets.all(5.0),
                  headerBuilder: (BuildContext context, int index) {
                    return new Container(
                        child: Text(
                            snapshot.data[index].startTime.substring(0, 12),
                            style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Armata',
                                fontWeight: FontWeight.bold)));
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      elevation: 2.0,
                      child: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(snapshot.data[index].topic,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Armata',
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                "Start Time " +
                                    snapshot.data[index].startTime.substring(12,
                                        snapshot.data[index].startTime.length),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Armata',
                                    fontWeight: FontWeight.normal)),
                            Text(
                                "End Time " +
                                    snapshot.data[index].endTime.substring(12,
                                        snapshot.data[index].endTime.length),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Armata',
                                    fontWeight: FontWeight.normal)),
                            showPaymentButtonOrChatButton(snapshot.data[index])
                          ],
                        ),
                      ),
                    );
                  },
                  hasSameHeader: (int a, int b) {
                    return snapshot.data[a].startTime.substring(0, 6) ==
                        snapshot.data[b].startTime.substring(0, 6);
                  },
                  itemExtend: null,
                );
              }
            }),
      ),
    );
  }

  Future<List<Plan>> getPlanList() async {
    String timeZone = await FlutterNativeTimezone.getLocalTimezone();

    String url = serverBaseUrl + '/plan/get-all-plan-by-user';
    Map<String, String> headers = {"Content-type": "application/json"};

    var request;

    if (userType == 2) {
      request = {
        'plan': {'conUid': uid, 'userType': 2, 'timeZone': timeZone}
      };
    } else {
      request = {
        'plan': {'cusUid': uid, 'userType': 1, 'timeZone': timeZone}
      };
    }

    Response response =
        await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      print(response.body.toString());
      return HttpResponse.fromJson(json.decode(response.body)).planList;
    } else {
      print("Plan list getting errowr!");
      Fluttertoast.showToast(msg: "Plan list getting error!");
      return [];
    }
  }

  void getClientToken(String amount, int planId) async {
    String url = serverBaseUrl + '/pg/get-client-token';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {'customerId': uid};

    Response response =
        await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      // checking if server returns an OK response, then parse the JSON.
      print(HttpResponse.fromJson(json.decode(response.body)).clientToken);

      String clientToken =
          HttpResponse.fromJson(json.decode(response.body)).clientToken;

      reloadAuth(clientToken, amount, planId);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  void goBrowserForPayment(String aid) async {
    String url = webClientBaseUrl + '/payment.html?aid=' + aid + "&uid=" + uid;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  showPaymentButtonOrChatButton(Plan p) {
    String buttonText = "Start Chat";
    // handle consultant
    if (userType == 2) {
      if (p.paymentTransId == null) {
        return Text("Payment Incomplete!",
            style: TextStyle(
                color: Colors.red,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold));
      } else {
        return Container(
          height: 20.0,
          width: 10.0,
          margin: EdgeInsets.symmetric(vertical: 3.0),
          child: OutlineButton(
            child: Text(buttonText,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              final fStartTime = DateTime.parse(p.fStartTime);
              final fEndTime = DateTime.parse(p.fEndTime);

              // allow enter chat room before 5 minutes
              print("before sub start time $fStartTime");
              final subStartTime = fStartTime.subtract(Duration(minutes: 5));
              print("after sub start time $subStartTime");
              print(DateTime.now());

              bool scheduleOk = true;

              if (DateTime.now().isBefore(subStartTime)) {
                scheduleOk = false;

                int wm = subStartTime.difference(DateTime.now()).inMilliseconds;
                int waitMinutes = ((wm / 1000) / 60).round();
                Fluttertoast.showToast(
                    msg: "Wait $waitMinutes minute's to enter the caht room!");
              }

              if (DateTime.now().isAfter(fEndTime)) {
                scheduleOk = false;
                Fluttertoast.showToast(msg: "Chat session has been ended!");
              }

              if (p.freeMinutesForNewCustomer != null) {
                final DateTime pDateTime = fStartTime
                    .add(Duration(minutes: p.freeMinutesForNewCustomer));

                print("adding time after free minutes = $pDateTime");

                if (DateTime.now().isAfter(pDateTime)) {
                  scheduleOk = false;
                  Fluttertoast.showToast(
                      msg:
                          "This customer has free minute and it's gone, so we recomandad him to create a new schedule!");
                }
              }

              print("scheduleOk $scheduleOk");

              if (scheduleOk) {
                Firestore.instance
                    .collection("userInfoList")
                    .document(p.cusUid)
                    .get()
                    .then((d) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Chat(
                              peerId: d.data['uid'],
                              peerAvatar: d.data['photoUrl'],
                              displayName: d.data['displayName'],
                              plan: p,
                              userType: userType,
                              uid: uid)));
                });
              }
            },
          ),
        );
      }

      // handle customer
    } else {
      if (p.paymentTransId == null) {
        return Container(
          height: 20.0,
          width: 10.0,
          margin: EdgeInsets.symmetric(vertical: 3.0),
          child: OutlineButton(
            color: Colors.red,
            textColor: Colors.black,
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: Colors.blue, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(2)),
            child: Text('Complete Payment',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              final fStartTime = DateTime.parse(p.fStartTime);
              final fEndTime = DateTime.parse(p.fEndTime);

              int millis = fEndTime.difference(fStartTime).inMilliseconds;
              double minutes = (millis / 1000) / 60;

              double costPerMinute = p.hourlyRate / 60;
              double totalCostForCus = minutes * costPerMinute;
              confirmPopUp(context, totalCostForCus.toString(), p);
            },
          ),
        );
      } else {
        return Container(
          height: 20.0,
          width: 10.0,
          margin: EdgeInsets.symmetric(vertical: 3.0),
          child: OutlineButton(
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(2.0)),
            child: Text(buttonText,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              int fm = p.freeMinutesForNewCustomer;
              print("free minute = $fm");

              final fStartTime = DateTime.parse(p.fStartTime);
              final fEndTime = DateTime.parse(p.fEndTime);

              print("before sub start time $fStartTime");
              // allow enter chat room before 5 minutes
              final subStartTime = fStartTime.subtract(Duration(minutes: 5));
              print("after sub start time $subStartTime");
              print(DateTime.now());

              bool scheduleOk = true;

              if (DateTime.now().isBefore(subStartTime)) {
                scheduleOk = false;

                int wm = subStartTime.difference(DateTime.now()).inMilliseconds;
                int waitMinutes = ((wm / 1000) / 60).round();
                Fluttertoast.showToast(
                    msg: "Wait $waitMinutes minute's to enter the caht room!");
              }

              if (DateTime.now().isAfter(fEndTime)) {
                scheduleOk = false;
                Fluttertoast.showToast(msg: "Chat sesssion has been ended!");
              }

              print("scheduleOk = $scheduleOk");

              if (p.freeMinutesForNewCustomer != null) {
                final DateTime pDateTime = fStartTime
                    .add(Duration(minutes: p.freeMinutesForNewCustomer));

                print("adding time after free minutes = $pDateTime");

                if (DateTime.now().isAfter(pDateTime)) {
                  scheduleOk = false;
                  Fluttertoast.showToast(
                      msg:
                          "Your free minut's is gone, we recomand you to book a new schedule!");
                }
              }

              if (scheduleOk) {
                Firestore.instance
                    .collection("userInfoList")
                    .document(p.conUid)
                    .get()
                    .then((d) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Chat(
                              peerId: d.data['uid'],
                              peerAvatar: d.data['photoUrl'],
                              displayName: d.data['displayName'],
                              plan: p,
                              userType: userType,
                              uid: uid)));
                });
              }
            },
          ),
        );
      }
    }
  }

  void confirmPopUp(BuildContext context, String amount, Plan p) {
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
              "You will be charged $amount \$",
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
                Navigator.of(context).pop();
                getClientToken(amount, p.id);
              },
            )
          ],
        );
      },
    );
  }

  void reloadAuth(String clientToken, String amount, int planId) async {
    String url = serverBaseUrl + '/auth/reload';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {
      'auth': {
        'uId': uid,
        'amount': amount,
        'clientToken': clientToken,
        'planId': planId
      }
    };

    Response response =
        await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      String aid = HttpResponse.fromJson(json.decode(response.body)).aid;
      goBrowserForPayment(aid);
      print(response.body.toString());
    } else {
      throw Exception('Failed to load post');
    }
  }

}
