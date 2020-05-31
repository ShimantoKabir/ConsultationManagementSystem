import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:peopeo/ConsultantProfile.dart';

class NotificationViewer extends StatefulWidget {
  final String uid;

  NotificationViewer({Key key, @required this.uid}) : super(key: key);

  @override
  NotificationViewerState createState() =>
      new NotificationViewerState(uid: uid);
}

class NotificationViewerState extends State<NotificationViewer> {
  NotificationViewerState({Key key, @required this.uid});

  String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          title: new Text('Notifications',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: StreamBuilder(
            stream: Firestore.instance
                .collection('notificationList')
                .where('uid', isEqualTo: uid)
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                List<Map<String, dynamic>> nList = [];

                snapshot.data.documents.forEach((f) {
                  nList.add({
                    'title': f['title'],
                    'fcmRegistrationToken': f['fcmRegistrationToken'],
                    'uid': f['uid'],
                    'body': f['body'],
                    'invitationSenderUid': f['invitationSenderUid'],
                    'seenStatus': f['seenStatus'],
                    'timeStamp': f['timeStamp'],
                    'startTime': f['startTime'],
                    'endTime': f['endTime'],
                    'topic': f['topic'],
                    'type': f['type'],
                    'docId': f.documentID
                  });
                });

                Comparator<Map<String, dynamic>> x =
                    (b, a) => a['timeStamp'].compareTo(b['timeStamp']);

                nList.sort(x);

                nList.forEach((f) {
                  print("timeStamp = ${f['timeStamp']}, title = ${f['title']}");
                });

                if (nList.length > 0) {
                  return ListView.builder(
                    itemBuilder: (context, index) =>
                        buildItem(context, nList[index]),
                    itemCount: nList.length,
                  );
                } else {
                  return Center(
                    child: Text("[No message found]",
                        style: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Armata',
                            fontWeight: FontWeight.bold)),
                  );
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                );
              }
            }));
  }

  buildItem(BuildContext context, document) {
    return Card(
      color: document['seenStatus'] == 1 ? Colors.white : Colors.white30,
      child: ListTile(
        leading: document['seenStatus'] == 1
            ? Icon(Icons.notifications, size: 40.0)
            : Icon(Icons.notifications_none, size: 40.0),
        title: Text(document['title'],
            style: getTextStyle(Colors.red, FontWeight.bold)),
        subtitle: Wrap(
          // 1 = booking request (start time, end time, topic, body , title)
          // 2 = booking request cancellation (start time, end time, topic, body , title)
          // 3 = booking request acceptation (start time, end time, topic, body , title)
          // 4 = chat session reminder (start time, end time, topic, body , title)
          // 5 = payment reminder (start time, end time, topic, body , title)
          // 6 = expert send invitation to customer (title, body, invitation sender id)
          // 7 = payment received (title, body, amount, email, plan id)

          children: <Widget>[
            Text(document['body'],
                style: getTextStyle(Colors.black, FontWeight.normal)),
            Visibility(
              visible: document['type'] == 1 ||
                  document['type'] == 2 ||
                  document['type'] == 3 ||
                  document['type'] == 4 ||
                  document['type'] == 5,
              child: Wrap(
                children: <Widget>[
                  Text(document['topic'] == null ? "Empty" : document['topic'],
                      style: getTextStyle(Colors.grey, FontWeight.normal)),
                  Text(document['startTime'] == null ? "Empty" : document['startTime'],
                      style: getTextStyle(Colors.grey, FontWeight.normal)),
                  Text(document['endTime']  == null ? "Empty" : document['endTime'],
                      style: getTextStyle(Colors.grey, FontWeight.normal)),
                ],
              ),
            ),
            Visibility(
              visible: document['type'] == 6,
              child: OutlineButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ConsultantProfile(
                            uid: document['invitationSenderUid']);
                      },
                    ),
                  );
                },
                child: Text("See My Profile".toUpperCase(),
                    style: TextStyle(fontSize: 14)),
              ),
            ),
            Visibility(
              visible: document['type'] == 7,
              child: OutlineButton(
                onPressed: () async {

                },
                child: Text("Set Paypal Email Address".toUpperCase(),
                    style: TextStyle(fontSize: 14)),
              ),
            )
          ],
        ),
        trailing: InkWell(
          child: Icon(Icons.delete),
          onTap: () {
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
                content: new Text('Do you want to delete?',
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
                      onPressed: () => Navigator.of(context).pop(false)),
                  FlatButton(
                      child: Text('Yes',
                          style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'Armata',
                              fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        Firestore.instance
                            .collection('notificationList')
                            .document(document['docId'])
                            .delete()
                            .then((res) {
                          Fluttertoast.showToast(
                              msg: "Delete successful!",
                              toastLength: Toast.LENGTH_LONG);
                        }).catchError((err) {
                          Fluttertoast.showToast(
                              msg: "Delete unsuccessful!",
                              toastLength: Toast.LENGTH_LONG);
                        });
                      })
                ],
              ),
            );
          },
        ),
        isThreeLine: true,
        onTap: () {
          Firestore.instance
              .collection('notificationList')
              .document(document['docId'])
              .updateData({"seenStatus": 1});
        },
      ),
    );
  }

  String getStartTime(document) {
    if (document['startTime'] == null) {
      return document['body'];
    } else {
      return "Start time ${document['startTime']}";
    }
  }

  String getEndTime(document) {
    if (document['endTime'] == null) {
      return "";
    } else {
      return "End time ${document['endTime']}";
    }
  }

  TextStyle getTextStyle(Color color, FontWeight fontWeight) {
    return TextStyle(
        color: color, fontFamily: 'Armata', fontWeight: fontWeight);
  }
}
