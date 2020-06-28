import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:peopeo/CustomerProfile.dart';
import 'package:peopeo/utility/PlanManager.dart';

import 'MySharedPreferences.dart';

class CustomerListViewer extends StatefulWidget {
  final List<Map<String, dynamic>> customerList;
  final String uid;

  CustomerListViewer({Key key, @required this.uid, @required this.customerList})
      : super(key: key);

  @override
  CustomerListViewerState createState() =>
      new CustomerListViewerState(uid: uid, customerList: customerList);
}

class CustomerListViewerState extends State<CustomerListViewer> {
  CustomerListViewerState(
      {Key key, @required this.uid, @required this.customerList});

  List<Map<String, dynamic>> customerList;
  String uid;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
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
        child: showCustomerList(),
      ),
    );
  }

  Widget buildItem(
      BuildContext context, Map<String, dynamic> document, String uid) {
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
                children: <Widget>[
                  Container(
                    height: 100.0,
                    width: 100.0,
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                          fit: BoxFit.cover,
                          image: CachedNetworkImageProvider(document['photoUrl'])),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        // likedUserIdList
                        Text(
                          "Rating (" +
                              getRating(document)
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
                          rating: getRating(document),
                          direction: Axis.horizontal,
                          itemCount: 5,
                          itemSize: 25.0,
                          itemBuilder: (context, index) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          )
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
                              return CustomerProfile(uid: document['uid'],reviewAndRatingList: reviewAndRatingList);
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
                    onPressed: () {

                      sendMessage(document);

                    },
                    color: Colors.red,
                    textColor: Colors.white,
                    child: Text("Send Message".toUpperCase(),
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

  void sendMessage(Map<String, dynamic> document) {

    showAlertDialog(context,"Invitation sending....");

    MySharedPreferences.getStringValue("displayName").then((displayName) {

      print("display name = $displayName");

      Firestore.instance
          .collection('notificationList')
          .add({
        'body' : "My name is $displayName, If you would like a chat session with me, please schedule a time on my calendar.",
        'title' : "Invitation",
        'fcmRegistrationToken' : document['fcmRegistrationToken'],
        'uid' : document['uid'],
        'seenStatus' : 0,
        'invitationSenderUid' : uid,
        'timeStamp' : DateTime.now().millisecondsSinceEpoch,
        'type' : 6
      }).then((res){

        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(msg: "Invitation send successfully!");

      }).catchError((err){

        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(msg: "Something went wrong!");

      });

    });

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

  showCustomerList() {

    if(customerList.length>0){

      return ListView.builder(
        itemBuilder: (context, index) =>
            buildItem(context, customerList[index], uid),
        itemCount: customerList.length,
      );

    }else {

      return Center(
        child: Text("[No customer like you yet]",
            style: TextStyle(
                color: Colors.red,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold)),
      );

    }

  }

}
