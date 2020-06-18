import 'dart:async';
import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:peopeo/ChattedUserViewer.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/ConsultantProfile.dart';
import 'package:peopeo/CustomerListViewer.dart';
import 'package:peopeo/CustomerProfile.dart';
import 'package:peopeo/ExpertSearch.dart';
import 'package:peopeo/LikedUserViewer.dart';
import 'package:peopeo/LoginPage.dart';
import 'package:peopeo/CalenderWebView.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/NotificationViewer.dart';
import 'package:peopeo/PlanInfo.dart';
import 'package:peopeo/UserInfo.dart';
import 'package:peopeo/utility/PlanManager.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share/share.dart';

void main() {
  runApp(Phoenix(child: MyApp()));
}

bool isUserLoggedIn = false;
var userInfo;

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Experts',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder(
          future: MySharedPreferences.getStringValue("userInfo"),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {

              isUserLoggedIn = true;
              userInfo = jsonDecode(snapshot.data);
              print("uid = ${userInfo['uid']}");
              print("photo url = ${userInfo['photoUrl']}");

              MySharedPreferences.getBooleanValue("isUploadRunning")
                  .then((isUploadRunning) {
                if (isUploadRunning == null) {
                  print("nothing is uploading!");
                } else if (isUploadRunning) {
                  Fluttertoast.showToast(
                      msg:
                          "Video/Image upload running, Please don't close the app!",
                      toastLength: Toast.LENGTH_LONG);
                }
              });
            } else {
              isUserLoggedIn = false;
            }
            return MyHomePage();
          },
        ));
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  final FirebaseMessaging fm = FirebaseMessaging();
  int i = 0;
  DateFormat df = new DateFormat('dd-MM-yyyy hh:mm:ss a');
  bool isInternetAvailable = true;
  StreamSubscription<ConnectivityResult> connectivitySubscription;
  StreamSubscription rsiSubscription;

  @override
  void initState() {
    super.initState();

    print("need to pop up notification = [yes] in main");
    MySharedPreferences.setBooleanValue("needToPopUpNoti", true);

    WidgetsBinding.instance.addObserver(this);
    fm.configure(onMessage: (Map<String, dynamic> message) async {
      if (i % 2 == 0) {
        print("onMessage: message = $message");
        MySharedPreferences.getBooleanValue("needToPopUpNoti").then((needToPopUpNoti){

          if(needToPopUpNoti){

            print("need to pop up notification = [yes] in main init state");
            showNotification(context, message);

          }else {
            print("need to pop up notification = [no] in main init state");
          }

        });
      }
      i++;
    });

    fm.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));

    ReceiveSharingIntent.getInitialText().then((String uid) {
      print("whan app not in memory => shared text $uid");
      if (uid != null) {

        if (isUserLoggedIn) {

          showAlertDialog(context,"Please wait...");

          var data = {
            'userType' : 2,
            'uid' : uid
          };

          PlanManager.getPlanList(data).then((reviewAndRatingList){

            Navigator.of(context, rootNavigator: true).pop('dialog');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {

                  return ConsultantProfile(uid: uid,reviewAndRatingList: reviewAndRatingList);

                },
              ),
            );

          });

        } else {
          goToLoginPage();
        }

      }
    });

    rsiSubscription = ReceiveSharingIntent.getTextStream().listen((String uid) {
      print("whan app in memory => shared text $uid");
      if (uid != null) {

        if (isUserLoggedIn) {

          showAlertDialog(context,"Please wait...");

          var data = {
            'userType' : 2,
            'uid' : uid
          };

          PlanManager.getPlanList(data).then((reviewAndRatingList){

            Navigator.of(context, rootNavigator: true).pop('dialog');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {

                  return ConsultantProfile(uid: uid,reviewAndRatingList: reviewAndRatingList);

                },
              ),
            );

          });

        }else {
          goToLoginPage();
        }

      }
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    updateOnlineStatus();
    Timer.periodic(Duration(minutes: 5), (timer) {
      updateOnlineStatus();
    });

    MySharedPreferences.setBooleanValue("isUploadRunning", false);

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

    // checkServer();

  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isInternetAvailable,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            leading: Padding(
              padding: EdgeInsets.all(10.0),
              child: getProfilePic(),
            ),
            title: Text(
              "Experts",
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[
              IconButton(
                icon: Badge(
                  badgeContent: getTotalUnSeenNotification(),
                  child: Icon(Icons.notifications, color: Colors.grey),
                ),
                onPressed: () async {
                  if (isUserLoggedIn) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return NotificationViewer(uid: userInfo['uid']);
                        },
                      ),
                    );
                  } else {
                    goToLoginPage();
                  }
                },
              )
            ]),
        body: StreamBuilder(
          stream: Firestore.instance
              .collection('userInfoList')
              .where('userType', isEqualTo: 2)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              );
            } else {
              return ListView.builder(
                itemBuilder: (context, index) =>
                    buildItem(context, snapshot.data.documents[index]),
                itemCount: snapshot.data.documents.length,
              );
            }
          },
        ),
        bottomNavigationBar: !isInternetAvailable
            ? Container(
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
              )
            : Container(
                color: Colors.white,
                height: 50.0,
                alignment: Alignment.center,
                child: new BottomAppBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            if (isUserLoggedIn) {
                              List<UserInfo> userInfoList = new List();
                              Firestore.instance
                                  .collection('userInfoList')
                                  .where('userType', isEqualTo: 2)
                                  .getDocuments()
                                  .then((docs) {
                                if (docs != null) {
                                  docs.documents.forEach((val) {
                                    userInfoList.add(UserInfo(
                                        uid: val.data['uid'],
                                        displayName: val.data['displayName'],
                                        email: val.data['email'],
                                        hashTag: val.data['hashTag']));
                                  });
                                  showSearch(
                                      context: context,
                                      delegate: ExpertSearch(userInfoList));
                                }
                              });
                            } else {
                              goToLoginPage();
                            }
                          }),
                      IconButton(
                          icon: Icon(Icons.favorite),
                          onPressed: () {
                            if (isUserLoggedIn) {
                              if (userInfo['userType'] == 1) {
                                showAlertDialog(context,
                                    "Gathering user that you liked...");

                                getLikedUserIdList(userInfo['uid'])
                                    .then((res) async {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return LikedUserViewer(
                                            uid: userInfo['uid'],
                                            likedUserIdList: res,
                                            userType: userInfo['userType']);
                                      },
                                    ),
                                  );
                                });
                              } else {
                                showAlertDialog(
                                    context, "Fetching customer list...");

                                getLikedCustomerList(userInfo['uid'])
                                    .then((res) {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return CustomerListViewer(
                                            uid: userInfo['uid'],
                                            customerList: res);
                                      },
                                    ),
                                  );
                                });
                              }
                            } else {
                              goToLoginPage();
                            }
                          }),
                      IconButton(
                          icon: Icon(Icons.history),
                          onPressed: () {
                            if (isUserLoggedIn) {
                              showAlertDialog(context,
                                  "Gathering user that you chatted before.");

                              getAllChattedUserInfo(userInfo['uid'])
                                  .then((chattedUserIdList) {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return ChattedUserViewer(
                                          uid: userInfo['uid'],
                                          chattedUserIdList: chattedUserIdList);
                                    },
                                  ),
                                );
                              });
                            } else {
                              goToLoginPage();
                            }
                          }),
                      IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            if (isUserLoggedIn) {
                              Connectivity()
                                  .checkConnectivity()
                                  .then((connectivityResult) {
                                if (connectivityResult ==
                                    ConnectivityResult.none) {
                                  Fluttertoast.showToast(
                                      msg: "No internet connection available.");
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return PlanInfo(
                                            uid: userInfo['uid'],
                                            userType: userInfo['userType']);
                                      },
                                    ),
                                  );
                                }
                              });
                            } else {
                              goToLoginPage();
                            }
                          }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void redirectCalender(DocumentSnapshot document, String tz, BuildContext context) async {

    if (userInfo['userType'] == 1) {
      int hr = document['hourlyRate'];
      int fm = 0;
      String conId = document['uid'];

      if (document['freeMinutesForNewCustomer'] != null) {
        fm = document['freeMinutesForNewCustomer'];
      }

      print("fm = $fm");

      if (hr == null) {
        Fluttertoast.showToast(msg: "This user didn't set hourly rate yet!");
      } else {

        String calenderUrl = webClientBaseUrl +
            "/calendar.html?conid=" +
            conId +
            "&cusid=" +
            userInfo['uid'] +
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
    } else {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
          msg:
              "Because of you are a expert, you can't see another expert calander!");
    }
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    String uid = (userInfo == null) ? "empty" : userInfo['uid'];
    if (document['uid'] == uid) {
      return Container();
    } else {
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
                          image: isInternetAvailable
                              ? CachedNetworkImageProvider(document['photoUrl'])
                              : AssetImage(
                                  "assets/images/demo_profile_pic.png")),
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
                                  icon: Icon(Icons.favorite),
                                  onPressed: () {
                                    if (isUserLoggedIn) {
                                      if (userInfo['userType'] == 1) {
                                        giveLike(document, userInfo['uid']);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg:
                                                "You can't like any expert, cause you are registered as expert!");
                                      }
                                    } else {
                                      goToLoginPage();
                                    }
                                  },
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
                        ),
                      )
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
                  ),
                  getCoronaExp(document),
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
                      if (isUserLoggedIn) {

                        showAlertDialog(context,"Please wait...");

                        var data = {
                          'userType' : 2,
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

                      } else {
                        goToLoginPage();
                      }
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
                      // first reload auth on server side
                      // then redirect to browser and open calender

                      if (isUserLoggedIn) {
                        if (document['hourlyRate'] == null) {
                          Fluttertoast.showToast(
                              msg:
                                  "This expert didn't set his hourly rate yet!");
                        } else {
                          bool isPortrait =
                              MediaQuery.of(context).orientation ==
                                  Orientation.portrait;

                          if (isPortrait) {
                            showAlertDialog(context, "Preparing calender ..");
                            Connectivity()
                                .checkConnectivity()
                                .then((connectivityResult) {
                              if (connectivityResult ==
                                  ConnectivityResult.none) {
                                Navigator.of(context).pop();
                                Fluttertoast.showToast(
                                    msg: "No internet connection available!");
                              } else {
                                getTimeZone().then((tz) {

                                  redirectCalender(document, tz,context);

                                }).catchError((er) {
                                  Navigator.of(context).pop();
                                  print("Time zone error $er");
                                  Fluttertoast.showToast(
                                      msg: "Can't fetch time zone!");
                                });
                              }
                            });
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    "Please change your app orientation to portrait!",
                                toastLength: Toast.LENGTH_LONG);
                          }
                        }
                      } else {
                        goToLoginPage();
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
  }

  getFreeMinutes(DocumentSnapshot document) {
    if (document['freeMinutesForNewCustomer'] == null) {
      return Text(
        "[No free minutes for new customer]",
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

  getHourlyRate(DocumentSnapshot document) {
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

  getDisplayName(DocumentSnapshot document) {
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

  getShortDescription(DocumentSnapshot document) {
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

  getLongDescription(DocumentSnapshot document) {
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

  getCoronaExp(DocumentSnapshot document) {
    if (document['coronavirusExperience'] == null) {
      return Text("Corona virus experience not set yet",
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    } else {
      return Text(
          "Corona virus experience [" +
              document['coronavirusExperience'].toString() +
              "]",
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontFamily: 'Armata',
          ));
    }
  }

  double getRating(document) {
    if (document['rating'] == null) {
      return double.tryParse("0.0");
    } else {
      return double.tryParse(document['rating'].toString());
    }
  }

  getTotalUnSeenNotification() {
    if (userInfo == null) {
      return Text("0",
          style: TextStyle(
              fontSize: 12.0,
              color: Colors.white,
              fontFamily: 'Armata',
              fontWeight: FontWeight.w600));
    } else {
      return StreamBuilder(
        stream: Firestore.instance
            .collection('notificationList')
            .where('uid', isEqualTo: userInfo['uid'])
            .where('seenStatus', isEqualTo: 0)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data.documents.length.toString(),
                style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.w600));
          } else {
            return Text("0",
                style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.w600));
          }
        },
      );
    }
  }

  void addToBookMark(expertUid, String myUid) {

    CollectionReference cr = Firestore.instance
        .collection('userInfoList')
        .document(myUid)
        .collection("bookMarkUserIdList");

    cr.document(expertUid).get().then((doc) {
      if (doc.exists) {
        cr.document(expertUid).delete();
      } else {
        cr.document(expertUid).setData({
          'expertUid': expertUid,
        });
      }
    });
  }

  void giveLike(DocumentSnapshot ds, String myUid) {
    CollectionReference cr = Firestore.instance
        .collection('userInfoList')
        .document(ds['uid'])
        .collection("likedUserIdList");

    cr.document(myUid).get().then((doc) {
      if (doc.exists) {
        cr.document(myUid).delete();
      } else {
        cr.document(myUid).setData({
          'uid': myUid,
        });
      }
    });
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

  void showNotification(BuildContext context, Map<String, dynamic> message) {

    Firestore.instance
        .collection('notificationList')
        .document(message['data']['docId'])
        .get().then((val){

      showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(message['notification']['title'],
                  style: TextStyle(
                      color: Colors.pink,
                      fontFamily: 'Armata',
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold)),
              content: Wrap(children: <Widget>[
                Visibility(
                  visible: val.data['type'] == 6 || val.data['type'] == 7,
                  child: Text(val.data['body'],
                      style: getTextStyle(Colors.black, FontWeight.normal,14.0)),
                ),
                Visibility(
                  visible: val.data['type'] == 1 ||
                      val.data['type'] == 2 ||
                      val.data['type'] == 3 ||
                      val.data['type'] == 4 ||
                      val.data['type'] == 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          val.data['topic'] == null
                              ? "empty"
                              : "Topic ${val.data['topic']}",
                          style: getTextStyle(Colors.black, FontWeight.bold,14.0)),
                      Text(
                          val.data['startTime'] == null
                              ? "empty"
                              : "Start at ${val.data['startTime']}",
                          style: getTextStyle(Colors.black, FontWeight.normal,11.0)),
                      Text(
                          val.data['endTime'] == null
                              ? "empty"
                              : "End at ${val.data['endTime']}",
                          style: getTextStyle(Colors.black, FontWeight.normal,11.0)),
                    ],
                  ),
                )
              ]),
              actions: <Widget>[
                FlatButton(
                    child: Text('Close',
                        style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'Armata',
                            fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(context).pop(false)),
                FlatButton(
                    child: Text('Details',
                        style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'Armata',
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return NotificationViewer(uid: userInfo['uid']);
                          },
                        ),
                      );
                    })
              ]);
        },
      );

    });

  }

  TextStyle getTextStyle(Color color, FontWeight fontWeight,double fs) {
    return TextStyle(
        color: color, fontFamily: 'Armata', fontWeight: fontWeight,fontSize: fs);
  }

  void goToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return LoginPage();
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getLikedUserIdList(String uid) async {
    print('getLikedUserIdList uid = $uid');

    List<Map<String, dynamic>> likedUserIdList = [];

    final uiDocs =
        await Firestore.instance.collection("userInfoList").getDocuments();

    await Future.wait(uiDocs.documents.map((ui) async {
      Map<String, dynamic> uiObj = ui.data;

      final luDocs = await Firestore.instance
          .collection('userInfoList')
          .document(uiObj['uid'])
          .collection('likedUserIdList')
          .where('uid', isEqualTo: uid)
          .getDocuments();

      await Future.wait(luDocs.documents.map((lu) async {
        print('lu id = ${uiObj['uid']}');
        likedUserIdList.add(uiObj);
      }));
    }));

    return likedUserIdList;
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

  Future<List<Map<String, dynamic>>> getAllChattedUserInfo(String uid) async {
    List<Map<String, dynamic>> chattedUserIdList = [];
    final mDocs =
        await Firestore.instance.collection("messages").getDocuments();

    await Future.wait(mDocs.documents.map((m) async {
      String peerId;

      String groupIdFirst = m.documentID.split("-").first;
      String groupIdLast = m.documentID.split("-").last;

      if (uid == groupIdFirst) {
        peerId = groupIdLast;
      } else if (uid == groupIdLast) {
        peerId = groupIdFirst;
      }

      print("peer id = $peerId");

      if (peerId != null) {
        final uiDoc = await Firestore.instance
            .collection('userInfoList')
            .document(peerId)
            .get();

        chattedUserIdList.add(uiDoc.data);
      }
    }));

    return chattedUserIdList;
  }

  Future<List<Map<String, dynamic>>> getLikedCustomerList(String uid) async {
    List<Map<String, dynamic>> customerList = [];

    final luDocs = await Firestore.instance
        .collection('userInfoList')
        .document(uid)
        .collection('likedUserIdList')
        .getDocuments();

    await Future.wait(luDocs.documents.map((lu) async {
      final uiDoc = await Firestore.instance
          .collection('userInfoList')
          .document(lu.data['uid'])
          .get();

      customerList.add(uiDoc.data);
    }));

    return customerList;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Life cycle state = $state");
  }

  getProfilePic() {
    if (isUserLoggedIn) {
      return FutureBuilder(
        future: MySharedPreferences.getStringValue("userInfo"),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {

            if (snapshot.hasData) {

              var ui = jsonDecode(snapshot.data);
              return Container(
                height: 10.0,
                width: 10.0,
                child: InkWell(
                  onTap: () {

                    showAlertDialog(context,"Please wait...");

                    var data = {
                      'userType' : ui['userType'],
                      'uid' : ui['uid']
                    };

                    PlanManager.getPlanList(data).then((reviewAndRatingList){

                      Navigator.of(context, rootNavigator: true).pop('dialog');
                      if (ui['userType'] == 1) {

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return CustomerProfile(uid: ui['uid'],reviewAndRatingList : reviewAndRatingList);
                            },
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return ConsultantProfile(uid: ui['uid'],reviewAndRatingList : reviewAndRatingList);
                            },
                          ),
                        );
                      }

                    });

                  },
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: isInternetAvailable
                          ? CachedNetworkImageProvider(ui['photoUrl'])
                          : AssetImage("assets/images/demo_profile_pic.png")),
                ),
              );

            }else {

              return Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              );

            }
          }
      );
    } else {
      return Container(
        height: 5.0,
        width: 5.0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return LoginPage();
                },
              ),
            );
          },
        ),
        decoration: new BoxDecoration(
          image: new DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage("assets/images/user_register.png")),
        ),
      );
    }
  }

  getOnlineStatus(DocumentSnapshot document) {
    if (document['isOnline'] == null) {
      return Icon(Icons.lens, color: Colors.green);
    } else if (document['isOnline']) {
      return Icon(Icons.lens, color: Colors.green);
    } else {
      return Icon(Icons.lens, color: Colors.grey);
    }
  }

  void updateOnlineStatus() {
    if (isUserLoggedIn) {
      getTimeZone().then((tz) {

        if(userInfo['userType'] == 2){

          print("user type = ${userInfo['userType']}");
          print("last online update , timezone = $tz");

          Firestore.instance
              .collection("userInfoList")
              .document(userInfo['uid'])
              .updateData({
            "lastOnlineAt": df.format(DateTime.now()),
            "timeZone": tz,
            "isOnline": true,
          });

        }

      });
    }
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    rsiSubscription.cancel();
    super.dispose();
  }

  Future<void> checkServer() async {

    String url = serverBaseUrl + '/app/test';
    Map<String, String> headers = {"Content-type": "application/json"};

    Response response = await get(url,headers: headers);

    print("server status = ${response.body}");

    if (response.statusCode == 200) {

      var body = json.decode(response.body);
      if (body['code'] == 200) {
        Fluttertoast.showToast(msg: "Server side application running.");
      }else {
        Fluttertoast.showToast(msg: "Server side application error.");
      }

    }else {

      Fluttertoast.showToast(msg: "Sever status code ${response.statusCode}");

    }


  }
}
