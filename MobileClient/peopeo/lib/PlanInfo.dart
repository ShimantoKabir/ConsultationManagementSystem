import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/MyWebView.dart';
import 'package:side_header_list_view/side_header_list_view.dart';
import 'package:peopeo/Chat.dart';
import 'package:peopeo/Plan.dart';
import 'package:intl/intl.dart';

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
  DateFormat df = new DateFormat('dd-MM-yyyy hh:mm a');
  bool isInternetAvailable = true;
  StreamSubscription<ConnectivityResult> connectivitySubscription;

  PlanInfoState({Key key, @required this.uid, @required this.userType});

  @override
  void initState() {
    super.initState();
    print("uid = $uid and user type = $userType");

    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => isInternetAvailable = false);
        print('You are disconnected from the internet.');
      } else {
        setState(() => isInternetAvailable = true);
        print('Data connection is available.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: !isInternetAvailable,
        child: Scaffold(
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
                  if (snapshot.hasData) {
                    if (snapshot.data.length > 0) {
                      return SideHeaderListView(
                        itemCount: snapshot.data.length,
                        padding: new EdgeInsets.all(5.0),
                        headerBuilder: (BuildContext context, int index) {
                          String st = df.format(
                              DateTime.parse(snapshot.data[index].fStartTime));
                          return Container(
                              child: Text(st.substring(0, 10),
                                  style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black,
                                      fontFamily: 'Armata',
                                      fontWeight: FontWeight.bold)));
                        },
                        itemBuilder: (BuildContext context, int index) {
                          String tp = snapshot.data[index].topic;
                          String st = df.format(
                              DateTime.parse(snapshot.data[index].fStartTime));
                          String et = df.format(
                              DateTime.parse(snapshot.data[index].fEndTime));
                          return Card(
                            elevation: 2.0,
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Text("Topic $tp",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Armata',
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold)),
                                  getPeerDisplayName(snapshot.data[index]),
                                  Text(
                                      "Start Time " +
                                          st.substring(11, st.length),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Armata',
                                          fontWeight: FontWeight.normal)),
                                  Text(
                                      "End Time " + et.substring(11, et.length),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Armata',
                                          fontWeight: FontWeight.normal)),
                                  showPaymentButtonOrChatButton(
                                      snapshot.data[index])
                                ],
                              ),
                            ),
                          );
                        },
                        hasSameHeader: (int a, int b) {
                          return snapshot.data[a].fStartTime.substring(0, 9) ==
                              snapshot.data[b].fStartTime.substring(0, 9);
                        },
                        itemExtend: null,
                      );
                    } else {
                      return Center(
                          child: Text(
                        "[No schedules found]",
                        style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.red,
                            fontFamily: 'Armata',
                            fontWeight: FontWeight.bold),
                      ));
                    }
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    );
                  }
                }),
          ),
          bottomNavigationBar: Visibility(
              visible: !isInternetAvailable,
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
                    Text("Trying to connect internet...",
                        style: TextStyle(
                          fontSize: 17.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Armata',
                        ))
                  ],
                ),
              )),
        ));
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
    print("response $response");

    if (response.statusCode == 200) {
      print(response.body);
      var body = json.decode(response.body);

      if (body['code'] == 404) {
        return [];
      } else {
        return HttpResponse.fromJson(json.decode(response.body)).planList;
      }
    } else {
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
      // print(HttpResponse.fromJson(json.decode(response.body)).clientToken);

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

    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (BuildContext context) => MyWebView(
                  title: "Payment",
                  url: url,
                )))
        .whenComplete(() {
      MySharedPreferences.getBooleanValue('isPaymentSuccessful')
          .then((isPaymentSuccessful) {
        if (isPaymentSuccessful) {
          Fluttertoast.showToast(
              msg: "Payment successful!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0);
        } else {
          Fluttertoast.showToast(
              msg: "Payment unsuccessful!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      });
    });
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
              // print("before sub start time $fStartTime");
              final subStartTime = fStartTime.subtract(Duration(minutes: 5));
              // print("after sub start time $subStartTime");
              // print(DateTime.now());

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

                // print("adding time after free minutes = $pDateTime");

                if (DateTime.now().isAfter(pDateTime)) {
                  scheduleOk = false;
                  Fluttertoast.showToast(
                      msg:
                          "This customer has free minute and it's gone, so we recomandad him to create a new schedule!");
                }
              }

              // print("scheduleOk $scheduleOk");

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
            onPressed: () async {
              Connectivity().checkConnectivity().then((connectivityResult) {
                if (connectivityResult == ConnectivityResult.none) {
                  Fluttertoast.showToast(
                      msg: "No internat connection available.");
                } else {
                  final fStartTime = DateTime.parse(p.fStartTime);
                  final fEndTime = DateTime.parse(p.fEndTime);

                  int milliseconds =
                      fEndTime.difference(fStartTime).inMilliseconds;

                  Duration timeDuration = Duration(milliseconds: milliseconds);
                  double chargeAmount =
                      p.hourlyRate * (timeDuration.inMinutes / 60);
                  confirmPopUp(context, chargeAmount.toStringAsFixed(2), p);
                }
              });
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
              // print("free minute = $fm");

              final fStartTime = DateTime.parse(p.fStartTime);
              final fEndTime = DateTime.parse(p.fEndTime);

              // print("before sub start time $fStartTime");
              // allow enter chat room before 5 minutes
              final subStartTime = fStartTime.subtract(Duration(minutes: 5));
              // print("after sub start time $subStartTime");
              // print(DateTime.now());

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

              // print("scheduleOk = $scheduleOk");

              if (p.freeMinutesForNewCustomer != null) {
                final DateTime pDateTime = fStartTime
                    .add(Duration(minutes: p.freeMinutesForNewCustomer));

                // print("adding time after free minutes = $pDateTime");

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
      // print(response.body.toString());
    } else {
      throw Exception('Failed to load post');
    }
  }

  getPeerDisplayName(Plan data) {
    String uid;
    String head;

    if (userType == 1) {
      uid = data.conUid;
      head = "Expert";
    } else {
      uid = data.cusUid;
      head = "Customer";
    }

    // print("Peer id $uid");

    return FutureBuilder(
        future:
            Firestore.instance.collection("userInfoList").document(uid).get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData) {
            return Text("$head [${snapshot.data.data['displayName']}]");
          } else {
            return Text("$head [Not found]");
          }
        });
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }
}
