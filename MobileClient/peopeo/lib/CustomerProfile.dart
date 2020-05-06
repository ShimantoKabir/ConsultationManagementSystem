import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peopeo/EditCustomerProfile.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:peopeo/LoginPage.dart';
import 'package:peopeo/Main.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/Plan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/FullPhoto.dart';
import 'package:peopeo/SocialSignIn.dart';
import 'package:peopeo/VideoPlayerScreen.dart';

class CustomerProfile extends StatefulWidget {
  final String uid;

  CustomerProfile({Key key, @required this.uid}) : super(key: key);

  @override
  CustomerProfileState createState() => new CustomerProfileState(uid: uid);
}

class CustomerProfileState extends State<CustomerProfile>
    with TickerProviderStateMixin {
  String uid;
  bool needToShowEditButton = false;

  CustomerProfileState({Key key, @required this.uid});

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

  void redirectLoginPage() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            "Profile",
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            Padding(
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
                                          Navigator.of(context).pop(false);
                                          redirectLoginPage();
                                        }
                                      });
                                    })
                              ],
                            ),
                          );
                        },
                        child: FaIcon(FontAwesomeIcons.signOutAlt))))
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
                                  Text(
                                    "Rating (" +
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
                                      rating:
                                          getRating(snapshot.data.documents[0]),
                                      direction: Axis.horizontal,
                                      itemCount: 5,
                                      itemSize: 25.0,
                                      itemBuilder: (context, index) => Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ))
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
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              );
            }
          }),
      floatingActionButton: Visibility(
          visible: needToShowEditButton,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return EditCustomerProfile(uid: uid);
                  },
                ),
              );
            },
            child: Icon(Icons.edit),
            backgroundColor: Colors.redAccent,
          )),
    );
  }

  double getRating(document) {
    if (document['rating'] == null) {
      return double.tryParse("0.0");
    } else {
      return double.tryParse(document['rating'].toString());
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
          child: Center(child: Icon(Icons.touch_app, color: Colors.white)),
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: (imgUrl == null)
                      ? AssetImage("assets/images/vid_tmp_img.jpg")
                      : NetworkImage(imgUrl),
                  fit: BoxFit.cover)),
        ));
  }

  Future<List<Plan>> getPlanList(snapshot) async {
    String url = serverBaseUrl + '/plan/get-review-and-rating';
    Map<String, String> headers = {"Content-type": "application/json"};

    var request = {
      'plan': {'cusUid': snapshot['uid'], 'userType': snapshot['userType']}
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
                  child: Text("No review and rating available!"),
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
          title: RatingBarIndicator(
              rating: double.tryParse(document.rating.toString()),
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 25.0,
              itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  )),
          subtitle: Text("Review: " + document.review)),
    );
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
}
