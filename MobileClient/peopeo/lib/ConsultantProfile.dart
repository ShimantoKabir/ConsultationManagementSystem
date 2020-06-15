import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/EditProfile.dart';
import 'package:peopeo/FullPhoto.dart';
import 'package:peopeo/LoginPage.dart';
import 'package:peopeo/CalenderWebView.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/Plan.dart';
import 'package:peopeo/SocialSignIn.dart';
import 'package:peopeo/VideoPlayerScreen.dart';

class ConsultantProfile extends StatefulWidget {
  final String uid;
  final List<Plan> reviewAndRatingList;

  ConsultantProfile({Key key, @required this.uid,this.reviewAndRatingList}) : super(key: key);

  @override
  ConsultantProfileState createState() => new ConsultantProfileState(uid: uid,reviewAndRatingList : reviewAndRatingList);
}

class ConsultantProfileState extends State<ConsultantProfile>
    with TickerProviderStateMixin {

  String uid;
  List<Plan> reviewAndRatingList;
  bool needToShowEditButton = false;
  bool isInternetAvailable = true;
  int totalPlanFetched = 0;
  StreamSubscription<ConnectivityResult> connectivitySubscription;

  ConsultantProfileState({Key key, @required this.uid, @required this.reviewAndRatingList});

  List<Tab> tabList = List();
  TabController tabController;

  @override
  void initState() {

    tabList.add(Tab(icon: Icon(Icons.camera)));
    tabList.add(Tab(icon: Icon(Icons.video_library)));
    tabList.add(Tab(icon: Icon(Icons.comment)));
    tabController = new TabController(length: tabList.length, vsync: this);

    MySharedPreferences.getStringValue("uid").then((myUid) {
      if (myUid == uid) {
        setState(() {
          needToShowEditButton = true;
        });
      } else {
        setState(() {
          needToShowEditButton = false;
        });
      }
    });

    super.initState();

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

    print("review and rating list = $reviewAndRatingList");

  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: !isInternetAvailable,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.black),
              backgroundColor: Colors.white,
              title: Text('Profile',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: <Widget>[
                Visibility(
                  visible: needToShowEditButton,
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                      child: Center(
                          child: InkWell(
                              onTap: () async {
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
                                    content: new Text('Do you want to logout?',
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
                                          onPressed: () =>
                                              Navigator.of(context).pop(false)),
                                      FlatButton(
                                          child: Text('Yes',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontFamily: 'Armata',
                                                  fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            logOut().then((isDataCleared) {
                                              if (isDataCleared) {
                                                Navigator.of(context)
                                                    .pop(false);
                                                redirectLoginPage();
                                              }
                                            });
                                          })
                                    ],
                                  ),
                                );
                              },
                              child: FaIcon(FontAwesomeIcons.signOutAlt)))),
                )
              ]),
          body: StreamBuilder(
              stream: Firestore.instance
                  .collection('userInfoList')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Divider(
                            height: 0.0,
                            thickness: 1.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: <Widget>[
                                InkWell(
                                  child: Container(
                                    height: 100.0,
                                    width: 100.0,
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: new DecorationImage(
                                          fit: BoxFit.cover,
                                          image: CachedNetworkImageProvider(snapshot
                                              .data.documents[0]['photoUrl'])),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return FullPhoto(
                                              url: snapshot.data.documents[0]
                                                  ['photoUrl']);
                                        },
                                      ),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: <Widget>[
                                          Column(
                                            children: <Widget>[
                                              IconButton(
                                                icon: Icon(Icons.favorite),
                                                onPressed: () {},
                                              ),
                                              StreamBuilder(
                                                stream: Firestore.instance
                                                    .collection('userInfoList')
                                                    .document(uid)
                                                    .collection(
                                                        "likedUserIdList")
                                                    .snapshots(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    String like;

                                                    if (snapshot.data.documents
                                                            .length >
                                                        0) {
                                                      if (snapshot
                                                              .data
                                                              .documents
                                                              .length ==
                                                          1) {
                                                        like = "1 Like";
                                                      } else {
                                                        like = snapshot
                                                                .data
                                                                .documents
                                                                .length
                                                                .toString() +
                                                            " Likes";
                                                      }
                                                    } else {
                                                      like = "0 Like";
                                                    }

                                                    return Text(like,
                                                        style: TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: 'Armata',
                                                        ));
                                                  } else {
                                                    return Text('0 Like',
                                                        style: TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                              Text(
                                                  getHourlyRate(snapshot
                                                      .data.documents[0]),
                                                  style: TextStyle(
                                                      fontSize: 12.0,
                                                      fontFamily: 'Armata',
                                                      fontWeight:
                                                          FontWeight.w600))
                                            ],
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            2.0, 15.0, 2.0, 2.0),
                                        child: Center(
                                          child: Text(
                                            getFreeMinutesForNewCustomer(
                                                snapshot.data.documents[0]),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontFamily: "Armata"),
                                          ),
                                        ),
                                      ),
                                      Visibility(
                                        visible: needToShowEditButton,
                                        child: Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: RaisedButton(
                                            shape: new RoundedRectangleBorder(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        8.0),
                                                side: BorderSide(
                                                    color: Colors.red)),
                                            onPressed: () async {
                                              bool isPortrait =
                                                  MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.portrait;
                                              print(
                                                  "is portrait = $isPortrait");

                                              if (isPortrait) {
                                                MySharedPreferences
                                                        .getStringValue(
                                                            "userInfo")
                                                    .then((ui) async {
                                                  var userInfo = jsonDecode(ui);

                                                  print(
                                                      "sp uid = ${userInfo['uid']}, uid $uid, user type ${userInfo['userType']}");

                                                  showAlertDialog(context,
                                                      "Preparing calender ..");

                                                  Connectivity()
                                                      .checkConnectivity()
                                                      .then(
                                                          (connectivityResult) {
                                                    if (connectivityResult ==
                                                        ConnectivityResult
                                                            .none) {
                                                      Navigator.of(context)
                                                          .pop();
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              "No internet connection available.");
                                                    } else {
                                                      getTimeZone().then((tz) {

                                                        redirectCalender(context, tz,
                                                            userInfo);

                                                      }).catchError((er) {
                                                        Navigator.of(context)
                                                            .pop();
                                                        print(
                                                            "Time zone error $er");
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                "Can't fetch time zone!");
                                                      });
                                                    }
                                                  });
                                                });
                                              } else {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Please change your app orientation to portrait!",
                                                    toastLength:
                                                        Toast.LENGTH_LONG);
                                              }
                                            },
                                            color: Colors.red,
                                            textColor: Colors.white,
                                            child: Text(
                                                "Show Calender".toUpperCase(),
                                                style: TextStyle(fontSize: 14)),
                                          ),
                                        ),
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
                                      "(" +
                                          getRating(snapshot.data.documents[0])
                                              .toString() +
                                          ")",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Armata',
                                      ),
                                    ),
                                    RatingBarIndicator(
                                        rating: getRating(
                                            snapshot.data.documents[0]),
                                        direction: Axis.horizontal,
                                        itemCount: 5,
                                        itemSize: 25.0,
                                        itemBuilder: (context, index) => Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ))
                                  ],
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Text(
                                  getDisplayName(snapshot.data.documents[0]),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Armata',
                                  ),
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Text(
                                  getShortDescription(
                                      snapshot.data.documents[0]),
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Armata',
                                  ),
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Text(
                                  getLongDescription(
                                      snapshot.data.documents[0]),
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Armata',
                                  ),
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Text(
                                  getCoronaExp(snapshot.data.documents[0]),
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Armata',
                                  ),
                                ),
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
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 0.0),
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: new TabBar(
                                controller: tabController,
                                labelColor: Colors.black,
                                indicatorColor: Colors.blue,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: tabList,
                              ),
                            ),
                            Container(
                              height: MediaQuery.of(context).size.height,
                              child: TabBarView(
                                controller: tabController,
                                children: <Widget>[
                                  showPictureInGridView('im'),
                                  showPictureInGridView('vd'),
                                  isInternetAvailable
                                      ? showReviewAndRating(context)
                                      : Wrap(
                                          children: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.all(15.0),
                                              child: Center(
                                                child: Text(
                                                    "[No internet connection available]",
                                                    style: TextStyle(
                                                      fontSize: 15.0,
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Armata',
                                                    )),
                                              ),
                                            )
                                          ],
                                        )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  );
                }
              }),
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
          floatingActionButton: Visibility(
            visible: needToShowEditButton,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return EditProfile(uid: uid, userType: 2);
                    },
                  ),
                );
              },
              child: Icon(Icons.edit),
              backgroundColor: Colors.red,
            ),
          ),
        ));
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

  getHourlyRate(document) {
    if (document['hourlyRate'] == null) {
      return "\$0/Hour";
    } else {
      return "\$" + document['hourlyRate'].toString() + "/Hour";
    }
  }

  getFreeMinutesForNewCustomer(document) {
    if (document['freeMinutesForNewCustomer'] == null) {
      return "[No free minutes for new customer]";
    } else {
      return "[" +
          document['freeMinutesForNewCustomer'].toString() +
          " minutes free for new customer]";
    }
  }

  String getDisplayName(document) {
    if (document['displayName'] == null) {
      return "Display name not set yet";
    } else {
      return document['displayName'].toString();
    }
  }

  String getShortDescription(document) {
    if (document['shortDescription'] == null) {
      return "Short description not set yet";
    } else {
      return document['shortDescription'].toString();
    }
  }

  String getLongDescription(document) {
    if (document['longDescription'] == null) {
      return "Long description not set yet";
    } else {
      return document['longDescription'].toString();
    }
  }

  void redirectCalender(BuildContext context, String tz, var ui) async {

    String calenderUrl = webClientBaseUrl +
        "/calendar.html?conid=" +
        uid +
        "&time-zone=" +
        tz;

    print("calender url = $calenderUrl");
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return MyFlutterWebView(
              title: "Calendar of " + ui['displayName'],
              url: calenderUrl);
        },
      ),
    ).whenComplete((){

      print("need to pop up notification = [yes] in oonsultant profile");
      MySharedPreferences.setBooleanValue("needToPopUpNoti", true);

    });

  }

  showPictureInGridView(String fileType) {
    String collectionName;
    String msgName;

    if (fileType == "vd") {
      collectionName = "videoThumbnailUrlList";
      msgName = "[No video found]";
    } else {
      collectionName = "imageUrlList";
      msgName = "[No image found]";
    }

    return StreamBuilder(
      stream: Firestore.instance
          .collection('userInfoList')
          .document(uid)
          .collection(collectionName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Wrap(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              )
            ],
          );
        } else {
          if (snapshot.data.documents.length == 0) {
            return Wrap(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Center(
                    child: Text(msgName,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Armata',
                        )),
                  ),
                )
              ],
            );
          } else {
            return GridView.builder(
                physics: ScrollPhysics(),
                itemCount: snapshot.data.documents.length,
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemBuilder: (context, index) => buildImageItem(
                    context, snapshot.data.documents[index], fileType));
          }
        }
      },
    );
  }

  Widget buildImageItem(BuildContext context, document, String fileType) {
    String imgUrl;
    String videoUrl;

    if (fileType == "vd") {
      videoUrl = document['videoUrl'];
      imgUrl = document['thmUrl'];
    } else {
      imgUrl = document['imageUrl'];
    }

    return InkWell(
        onTap: () {
          if (fileType == "vd") {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return VideoPlayerScreen(url: videoUrl);
                },
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return FullPhoto(url: imgUrl);
                },
              ),
            );
          }
        },
        child: Container(
          child: Center(child: Icon(Icons.touch_app, color: Colors.white)),
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: (imgUrl == null)
                      ? AssetImage("assets/images/vid_tmp_img.jpg")
                      : CachedNetworkImageProvider(imgUrl),
                  fit: BoxFit.cover)),
        ));
  }

  getTotalLike(document) {
    if (document['like'] == null) {
      return "0 Like";
    } else {
      return document['like'].toString() + " Likes";
    }
  }

  double getRating(document) {
    if (document['rating'] == null) {
      return double.tryParse("0.0");
    } else {
      return double.tryParse(document['rating'].toString());
    }
  }

  showReviewAndRating(BuildContext context) {

    print("review and rating length = ${reviewAndRatingList.length}");

    if(reviewAndRatingList.length == 0){

      return Wrap(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(15.0),
            child: Center(
              child: Text(
                  "[No review and rating found]",
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.red,
                    fontWeight:
                    FontWeight.bold,
                    fontFamily: 'Armata',
                  )),
            ),
          )
        ],
      );

    }else {
      return ListView.builder(
        itemBuilder: (context, index) =>
            buildItem(context, reviewAndRatingList[index]),
        itemCount: reviewAndRatingList.length,
      );
    }
  }

  buildItem(BuildContext context, document) {
    return Card(
      child: ListTile(
          title: RatingBarIndicator(
              rating: double.tryParse(document.rating.toString()),
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 25.0,
              itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  )),
          subtitle: Text(document.review,
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Armata',
              ))),
    );
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

  String getCoronaExp(document) {
    if (document['coronavirusExperience'] == null) {
      return "Corona virus experience not set yet";
    } else {
      return "Corona virus experience [" +
          document['coronavirusExperience'].toString() +
          "]";
    }
  }

  void redirectLoginPage() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    tabController.dispose();
    super.dispose();
  }

}
