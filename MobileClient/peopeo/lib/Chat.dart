import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peopeo/PlanInfo.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Plan.dart';
import 'const.dart';
import 'package:peopeo/HttpResponse.dart';
import 'fullPhoto.dart';

class Chat extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String displayName;
  final Plan plan;
  final int userType;
  final String uid;

  Chat(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      @required this.displayName,
      @required this.plan,
      @required this.userType,
      @required this.uid})
      : super(key: key);

  @override
  ChatState createState() => new ChatState(
      peerId: peerId,
      peerAvatar: peerAvatar,
      displayName: displayName,
      plan: plan,
      userType: userType,
      uid: uid);
}

class ChatState extends State<Chat> with TickerProviderStateMixin {
  ChatState(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      @required this.displayName,
      @required this.plan,
      @required this.userType,
      @required this.uid});

  String peerId;
  String peerAvatar;
  String id;
  String displayName;
  Plan plan;
  int userType;
  String uid;
  int rating;
  bool isFirstMsgSend = false;
  bool isPaymentUiShowedUp = false;
  bool isTimeTickerRunning = false;
  bool isReviewAndRatingShowedUp = false;
  var listMessage;
  String groupChatId;
  SharedPreferences prefs;
  DateTime mEndDateTime;
  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  final TextEditingController textEditingController =
      new TextEditingController();

  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  // time ticker controller
  AnimationController controller;

  TextEditingController reviewTECtl = TextEditingController();

  String get timerString {
    Duration duration = controller.duration * controller.value;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);

    groupChatId = '';

    isLoading = false;
    isShowSticker = false;
    imageUrl = '';

    controller =
        AnimationController(vsync: this, duration: Duration(minutes: 0));

    final DateTime aStartDateTime = DateTime.parse(plan.fStartTime);
    final DateTime aEndDateTime = DateTime.parse(plan.fEndTime);
    final DateTime currentDateTime = DateTime.now();

    int fm = plan.freeMinutesForNewCustomer;
    String pi = plan.paymentTransId;
    int id = plan.id;
    print("Free minute = $fm");
    print("Payment id = $pi");
    print("Plan id $id");

    if (plan.freeMinutesForNewCustomer != null) {
      mEndDateTime = aEndDateTime.add(Duration(minutes: 2));
    }

    Timer.periodic(Duration(seconds: 5), (timer) {
      print("Hi thee");

      // logic for start time ticker
      if (!isTimeTickerRunning && currentDateTime.isAfter(aStartDateTime)) {
        if (plan.freeMinutesForNewCustomer == null) {
          int m = calculateDuration(aEndDateTime, currentDateTime);
          startTimeTicker(controller, m);
        } else {
          int m = calculateDuration(mEndDateTime, currentDateTime);
          startTimeTicker(controller, m);
        }
        print('Time ticker started!');
        isTimeTickerRunning = true;
      }

      // logic for popup review and rating
      if (plan.freeMinutesForNewCustomer == null) {
        if (!isReviewAndRatingShowedUp) {
          if (DateTime.now().isAfter(aEndDateTime)) {
            reviewAndRatingPopUp();
            print('Show popup for review and rating');
            isReviewAndRatingShowedUp = true;
          }
        }
      } else {
        if (!isReviewAndRatingShowedUp) {
          if (DateTime.now().isAfter(mEndDateTime)) {
            reviewAndRatingPopUp();
            print('Show popup for review and rating');
            isReviewAndRatingShowedUp = true;
          }
        }
      }

      // logic for show up payment ui
      if (plan.freeMinutesForNewCustomer != null && userType == 1) {
        final DateTime pDateTime = aStartDateTime
            .add(Duration(minutes: plan.freeMinutesForNewCustomer));

        if (DateTime.now().isAfter(pDateTime) && !isPaymentUiShowedUp) {
          print("Show payment ui!");
          int m = calculateDuration(aEndDateTime, DateTime.now());
          int hourlyRate = plan.hourlyRate * m;
          confirmPopUp(context, hourlyRate.toString(), plan);
          isPaymentUiShowedUp = true;
        }
      }
    });

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

    Firestore.instance
        .collection('userInfoList')
        .document(id)
        .updateData({'chattingWith': peerId});

    setState(() {});
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      sendMsgContent(content, type);

      // update plan cus con chatted
      // status only first time
      if (!isFirstMsgSend) {
        print("isFirstMsgSend");
        changeChattedStatus(plan.id, uid, peerId);
        isFirstMsgSend = true;
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
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
                      right: 10.0),
                )
              : document['type'] == 1
                  // Image
                  ? Container(
                      child: FlatButton(
                        child: Material(
                          child: CachedNetworkImage(
                            placeholder: (context, url) => Container(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(themeColor),
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
                                'images/img_not_available.jpeg',
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                              clipBehavior: Clip.hardEdge,
                            ),
                            imageUrl: document['content'],
                            width: 200.0,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
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
                        'images/${document['content']}.gif',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 10.0),
                    ),
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
                        ),
                        clipBehavior: Clip.hardEdge,
                      )
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
                    : document['type'] == 1
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
                                    clipBehavior: Clip.hardEdge,
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
                                bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                                right: 10.0),
                          ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      "lol",
                      style: TextStyle(
                          color: greyColor,
                          fontSize: 12.0,
                          fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
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
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      Firestore.instance
          .collection('userInfoList')
          .document(id)
          .updateData({'chattingWith': null});
      Navigator.pop(context);
    }

    return Future.value(false);
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
          centerTitle: true,
          actions: <Widget>[
            Padding(
              child: Container(
                padding: const EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.all(Radius.circular(5.0) //
                        )),
                child: Center(
                  child: AnimatedBuilder(
                      animation: controller,
                      builder: (BuildContext context, Widget child) {
                        return Text(timerString,
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Armata',
                                fontWeight: FontWeight.bold));
                      }),
                ),
              ),
              padding: EdgeInsets.all(5.0),
            )
          ]),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                // List of messages
                buildListMessage(),

                // Sticker
                (isShowSticker ? buildSticker() : Container()),

                // Input content
                buildInput(),
              ],
            ),

            // Loading
            buildLoading()
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'assets/images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'assets/images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'assets/images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'assets/images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'assets/images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'assets/images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'assets/images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'assets/images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'assets/images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border:
              new Border(top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImage,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.face),
                onPressed: getSticker,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border:
              new Border(top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
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
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  int calculateDuration(DateTime endDateTime, DateTime startDateTime) {
    int milliseconds = endDateTime.difference(startDateTime).inMilliseconds;
    double minutes = (milliseconds / 1000) / 60;
    return minutes.round();
  }

  void startTimeTicker(AnimationController controller, int minutes) {
    controller.reset();
    controller.duration = Duration(minutes: minutes);
    controller.reverse(from: 1.0);
  }

  void reviewAndRatingPopUp() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return AlertDialog(
          title: Text('Review & Rating',
              style: TextStyle(
                  color: Colors.pink,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          content: Wrap(children: <Widget>[
            Center(
              child: RatingBar(
                initialRating: 0,
                direction: Axis.horizontal,
                itemCount: 5,
                itemSize: 30,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, index) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (r) {
                  setState(() {
                    rating = r.toInt();
                  });
                },
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: TextField(
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(15.0, 5.0, 5.0, 5.0),
                      border: OutlineInputBorder(),
                      labelText: "Write a review"),
                  controller: reviewTECtl,
                ),
              ),
            )
          ]),
          actions: <Widget>[
            FlatButton(
              child: Text('NEXT',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                if (rating == null) {
                  Fluttertoast.showToast(msg: "Please give a rating!");
                } else if (reviewTECtl.text.toString().isEmpty) {
                  Fluttertoast.showToast(msg: "Please give a review!");
                } else {
                  var request;
                  // customer
                  if (userType == 1) {
                    request = {
                      'plan': {
                        'id': plan.id,
                        'conUid': peerId,
                        'cusUid': null,
                        'conReview': reviewTECtl.text.toString(),
                        'conRating': rating
                      }
                    };

                    // consultant
                  } else {
                    request = {
                      'plan': {
                        'id': plan.id,
                        'conUid': null,
                        'cusUid': peerId,
                        'cusReview': reviewTECtl.text.toString(),
                        'cusRating': rating
                      }
                    };
                  }
                  saveReviewAndRating(request, uid, userType);
                }
              },
            )
          ],
        );
      },
    );
  }

  void saveReviewAndRating(request, uid, userType) async {
    String url = serverBaseUrl + '/plan/save-review-and-rating';
    Map<String, String> headers = {"Content-type": "application/json"};
    Response response =
        await post(url, headers: headers, body: json.encode(request));
    if (response.statusCode == 200) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PlanInfo(userType: userType, uid: uid)));
      print(response.body.toString());
    } else {
      throw Exception('Failed to load post');
    }
  }

  void confirmPopUp(BuildContext context, String amount, Plan p) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert',
              style: TextStyle(
                  color: Colors.pink,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          content: Wrap(children: <Widget>[
            Text(
              "If you want to continue chat, you need to pay $amount \$",
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.normal),
            ),
            Text(
              "[We have given you extrea 2 minutes to coomplete your payemnt, consultant will not charing this 2 minutes]",
              style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.normal),
            )
          ]),
          actions: <Widget>[
            FlatButton(
              child: Text('No',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {

                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PlanInfo(userType: userType, uid: uid)));
              },
            ),
            FlatButton(
              child: Text('Yes',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                getClientToken(amount, p.id);
              },
            ),
          ],
        );
      },
    );
  }

  void getClientToken(String amount, int planId) async {
    String url = serverBaseUrl + '/pg/get-client-token';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {'customerId': uid};

    Response response =
        await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      // checking if server returns an OK response, then parse the JSON.
      print(HttpResponse.fromJson(json.decode(response.body)).clientToken);

      String clientToken =
          HttpResponse.fromJson(json.decode(response.body)).clientToken;

      reloadAuth(clientToken, amount, planId);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  void reloadAuth(String clientToken, String amount, int planId) async {
    String url = serverBaseUrl + '/auth/reload';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {
      'auth': {
        'uId': uid,
        'amount': amount,
        'clientToken': clientToken,
        'planId': planId
      }
    };

    Response response =
        await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      String aid = HttpResponse.fromJson(json.decode(response.body)).aid;

      goBrowserForPayment(aid);

      print(response.body.toString());
    } else {
      throw Exception('Failed to load post');
    }
  }

  void changeChattedStatus(int planId, String cusUid, String conUid) async {
    String url = serverBaseUrl + '/plan/change-are-cus-con-have-chatted-status';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {
      'plan': {'id': planId, 'cusUid': cusUid, 'conUid': conUid}
    };

    Response response =
        await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      // HttpResponse.fromJson(json.decode(response.body));
      print(response.body.toString());
    } else {
      throw Exception('Failed to load post');
    }
  }

  void goBrowserForPayment(String aid) async {
    String url = webClientBaseUrl + '/payment.html?aid=' + aid + "&uid=" + uid;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    if (controller.status == AnimationStatus.reverse) {
      controller.dispose();
    }
    super.dispose();
  }

  void sendMsgContent(String content, int type) {
    textEditingController.clear();

    var documentReference = Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .collection(groupChatId)
        .document(DateTime.now().millisecondsSinceEpoch.toString());

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'idFrom': id,
          'idTo': peerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': content,
          'type': type
        },
      );
    });

    listScrollController.animateTo(0.0,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void hookConForAllowCusToOnSpotPayment() {
    Firestore.instance.collection('userInf').add({
      'title': "Payment Request",
      'body': "A customer is waiting for you and, would you like chat with him",
      'isConAllowCusForPayment': false
    });
  }

  void checkPaymentCompleteStatus(int id) async {
    String url = serverBaseUrl + '/plan/check-payment-complete-status';
    Map<String, String> headers = {"Content-type": "application/json"};
    var request = {
      'plan': {
        'id': id,
      }
    };

    Response response =
    await post(url, headers: headers, body: json.encode(request));

    if (response.statusCode == 200) {
      int code = HttpResponse.fromJson(json.decode(response.body)).code;

      if(code == 200){

        Navigator.pop(context);

      }else{

        Fluttertoast.showToast(msg: "You did not complete your payment yet!");

      }

    } else {
      throw Exception('Failed to load post');
    }
  }

}
