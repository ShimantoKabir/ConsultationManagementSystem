import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
            Text("Start time "+document['startTime']),
            Text("End time "+document['endTime'])
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
}
