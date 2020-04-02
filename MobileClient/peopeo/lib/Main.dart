import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:peopeo/BookmarkViewer.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/LikedUserViewer.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/NotificationViewer.dart';
import 'package:peopeo/PlanInfo.dart';
import 'package:peopeo/UserInfo.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:peopeo/ConsultantProfile.dart';
import 'package:peopeo/CustomerProfile.dart';
import 'package:peopeo/ExpertSearch.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:peopeo/LoginPage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Experts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final FirebaseMessaging fm = FirebaseMessaging();
  bool isUserLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.all(10.0),
            child: FutureBuilder(
              future: MySharedPreferences.getStringValue("photoUrl"),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  isUserLoggedIn = true;
                  return Container(
                    height: 10.0,
                    width: 10.0,
                    child: InkWell(
                      onTap: () {
                        MySharedPreferences.getIntegerValue('userType')
                            .then((ut) {
                          MySharedPreferences.getStringValue('uid').then((uid) {
                            if (ut == 1) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return CustomerProfile(uid: uid);
                                  },
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return ConsultantProfile(uid: uid);
                                  },
                                ),
                              );
                            }
                          });
                        });
                      },
                    ),
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                          fit: BoxFit.fill,
                          image: new NetworkImage(snapshot.data)),
                    ),
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
                          image: new AssetImage(
                              "assets/images/user_register.png")),
                    ),
                  );
                }
              },
            ),
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
                badgeContent: FutureBuilder(
                    future: MySharedPreferences.getStringValue("uid"),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasData) {
                        return getTotalUnSeenNotification(snapshot.data);
                      } else {
                        return Text("0",
                            style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.white,
                                fontFamily: 'Armata',
                                fontWeight: FontWeight.w600));
                      }
                    }),
                child: Icon(Icons.notifications, color: Colors.grey),
              ),
              onPressed: () {
                if (isUserLoggedIn) {
                  MySharedPreferences.getStringValue("uid").then((val) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return NotificationViewer(uid: val);
                        },
                      ),
                    );
                  });
                } else {
                  goToLoginPage();
                }
              },
            )
          ]),
      body: FutureBuilder(
        future: MySharedPreferences.getStringValue("uid"),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          String uid;
          if (snapshot.hasData) {
            uid = snapshot.data;
          }
          return Container(
            child: StreamBuilder(
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
                        buildItem(context, snapshot.data.documents[index], uid),
                    itemCount: snapshot.data.documents.length,
                  );
                }
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
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
                                email: val.data['email']));
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
                      List<Map<String, dynamic>> likedUserIdList = [];

                      MySharedPreferences.getStringValue("uid").then((uid) {
                        Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection("likedUserIdList")
                            .getDocuments()
                            .then((docs) {
                          docs.documents.forEach((f) {
                            print(f.data);
                            Map<String, dynamic> likeObj = f.data;

                            Firestore.instance
                                .collection('userInfoList')
                                .document(likeObj['expertUid'])
                                .get()
                                .then((u) {
                              likedUserIdList.add(u.data);

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return LikedUserViewer(
                                        uid: uid,
                                        likedUserIdList: likedUserIdList);
                                  },
                                ),
                              );
                            });
                          });
                        });
                      });
                    } else {
                      goToLoginPage();
                    }
                  }),
              IconButton(
                  icon: Icon(Icons.bookmark),
                  onPressed: () {
                    if (isUserLoggedIn) {
                      List<Map<String, dynamic>> bookMarkUserIdList = [];
                      MySharedPreferences.getStringValue("uid").then((uid) {
                        Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection("bookMarkUserIdList")
                            .getDocuments()
                            .then((docs) {
                          docs.documents.forEach((f) {
                            print(f.data);
                            Map<String, dynamic> likeObj = f.data;

                            Firestore.instance
                                .collection('userInfoList')
                                .document(likeObj['expertUid'])
                                .get()
                                .then((u) {
                              bookMarkUserIdList.add(u.data);

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return BookmarkViewer(
                                        uid: uid,
                                        bookMarkUserIdList: bookMarkUserIdList);
                                  },
                                ),
                              );
                            });
                          });
                        });
                      });
                    } else {
                      goToLoginPage();
                    }
                  }),
              IconButton(
                  icon: Icon(Icons.schedule),
                  onPressed: () {
                    if (isUserLoggedIn) {
                      MySharedPreferences.getIntegerValue("userType")
                          .then((ut) {
                        MySharedPreferences.getStringValue("uid")
                            .then((uid) async {
                          print("User id : $uid");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return PlanInfo(uid: uid, userType: ut);
                              },
                            ),
                          );
                        });
                      });
                    } else {
                      goToLoginPage();
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void reloadAuth(DocumentSnapshot document, String tz) async {
    MySharedPreferences.getIntegerValue("userType").then((ut) {
      MySharedPreferences.getStringValue("uid").then((uid) async {
        if (ut == 1) {
          int hr = document['hourlyRate'];
          int fm = 0;
          String conId = document['uid'];

          if (document['freeMinutesForNewCustomer'] != null) {
            fm = document['freeMinutesForNewCustomer'];
          }

          if (hr == null) {
            Fluttertoast.showToast(
                msg: "This user didn't set hourly rate yet!");
          } else {
            String url = serverBaseUrl + '/auth/reload';
            Map<String, String> headers = {"Content-type": "application/json"};
            var request = {
              'auth': {'uId': uid}
            };

            Response response =
            await post(url, headers: headers, body: json.encode(request));

            if (response.statusCode == 200) {
              print(response.body.toString());

              String aid =
                  HttpResponse
                      .fromJson(json.decode(response.body))
                      .aid;

              String calenderUrl = webClientBaseUrl +
                  "/calendar.html?aid=" +
                  aid +
                  "&conid=" +
                  conId +
                  "&cusid=" +
                  uid +
                  "&hourly-rate=" +
                  hr.toString() +
                  "&free-minutes=" +
                  fm.toString() +
                  "&time-zone=" +
                  tz;

              print(calenderUrl);

              if (await canLaunch(calenderUrl)) {
                await launch(calenderUrl);
              } else {
                throw 'Could not launch $calenderUrl';
              }
            } else {
              throw Exception('Failed to load post');
            }
          }
        } else {
          Fluttertoast.showToast(
              msg:
              "Because of you are a consultant you can't see another consultant calander!");
        }
      });
    });
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document,
      String uid) {
    if (document['uid'] == uid) {
      return Container();
    } else {
      return Container(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme
                    .of(context)
                    .dividerColor))),
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
                  IconButton(
                    icon: StreamBuilder(
                        stream: Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection("likedUserIdList")
                            .where('expertUid', isEqualTo: document['uid'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data.documents.length == 1) {
                              return Icon(Icons.favorite, color: Colors.red);
                            } else {
                              return Icon(Icons.favorite, color: Colors.grey);
                            }
                          } else {
                            return Icon(Icons.favorite, color: Colors.white10);
                          }
                        }),
                    onPressed: () {
                      if (isUserLoggedIn) {
                        addToFavorite(document['uid'], uid);
                      } else {
                        goToLoginPage();
                      }
                    },
                  ),
                  IconButton(
                    icon: StreamBuilder(
                        stream: Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection("bookMarkUserIdList")
                            .where('expertUid', isEqualTo: document['uid'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data.documents.length == 1) {
                              return Icon(Icons.bookmark, color: Colors.red);
                            } else {
                              return Icon(Icons.bookmark, color: Colors.grey);
                            }
                          } else {
                            return Icon(Icons.bookmark, color: Colors.white10);
                          }
                        }),
                    onPressed: () {
                      if (isUserLoggedIn) {
                        addToBookMark(document['uid'], uid);
                      } else {
                        goToLoginPage();
                      }
                    },
                  )
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
                          fit: BoxFit.fill,
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
                                  onPressed: () {
                                    if (isUserLoggedIn) {
                                      giveThumbUp(document['uid']);
                                    } else {
                                      goToLoginPage();
                                    }
                                  },
                                ),
                                getLike(document)
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.star),
                                  onPressed: () {},
                                ),
                                getRating(document)
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
                      if (isUserLoggedIn) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return ConsultantProfile(uid: document['uid']);
                            },
                          ),
                        );
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
                    onPressed: () {
                      // first reload auth on server side
                      // then redirect to browser and open calender
                      if (isUserLoggedIn) {
                        getTimeZone().then((tz) {
                          reloadAuth(document, tz);
                        }).catchError((er) {
                          print("Time zone error $er");
                          Fluttertoast.showToast(msg: "Can't fetch time zone!");
                        });
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

  getLike(DocumentSnapshot document) {
    if (document['like'] == null) {
      return Text('0',
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Armata',
          ));
    } else {
      return Text(document['like'].toString(),
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Armata',
          ));
    }
  }

  getFreeMinutes(DocumentSnapshot document) {
    if (document['freeMinutesForNewCustomer'] == null) {
      return Text(
        "[No fres minute's for new customer]",
        style: TextStyle(color: Colors.green, fontFamily: "Armata"),
      );
    } else {
      return Text(
        "[" +
            document['freeMinutesForNewCustomer'].toString() +
            " minute's free for new customer]",
        style: TextStyle(color: Colors.green, fontFamily: "Armata"),
      );
    }
  }

  getHourlyRate(DocumentSnapshot document) {
    if (document['hourlyRate'] == null) {
      return Text(
        "N/A",
        style: TextStyle(
            fontSize: 12.0, fontWeight: FontWeight.w600, fontFamily: 'Armata'),
      );
    } else {
      return Text(
        document['hourlyRate'].toString() + " \$/H",
        style: TextStyle(
            fontSize: 12.0, fontWeight: FontWeight.w600, fontFamily: 'Armata'),
      );
    }
  }

  getDisplayName(DocumentSnapshot document) {
    if (document['displayName'] == null) {
      return Text("N/A",
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
      return Text("N/A",
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
      return Text("N/A",
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

  getRating(DocumentSnapshot document) {
    if (document['rating'] == null) {
      return Text("N/A",
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Armata',
          ));
    } else {
      return Text(document['rating'].toString(),
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Armata',
          ));
    }
  }

  getTotalUnSeenNotification(String uid) {
    return FutureBuilder(
      future: Firestore.instance
          .collection('notificationList')
          .where('uid', isEqualTo: uid)
          .where('seenStatus', isEqualTo: 0)
          .getDocuments(),
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

  void addToFavorite(expertUid, myUid) {
    CollectionReference cr = Firestore.instance
        .collection('userInfoList')
        .document(myUid)
        .collection("likedUserIdList");
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

  void giveThumbUp(document) {
    Firestore.instance
        .collection('userInfoList')
        .document(document)
        .updateData(<String, dynamic>{
      'like': FieldValue.increment(1),
    });
  }

  @override
  void initState() {
    super.initState();

    fm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage: message = $message");

      showNotification(context, message);
    });
    fm.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
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
    showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(message['notification']['title'],
                style: TextStyle(
                    color: Colors.pink,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            content: Wrap(children: <Widget>[
              Text(
                message['notification']['body'],
                style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.normal),
              )
            ]));
      },
    );
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

}
