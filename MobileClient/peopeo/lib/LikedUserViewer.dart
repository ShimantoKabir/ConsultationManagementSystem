import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Const.dart';
import 'HttpResponse.dart';

class LikedUserViewer extends StatefulWidget {
  final List<Map<String, dynamic>> likedUserIdList;
  final String uid;

  LikedUserViewer({Key key, @required this.uid, @required this.likedUserIdList})
      : super(key: key);

  @override
  LikedUserViewerState createState() =>
      new LikedUserViewerState(uid: uid, likedUserIdList: likedUserIdList);
}

class LikedUserViewerState extends State<LikedUserViewer> {
  LikedUserViewerState(
      {Key key, @required this.uid, @required this.likedUserIdList});

  List<Map<String, dynamic>> likedUserIdList;
  String uid;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: new AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: new Text('Favorite',
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        child: ListView.builder(
          itemBuilder: (context, index) =>
              buildItem(context, likedUserIdList[index]),
          itemCount: likedUserIdList.length,
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, Map<String, dynamic> document) {
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
                                onPressed: () {},
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.star),
                                onPressed: () {},
                              ),
                              Text("91%",
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
                  onPressed: () {},
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
                    reloadAuth(document);
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

  getLike(Map<String, dynamic> document) {
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

  getFreeMinutes(Map<String, dynamic> document) {
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

  getHourlyRate(Map<String, dynamic> document) {
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

  getDisplayName(Map<String, dynamic> document) {
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

  getShortDescription(Map<String, dynamic> document) {
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

  getLongDescription(Map<String, dynamic> document) {
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

  void reloadAuth(Map<String, dynamic> document) async {
    int hr = document['hourlyRate'];
    int fm = 0;
    String conId = document['uid'];

    if (document['freeMinutesForNewCustomer'] != null) {
      fm = document['freeMinutesForNewCustomer'];
    }

    if (hr == null) {
      Fluttertoast.showToast(msg: "This user didn't set hourly rate yet!");
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

        String aid = HttpResponse.fromJson(json.decode(response.body)).aid;

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
            fm.toString();

        if (await canLaunch(calenderUrl)) {
          await launch(calenderUrl);
        } else {
          throw 'Could not launch $calenderUrl';
        }
      } else {
        throw Exception('Failed to load post');
      }
    }
  }
}
