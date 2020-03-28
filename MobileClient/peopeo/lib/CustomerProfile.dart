import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peopeo/EditCustomerProfile.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:peopeo/Plan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/FullPhoto.dart';
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

  CustomerProfileState({Key key, @required this.uid});

  List<Tab> tabList = List();
  TabController tabController;

  @override
  void initState() {
    tabList.add(Tab(icon: Icon(Icons.camera)));
    tabList.add(Tab(icon: Icon(Icons.video_library)));
    tabList.add(Tab(icon: Icon(Icons.comment)));
    tabController = new TabController(length: tabList.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  // ignore: missing_return
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
          )),
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
                                    ],
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
      floatingActionButton: FloatingActionButton(
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
      ),
    );
  }

  String getRating(document) {
    if (document['rating'] == null) {
      return "N/A";
    } else {
      return document['rating'].toString();
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
}