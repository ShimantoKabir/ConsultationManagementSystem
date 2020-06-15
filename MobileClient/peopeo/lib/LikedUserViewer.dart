import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:peopeo/CalenderWebView.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/utility/PlanManager.dart';
import 'package:share/share.dart';
import 'Const.dart';
import 'ConsultantProfile.dart';

class LikedUserViewer extends StatefulWidget {

  final List<Map<String, dynamic>> likedUserIdList;
  final String uid;
  final int userType;

  LikedUserViewer(
      {Key key,
      @required this.uid,
      @required this.likedUserIdList,
      @required this.userType})
      : super(key: key);

  @override
  LikedUserViewerState createState() => new LikedUserViewerState(
      uid: uid, likedUserIdList: likedUserIdList, userType: userType);
}

class LikedUserViewerState extends State<LikedUserViewer> {

  LikedUserViewerState(
      {Key key,
      @required this.uid,
      @required this.likedUserIdList,
      @required this.userType});

  List<Map<String, dynamic>> likedUserIdList;
  String uid;
  int userType;
  bool isInternetAvailable = true;
  StreamSubscription<ConnectivityResult> connectivitySubscription;

  @override
  void initState() {
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: !isInternetAvailable,
        child: Scaffold(
          appBar: new AppBar(
            iconTheme: IconThemeData(color: Colors.black),
            backgroundColor: Colors.white,
            title: new Text('Like',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Container(
            child: showLikedUser(),
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

  Widget buildItem(
      BuildContext context, Map<String, dynamic> document) {
    print("uid = ${document['uid']}");
    return Container(
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                getOnlineStatus(document),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.grey),
                  onPressed: () {
                    Share.share(
                        webClientBaseUrl +
                            "/profile.html?uid=" +
                            document['uid'],
                        subject: "Profile");
                  },
                ),
              ],
            ),
          ),
          Divider(
            height: 0.0,
            thickness: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: <Widget>[
                Container(
                  height: 100.0,
                  width: 100.0,
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    image: new DecorationImage(
                        fit: BoxFit.cover,
                        image: new NetworkImage(document['photoUrl'])),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.thumb_up),
                                onPressed: () {},
                              ),
                              StreamBuilder(
                                stream: Firestore.instance
                                    .collection('userInfoList')
                                    .document(document['uid'])
                                    .collection("likedUserIdList")
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    String like;

                                    if (snapshot.data.documents.length > 0) {
                                      if (snapshot.data.documents.length ==
                                          1) {
                                        like = "1 Like";
                                      } else {
                                        like = snapshot.data.documents.length
                                            .toString() +
                                            " Likes";
                                      }
                                    } else {
                                      like = "0 Like";
                                    }

                                    return Text(like,
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Armata',
                                        ));
                                  } else {
                                    return Text('0 Like',
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Armata',
                                        ));
                                  }
                                },
                              )
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.attach_money),
                                onPressed: () {},
                              ),
                              getHourlyRate(document)
                            ],
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: getFreeMinutes(document),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      "(" + getRating(document).toString() + ")",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Armata',
                      ),
                    ),
                    RatingBarIndicator(
                        rating: getRating(document),
                        direction: Axis.horizontal,
                        itemCount: 5,
                        itemSize: 25.0,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ))
                  ],
                ),
                getDisplayName(document),
                SizedBox(
                  height: 10.0,
                ),
                getShortDescription(document),
                SizedBox(
                  height: 10.0,
                ),
                getLongDescription(document),
                SizedBox(
                  height: 10.0,
                )
              ],
            ),
          ),
          Divider(
            height: 0.0,
            thickness: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                RaisedButton(
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.red)),
                  onPressed: () {

                    showAlertDialog(context,"Please wait...");

                    var data = {
                      'userType' : 1,
                      'uid' : document['uid']
                    };

                    PlanManager.getPlanList(data).then((reviewAndRatingList){

                      Navigator.of(context, rootNavigator: true).pop('dialog');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ConsultantProfile(uid: document['uid'],reviewAndRatingList: reviewAndRatingList);
                          },
                        ),
                      );

                    });

                  },
                  color: Colors.red,
                  textColor: Colors.white,
                  child: Text("Profile".toUpperCase(),
                      style: TextStyle(fontSize: 14)),
                ),
                RaisedButton(
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.red)),
                  onPressed: () async {
                    if (document['hourlyRate'] == null) {
                      Fluttertoast.showToast(
                          msg: "This expert didn't set his hourly rate yet.");
                    } else {
                      bool isPortrait = MediaQuery.of(context).orientation ==
                          Orientation.portrait;

                      if (isPortrait) {
                        showAlertDialog(context, "Preparing calender ..");
                        Connectivity()
                            .checkConnectivity()
                            .then((connectivityResult) {
                          if (connectivityResult == ConnectivityResult.none) {
                            Navigator.of(context).pop();
                            Fluttertoast.showToast(
                                msg: "No internat connection available.");
                          } else {
                            getTimeZone().then((tz) {

                              redirectCalender(context, document, tz);

                            }).catchError((er) {
                              Navigator.of(context).pop();
                              print("Time zone error $er.");
                              Fluttertoast.showToast(
                                  msg: "Can't fetch time zone.");
                            });
                          }
                        });
                      } else {
                        Fluttertoast.showToast(
                            msg:
                            "Please change your app orientation to portrait.",
                            toastLength: Toast.LENGTH_LONG);
                      }
                    }
                  },
                  color: Colors.red,
                  textColor: Colors.white,
                  child: Text("Calender".toUpperCase(),
                      style: TextStyle(fontSize: 14)),
                )
              ],
            ),
          ),
        ],
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

  getOnlineStatus(Map<String, dynamic> document) {
    if (document['isOnline'] == null) {
      return Icon(Icons.lens, color: Colors.green);
    } else if (document['isOnline']) {
      return Icon(Icons.lens, color: Colors.green);
    } else {
      return Icon(Icons.lens, color: Colors.grey);
    }
  }

  Future<String> getTimeZone() async {
    String timeZone;
    try {
      timeZone = await FlutterNativeTimezone.getLocalTimezone();
    } catch (e) {
      timeZone = null;
      print("Time zone fetching exp = $e");
    }
    print("Time zone = $timeZone");
    return timeZone;
  }

  void redirectCalender(
      BuildContext context, Map<String, dynamic> document, String tz) async {

    int hr = document['hourlyRate'];
    int fm = 0;
    String conId = document['uid'];

    if (document['freeMinutesForNewCustomer'] != null) {
      fm = document['freeMinutesForNewCustomer'];
    }

    if (hr == null) {
      Fluttertoast.showToast(msg: "This user didn't set hourly rate yet!");
    } else {

      String calenderUrl = webClientBaseUrl +
          "/calendar.html?conid=" +
          conId +
          "&cusid=" +
          uid +
          "&hourly-rate=" +
          hr.toString() +
          "&free-minutes=" +
          fm.toString() +
          "&time-zone=" +
          tz;

      print("calender url = $calenderUrl");

      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return MyFlutterWebView(
                title: "Calendar of " + document['displayName'],
                url: calenderUrl);
          },
        ),
      ).whenComplete((){

        print("need to pop up notification = [yes] in main calendre button");
        MySharedPreferences.setBooleanValue("needToPopUpNoti", true);

      });
    }
  }

  getHourlyRate(Map<String, dynamic> document) {
    if (document['hourlyRate'] == null) {
      return Text(
        "\$0/Hour",
        style: TextStyle(
            fontSize: 12.0, fontWeight: FontWeight.w600, fontFamily: 'Armata'),
      );
    } else {
      return Text(
        "\$" + document['hourlyRate'].toString() + "/Hour",
        style: TextStyle(
            fontSize: 12.0, fontWeight: FontWeight.w600, fontFamily: 'Armata'),
      );
    }
  }

  getFreeMinutes(Map<String, dynamic> document) {
    if (document['freeMinutesForNewCustomer'] == null) {
      return Text(
        "[No fres minutes for new customer]",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green, fontFamily: "Armata"),
      );
    } else {
      return Text(
        "[" +
            document['freeMinutesForNewCustomer'].toString() +
            " minutes free for new customer]",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green, fontFamily: "Armata"),
      );
    }
  }

  double getRating(Map<String, dynamic> document) {
    if (document['rating'] == null) {
      return double.tryParse("0.0");
    } else {
      return double.tryParse(document['rating'].toString());
    }
  }

  getDisplayName(Map<String, dynamic> document) {
    if (document['displayName'] == null) {
      return Text("Display name not set yet",
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    } else {
      return Text(document['displayName'].toString(),
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    }
  }

  getShortDescription(Map<String, dynamic> document) {
    if (document['shortDescription'] == null) {
      return Text("Short description not set yet",
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    } else {
      return Text(document['shortDescription'].toString(),
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    }
  }

  getLongDescription(Map<String, dynamic> document) {
    if (document['longDescription'] == null) {
      return Text("Long description not set yet",
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    } else {
      return Text(document['longDescription'].toString(),
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    }
  }

  showLikedUser() {

    if (likedUserIdList.length > 0) {
      return ListView.builder(
        itemBuilder: (context, index) =>
            buildItem(context, likedUserIdList[index]),
        itemCount: likedUserIdList.length,
      );
    } else {
      return Center(
        child: Text("[You didn't like any expert yet]",
            style: TextStyle(
                color: Colors.red,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold)),
      );
    }
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }

}
