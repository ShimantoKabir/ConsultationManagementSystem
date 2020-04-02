import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/EditConsultantProfile.dart';
import 'package:peopeo/FullPhoto.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:peopeo/HttpResponse.dart';
import 'package:peopeo/Plan.dart';
import 'package:peopeo/VideoPlayerScreen.dart';

class ConsultantProfile extends StatefulWidget {
  final String uid;

  ConsultantProfile({Key key, @required this.uid}) : super(key: key);

  @override
  ConsultantProfileState createState() => new ConsultantProfileState(uid: uid);
}

class ConsultantProfileState extends State<ConsultantProfile>
    with TickerProviderStateMixin {
  String uid;
  bool needToShowEditButton = false;

  ConsultantProfileState({Key key, @required this.uid});

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
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          title: Text('Profile',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          centerTitle: true),
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
                            Container(
                              height: 100.0,
                              width: 100.0,
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                image: new DecorationImage(
                                    fit: BoxFit.fill,
                                    image: new NetworkImage(snapshot
                                        .data.documents[0]['photoUrl'])),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  // likedUserIdList
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(Icons.thumb_up),
                                            onPressed: () {},
                                          ),
                                          Text(
                                              getTotalLike(
                                                  snapshot.data.documents[0]),
                                              style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontFamily: 'Armata',
                                                  fontWeight: FontWeight.w600))
                                        ],
                                      ),
                                      Column(
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(Icons.star),
                                            onPressed: () {},
                                          ),
                                          Text(
                                              getRating(
                                                  snapshot.data.documents[0]),
                                              style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontFamily: 'Armata',
                                                  fontWeight: FontWeight.w600))
                                        ],
                                      ),
                                      Column(
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(Icons.attach_money),
                                            onPressed: () {},
                                          ),
                                          Text(
                                              getHourlyRate(
                                                  snapshot.data.documents[0]),
                                              style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontFamily: 'Armata',
                                                  fontWeight: FontWeight.w600))
                                        ],
                                      )
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        2.0, 15.0, 2.0, 2.0),
                                    child: Text(
                                      getFreeMinutesForNewCustomer(
                                          snapshot.data.documents[0]),
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontFamily: "Armata"),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: RaisedButton(
                                      shape: new RoundedRectangleBorder(
                                          borderRadius:
                                              new BorderRadius.circular(8.0),
                                          side: BorderSide(color: Colors.red)),
                                      onPressed: () async {
                                        getTimeZone().then((tz) {
                                          reloadAuth(uid, tz);
                                        }).catchError((er) {
                                          print("Time zone error $er");
                                          Fluttertoast.showToast(
                                              msg: "Can't fetch time zone!");
                                        });
                                      },
                                      color: Colors.red,
                                      textColor: Colors.white,
                                      child: Text("Show Calender".toUpperCase(),
                                          style: TextStyle(fontSize: 14)),
                                    ),
                                  ),
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
                              getShortDescription(snapshot.data.documents[0]),
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
                              getLongDescription(snapshot.data.documents[0]),
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.grey,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
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
                              FutureBuilder(
                                future: Firestore.instance
                                    .collection('userInfoList')
                                    .document(uid)
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.hasData) {
                                    return showReviewAndRating(snapshot.data);
                                  } else {
                                    return Wrap(
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.all(15.0),
                                          child: Center(
                                            child: Text(
                                                "No review and rating available!"),
                                          ),
                                        )
                                      ],
                                    );
                                  }
                                },
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
              return Text('No user info found');
            }
          }),
      floatingActionButton: Visibility(
        visible: needToShowEditButton,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return EditConsultantProfile(uid: uid);
                },
              ),
            );
          },
          child: Icon(Icons.edit),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  getHourlyRate(document) {
    if (document['hourlyRate'] == null) {
      return "N/A";
    } else {
      return document['hourlyRate'].toString() + " \$/H";
    }
  }

  getFreeMinutesForNewCustomer(document) {
    if (document['freeMinutesForNewCustomer'] == null) {
      return "[N/A free minute's for new customer]";
    } else {
      return "[" +
          document['freeMinutesForNewCustomer'].toString() +
          " minute's free for new customer]";
    }
  }

  String getDisplayName(document) {
    if (document['displayName'] == null) {
      return "Not set yet";
    } else {
      return document['displayName'].toString();
    }
  }

  String getShortDescription(document) {
    if (document['shortDescription'] == null) {
      return "Short description set yet";
    } else {
      return document['shortDescription'].toString();
    }
  }

  String getLongDescription(document) {
    if (document['longDescription'] == null) {
      return "Long description set yet";
    } else {
      return document['longDescription'].toString();
    }
  }

  void reloadAuth(String uid, String tz) async {
    String reqUrl = serverBaseUrl + '/auth/reload';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {
      'auth': {'uId': uid}
    };
    Response response =
        await post(reqUrl, headers: headers, body: json.encode(request));
    if (response.statusCode == 200) {
      String aid = HttpResponse.fromJson(json.decode(response.body)).aid;
      print(aid);
      String calenderUrl = webClientBaseUrl +
          "/calendar.html?aid=" +
          aid +
          "&conid=" +
          uid +
          "&time-zone=" +
          tz;
      print(calenderUrl);

      if (await canLaunch(calenderUrl)) {
        await launch(calenderUrl);
      } else {
        throw 'Could not launch $calenderUrl';
      }
    } else {
      throw Exception('Failed to load browser');
    }
  }

  showPictureInGridView(String fileType) {
    String collectionName;
    String msgName;

    if (fileType == "vd") {
      collectionName = "videoThumbnailUrlList";
      msgName = "No video found!";
    } else {
      collectionName = "imageUrlList";
      msgName = "No image found!";
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
                  child: Text(msgName),
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
                    child: Text(msgName),
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
          decoration: new BoxDecoration(
            shape: BoxShape.rectangle,
            image: new DecorationImage(
                fit: BoxFit.fill, image: new NetworkImage(imgUrl)),
          ),
        ));
  }

  getTotalLike(document) {
    if (document['like'] == null) {
      return "N/A";
    } else {
      return document['like'].toString();
    }
  }

  String getRating(document) {
    if (document['rating'] == null) {
      return "N/A";
    } else {
      return document['rating'].toString();
    }
  }

  Future<List<Plan>> getPlanList(snapshot) async {
    String url = serverBaseUrl + '/plan/get-review-and-rating';
    Map<String, String> headers = {"Content-type": "application/json"};

    var request = {
      'plan': {'conUid': snapshot['uid'], 'userType': snapshot['userType']}
    };

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

  showReviewAndRating(DocumentSnapshot documentSnapshot) {
    return FutureBuilder<List<Plan>>(
      future: getPlanList(documentSnapshot),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemBuilder: (context, index) =>
                buildItem(context, snapshot.data[index], documentSnapshot),
            itemCount: snapshot.data.length,
          );
        } else {
          return Wrap(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Center(
                  child: Text("No review and rating found!"),
                ),
              )
            ],
          );
        }
      },
    );
  }

  buildItem(BuildContext context, document, DocumentSnapshot documentSnapshot) {
    return Card(
      child: ListTile(
          title: RatingBar(
            initialRating: double.tryParse(document.rating.toString()),
            direction: Axis.horizontal,
            itemCount: 5,
            itemSize: 25.0,
            itemBuilder: (context, index) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (double value) {},
          ),
          subtitle: Text("Review: " + document.review)),
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
}
