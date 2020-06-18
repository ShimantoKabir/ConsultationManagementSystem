import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/fullPhoto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistory extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String displayName;
  final String uid;

  ChatHistory(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      @required this.displayName,
      @required this.uid})
      : super(key: key);

  @override
  ChatHistoryState createState() => new ChatHistoryState(
      peerId: peerId,
      peerAvatar: peerAvatar,
      displayName: displayName,
      uid: uid);
}

class ChatHistoryState extends State<ChatHistory>
    with TickerProviderStateMixin {

  ChatHistoryState(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      @required this.displayName,
      @required this.uid});

  String peerId;
  String peerAvatar;
  String id;
  String displayName;
  String uid;
  int rating;
  var listMessage;
  String groupChatId;
  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  final TextEditingController textEditingController =
      new TextEditingController();

  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  TextEditingController reviewTECtl = TextEditingController();

  @override
  void initState() {
    super.initState();

    groupChatId = '';
    imageUrl = '';
    isLoading = false;
    isShowSticker = false;
    focusNode.addListener(onFocusChange);
    readLocal();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('uid') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }

    print("GroupChatId = $groupChatId");
    FocusScope.of(context).requestFocus(focusNode);
    Firestore.instance
        .collection('userInfoList')
        .document(id)
        .updateData({'chattingWith': peerId});
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document['idFrom'] == id) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
              ? Container(
                  child: Text(
                    document['content'],
                    style: TextStyle(color: primaryColor),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      color: greyColor2,
                      borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                      right: 10.0))
              // payment
              : document['type'] == 3
                  ? Container(
                      child: Text(
                        document['content'],
                        style: TextStyle(color: primaryColor),
                      ),
                      padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                      width: 200.0,
                      decoration: BoxDecoration(
                          color: greyColor2,
                          borderRadius: BorderRadius.circular(8.0)),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 10.0))
                  : document['type'] == 1
                      // Image
                      ? Container(
                          child: FlatButton(
                            child: Material(
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        themeColor),
                                  ),
                                  width: 200.0,
                                  height: 200.0,
                                  padding: EdgeInsets.all(70.0),
                                  decoration: BoxDecoration(
                                    color: greyColor2,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Material(
                                  child: Image.asset(
                                    'assets/images/img_not_available.jpeg',
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                ),
                                imageUrl: document['content'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          FullPhoto(url: document['content'])));
                            },
                            padding: EdgeInsets.all(0),
                          ),
                          margin: EdgeInsets.only(
                              bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                              right: 10.0),
                        )
                      // Sticker
                      : Container(
                          child: new Image.asset(
                            'assets/images/${document['content']}.gif',
                            width: 100.0,
                            height: 100.0,
                            fit: BoxFit.cover,
                          ),
                          margin: EdgeInsets.only(
                              bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                              right: 10.0),
                        )
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                            child: CircularProgressIndicator(
                              strokeWidth: 1.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(themeColor),
                            ),
                            width: 35.0,
                            height: 35.0,
                            padding: EdgeInsets.all(10.0),
                          ),
                          imageUrl: peerAvatar,
                          width: 35.0,
                          height: 35.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(18.0),
                        ))
                    : Container(width: 35.0),
                document['type'] == 0
                    ? Container(
                        child: Text(
                          document['content'],
                          style: TextStyle(color: Colors.white),
                        ),
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                        width: 200.0,
                        decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8.0)),
                        margin: EdgeInsets.only(left: 10.0),
                      )
                    : document['type'] == 3
                        ? Container(
                            child: Text(
                              document['content'],
                              style: TextStyle(color: Colors.white),
                            ),
                            padding:
                                EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                            width: 200.0,
                            decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(8.0)),
                            margin: EdgeInsets.only(left: 10.0),
                          )
                        : document['type'] == 1
                            ? Container(
                                child: FlatButton(
                                  child: Material(
                                    child: CachedNetworkImage(
                                      placeholder: (context, url) => Container(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  themeColor),
                                        ),
                                        width: 200.0,
                                        height: 200.0,
                                        padding: EdgeInsets.all(70.0),
                                        decoration: BoxDecoration(
                                          color: greyColor2,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8.0),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Material(
                                        child: Image.asset(
                                          'assets/images/img_not_available.jpeg',
                                          width: 200.0,
                                          height: 200.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                      ),
                                      imageUrl: document['content'],
                                      width: 200.0,
                                      height: 200.0,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8.0)),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => FullPhoto(
                                                url: document['content'])));
                                  },
                                  padding: EdgeInsets.all(0),
                                ),
                                margin: EdgeInsets.only(left: 10.0),
                              )
                            : Container(
                                child: new Image.asset(
                                  'assets/images/${document['content']}.gif',
                                  width: 100.0,
                                  height: 100.0,
                                  fit: BoxFit.cover,
                                ),
                                margin: EdgeInsets.only(
                                    bottom:
                                        isLastMessageRight(index) ? 20.0 : 10.0,
                                    right: 10.0),
                              ),
              ],
            )
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          title: new Text(displayName,
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          centerTitle: true),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[buildListMessage()],
            ),
            buildLoading()
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .document(groupChatId)
                  .collection('conversations')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),
                  );
                } else {
                  listMessage = snapshot.data.documents;

                  if (snapshot.data.documents.length > 0) {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                      reverse: true,
                      controller: listScrollController,
                    );
                  } else {
                    return Center(
                      child: Text("[No chat history found]",
                          style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Armata',
                              fontWeight: FontWeight.bold)),
                    );
                  }
                }
              },
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
