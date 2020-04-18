import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    // TODO: implement build
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
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemBuilder: (context, index) =>
                      buildItem(context, snapshot.data.documents[index]),
                  itemCount: snapshot.data.documents.length,
                );
              } else {
                return Center(
                  child: Text("No Notification found!"),
                );
              }
            }));
  }

  buildItem(BuildContext context, document) {
    print(document['uid']);

    return Card(
      color: document['seenStatus'] == 1 ? Colors.white : Colors.white30,
      child: ListTile(
        leading: document['seenStatus'] == 1
            ? Icon(Icons.notifications, size: 40.0)
            : Icon(Icons.notifications_none, size: 40.0),
        title: Text(document['title']),
        subtitle: Wrap(
          children: <Widget>[
            Text(getStartTime(document)),
            Text(getEndTime(document)),
            Visibility(
              visible: document['invitationSenderUid'] != null,
              child: OutlineButton(
                onPressed: () async {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ConsultantProfile(uid: uid);
                      },
                    ),
                  );

                },
                child: Text("See My Profile".toUpperCase(),
                    style: TextStyle(fontSize: 14)),
              ),
            )
          ],
        ),
        trailing: Icon(Icons.touch_app),
        isThreeLine: true,
        onTap: () {
          Firestore.instance
              .collection('notificationList')
              .document(document.documentID)
              .updateData({"seenStatus": 1});
        },
      ),
    );
  }

  String getStartTime(document) {

    if(document['startTime'] == null){
      return document['body'];
    }else {
      return document['startTime'];
    }
  }

  String getEndTime(document) {

    if(document['endTime'] == null){
      return "";
    }else {
      return document['endTime'];
    }

  }
}
