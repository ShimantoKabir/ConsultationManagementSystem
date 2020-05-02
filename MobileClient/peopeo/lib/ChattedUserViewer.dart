import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:peopeo/ChatHistory.dart';

class ChattedUserViewer extends StatefulWidget {

  final List<Map<String, dynamic>> chattedUserIdList;
  final String uid;

  ChattedUserViewer({Key key,@required this.uid, @required this.chattedUserIdList}) : super(key: key);

  @override
  ChattedUserViewerState createState() => new ChattedUserViewerState(uid: uid,chattedUserIdList: chattedUserIdList);
}

class ChattedUserViewerState extends State<ChattedUserViewer>{

  ChattedUserViewerState({Key key,@required this.uid, @required this.chattedUserIdList});

  List<Map<String, dynamic>> chattedUserIdList;
  String uid;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: new AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: new Text('Chat History',
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        child: showChattedUserList(),
      ),
    );
  }

  Widget buildItem(
      BuildContext context, Map<String, dynamic> document) {

    return Card(
      margin: EdgeInsets.all(5.0),
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.all(5.0),
        leading: Container(
          height: 50.0,
          width: 50.0,
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            image: new DecorationImage(
                fit: BoxFit.fill,
                image: new NetworkImage(document['photoUrl'])),
          ),
        ),
        title: getDisplayName(document),
        trailing: Icon(Icons.touch_app),
        onTap: () {

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return ChatHistory(
                  displayName: document['displayName'],
                  peerAvatar: document['photoUrl'],
                  peerId: document['uid'],
                  uid: uid
                );
              },
            ),
          );

        },
      ),
    );

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

  showChattedUserList() {

    if(chattedUserIdList.length > 0){

      return ListView.builder(
        itemBuilder: (context, index) =>
            buildItem(context, chattedUserIdList[index]),
        itemCount: chattedUserIdList.length,
      );

    }else {

      return Center(
        child: Text("[You did't chat any one yet]",
            style: TextStyle(
                color: Colors.red,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold)),
      );

    }

  }

}