import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:peopeo/PlanInfo.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peopeo/Plan.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:peopeo/fullPhoto.dart';
import 'MyWebView.dart';

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
  bool needToShowPaymentUi = true;
  bool isPaymentComplete = false;
  bool isChargedMinutesStarted = false;
  var listMessage;
  String groupChatId;
  SharedPreferences prefs;
  DateTime mEndDateTime;
  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  int totalChatDuration = 0;
  String idOfCusLeaveMsg;
  String idOfCusSuccessPaymentMsg;
  int chargedMinutes = 0;
  DateTime reviewAndRatingShowDateTime;
  bool isInternetAvailable = true;
  StreamSubscription<ConnectivityResult> connectivitySubscription;

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
    Screen.keepOn(true);

    print("need to pop up notification = [no] in chat");
    MySharedPreferences.setBooleanValue("needToPopUpNoti", false);

    groupChatId = '';
    imageUrl = '';
    isLoading = false;
    isShowSticker = false;
    int fm = plan.freeMinutesForNewCustomer;
    String pi = plan.paymentTransId;
    int id = plan.id;
    int hr = plan.hourlyRate;

    controller =
        AnimationController(vsync: this, duration: Duration(minutes: 0));

    final DateTime startDateTime = DateTime.parse(plan.fStartTime);
    final DateTime endDateTime = DateTime.parse(plan.fEndTime);
    reviewAndRatingShowDateTime = (fm == null)
        ? null
        : endDateTime.add(Duration(minutes: paymentDuration));
    final DateTime fmAddWithStartDateTime =
        (fm == null) ? null : startDateTime.add(Duration(minutes: fm));
    final DateTime fmAndPdAddWithStartDateTime = (fm == null)
        ? null
        : startDateTime.add(Duration(minutes: (fm + paymentDuration)));
    totalChatDuration = calculateDuration(endDateTime, startDateTime);

    print("Free minute = $fm");
    print("Payment id = $pi");
    print("Plan id = $id");
    print("Plan hourly rate  = $hr");
    print("Total chat duration = $totalChatDuration");
    print("Free min add with start date time = $fmAddWithStartDateTime");
    print("Riview and rating show date time = $reviewAndRatingShowDateTime");

    // if free minute's[10] equal to
    // total chat duration[10] or
    // total chat duration[5] less
    // then free minute's[10]
    // then no need to showed up payment ui
    needToShowPaymentUi =
        (fm != null && fm >= totalChatDuration) ? false : true;

    Timer.periodic(Duration(seconds: 5), (timer) {
      DateTime dateTimeNow = DateTime.now();
      AnimationStatus as = controller.status;
      print("Timer ticking.. !");
      print("Is time ticking running = $isTimeTickerRunning");
      print("Is review and rating showed up = $isReviewAndRatingShowedUp");
      print("Is payment ui showed up = $isPaymentUiShowedUp");
      print("Date time now = $dateTimeNow");
      print("Animation Status = $as");

      // check free minutes
      // available or not
      // if not available
      if (plan.freeMinutesForNewCustomer == null) {
        print('==no free minutes available==');

        // logic for start time ticker
        if (!isTimeTickerRunning && dateTimeNow.isAfter(startDateTime)) {
          int passedAwayMinutes = calculateDuration(dateTimeNow, startDateTime);
          int chatDuration = totalChatDuration - passedAwayMinutes;
          print('Time ticker started!');
          isTimeTickerRunning = true;
          startTimeTicker(controller, chatDuration);
        }

        // logic for review and rating
        if (!isReviewAndRatingShowedUp && dateTimeNow.isAfter(endDateTime)) {
          print('Review and rating showed up!');
          isReviewAndRatingShowedUp = true;
          reviewAndRatingPopUp();
        }

        // if available
      } else {
        print('==free minutes available==');

        // logic for start time ticker
        if (!isTimeTickerRunning && dateTimeNow.isAfter(startDateTime)) {
          // if => need to show payment ui
          // then first chat duration is
          // free minute's
          // else => only chat duration
          // is total chat duration

          // another thing that need to check up
          // if the user came chat room late
          // then we need to minus the late minutes

          int passedAwayMinutes = calculateDuration(dateTimeNow, startDateTime);
          int detectedChatDuration =
              (needToShowPaymentUi) ? fm : totalChatDuration;
          int chatDuration = detectedChatDuration - passedAwayMinutes;
          isTimeTickerRunning = true;
          startTimeTicker(controller, chatDuration);

        }

        // logic for show up payment ui
        // if payment ui showed up that means
        // total chat duration must be greater
        // than free minutes
        if (needToShowPaymentUi &&
            dateTimeNow.isAfter(fmAddWithStartDateTime) &&
            controller.isDismissed &&
            !isPaymentUiShowedUp) {
          // open payment ui only for customer
          int m = calculateDuration(endDateTime, startDateTime);
          chargedMinutes = m - fm;

          if (userType == 1) {
            double chargeAmount = hr * (chargedMinutes / 60);
            confirmPopUp(context, chargeAmount.toStringAsFixed(2), plan);
          }

          // but start time ticker for all
          isPaymentUiShowedUp = true;
          startTimeTicker(controller, paymentDuration);
        }

        // logic for start time ticker after
        // end of payment completion time
        if (dateTimeNow.isAfter(fmAndPdAddWithStartDateTime) &&
            controller.isDismissed &&
            !isChargedMinutesStarted) {
          // customer
          if (userType == 1) {
            checkPaymentStatus(plan.id, true);
          }

          isChargedMinutesStarted = true;
          startTimeTicker(controller, chargedMinutes);
        }

        // logic for popup review and rating
        if (isPaymentUiShowedUp &&
            !isReviewAndRatingShowedUp &&
            controller.isDismissed &&
            dateTimeNow.isAfter(reviewAndRatingShowDateTime)) {
          reviewAndRatingPopUp();
          print('Show popup for review and rating in time tiker block!');
          isReviewAndRatingShowedUp = true;
        }
      }
    });

    focusNode.addListener(onFocusChange);
    readLocal();

    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => isInternetAvailable = false);
        print('You are disconnected from the internet.');
      } else {
        setState(() => isInternetAvailable = true);
        print('Data connection is available.');
      }
    });
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
    // type: 0 = text, 1 = image, 2 = sticker,
    // 3 = customer leave after free minute end
    if (content.trim() != '') {
      sendMsgContent(content, type);

      // update plan cus con chatted
      // status only first time
      if (!isFirstMsgSend) {
        print("isFirstMsgSend = $isFirstMsgSend");
        print("isFirstMsgSend = $listMessage");
        changeChattedStatus(plan.id, uid, peerId);
        isFirstMsgSend = true;
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    idOfCusLeaveMsg = (document['type'] == 3 &&
            document['isReviewAndRatingShowedUp'] == 0 &&
            !isReviewAndRatingShowedUp)
        ? document.documentID
        : idOfCusLeaveMsg;

    idOfCusSuccessPaymentMsg = (document['type'] == 4 &&
            document['isPaymentCompleteAfterFreeMinuteGone'] == 0)
        ? document.documentID
        : idOfCusSuccessPaymentMsg;

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
                  : document['type'] == 4
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
                              margin: EdgeInsets.only(
                                  bottom:
                                      isLastMessageRight(index) ? 20.0 : 10.0,
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
                                  bottom:
                                      isLastMessageRight(index) ? 20.0 : 10.0,
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
                    : document['type'] == 3
                        // Customer don't want to continue after free minute's
                        // so need open up review and rating window
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
                        : document['type'] == 4
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
                                          placeholder: (context, url) =>
                                              Container(
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
                                            clipBehavior: Clip.hardEdge,
                                          ),
                                          imageUrl: document['content'],
                                          width: 200.0,
                                          height: 200.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8.0)),
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
                                        bottom: isLastMessageRight(index)
                                            ? 20.0
                                            : 10.0,
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
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Alert',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Armata',
                )),
            content: new Text('Do you want to leave the chat room?',
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
                    if (isShowSticker) {
                      setState(() {
                        isShowSticker = false;
                      });
                    } else {
                      Firestore.instance
                          .collection('userInfoList')
                          .document(id)
                          .updateData({'chattingWith': null});
                    }

                    sendMsgContent(
                        "$displayName has ended the chat session.", 3);
                    isReviewAndRatingShowedUp = true;
                    controller.stop();
                    reviewAndRatingPopUp();
                  })
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: !isInternetAvailable,
        child: Scaffold(
            appBar: new AppBar(
                iconTheme: IconThemeData(color: Colors.black),
                backgroundColor: Colors.white,
                leading: InkWell(
                  onTap: () {
                    onBackPress();
                  },
                  child: Icon(Icons.stop),
                ),
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
                  buildLoading()
                ],
              ),
              onWillPop: onBackPress,
            ),
            bottomNavigationBar: Visibility(
                visible: !isInternetAvailable,
                child: Container(
                  color: Colors.white,
                  height: 50.0,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                            strokeWidth: 1.0,
                          )),
                      SizedBox(width: 10),
                      Text("Trying to connect internet...",
                          style: TextStyle(
                            fontSize: 17.0,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Armata',
                          ))
                    ],
                  ),
                ))));
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
                  .collection('conversations')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor));
                } else {
                  listMessage = snapshot.data.documents;
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => actionAfterFreeMinutesGone(context));

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
              child: Text('Send',
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
                  showAlertDialog(
                      context, "Please wait, saving review and rating ...");

                  var request;
                  // customer
                  if (userType == 1) {
                    request = {
                      'plan': {
                        'id': plan.id,
                        'conUid': peerId,
                        'cusUid': uid,
                        'conReview': reviewTECtl.text.toString(),
                        'conRating': rating,
                        'userType': 1
                      }
                    };
                    // consultant
                  } else {
                    request = {
                      'plan': {
                        'id': plan.id,
                        'conUid': uid,
                        'cusUid': peerId,
                        'cusReview': reviewTECtl.text.toString(),
                        'cusRating': rating,
                        'userType': 2
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
    print("request review and rating = $request");

    if (response.statusCode == 200) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PlanInfo(userType: userType, uid: uid)));
      print(response.body.toString());
    } else {
      this.dispose();
      print("need to pop up notification = [yes] in chat when finish");
      MySharedPreferences.setBooleanValue("needToPopUpNoti", true);
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PlanInfo(userType: userType, uid: uid)));
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
              "You have $paymentDuration minute's to coomplete your payemnt. Would to like to pay?",
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
                print(
                    "Review and rating showed up when customer don't want to pay");
                sendMsgContent(cusLeaveMsg, 3);
                isReviewAndRatingShowedUp = true;
                needToShowPaymentUi = false;
                Navigator.of(context).pop();
                controller.stop();
                reviewAndRatingPopUp();
              },
            ),
            FlatButton(
              child: Text("Yes",
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () async {
                Connectivity().checkConnectivity().then((connectivityResult) {
                  if (connectivityResult == ConnectivityResult.none) {
                    Fluttertoast.showToast(
                        msg: "No internat connection available.");
                  } else {
                    sendMsgContent(cusContinueMsg, 0);
                    getClientToken(amount, p.id);
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void paymentCheckingPopUp(BuildContext context) {
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
              "Payment successfull",
              style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.normal),
            )
          ]),
          actions: <Widget>[
            FlatButton(
              child: Text('Continue Chat',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Armata',
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                checkPaymentStatus(plan.id, false);
              },
            )
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

    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (BuildContext context) => MyWebView(
                  title: "Payment",
                  url: url,
                )))
        .whenComplete(() {
      MySharedPreferences.getBooleanValue('isPaymentSuccessful')
          .then((isPaymentSuccessful) {
        if (isPaymentSuccessful) {
          paymentCheckingPopUp(context);
        } else {
          Fluttertoast.showToast(
              msg: "Payment unsuccessful!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);

          sendMsgContent("Customer payment unsuccessful!", 3);
          isReviewAndRatingShowedUp = true;
          controller.stop();
          reviewAndRatingPopUp();
        }
      });
    });
  }

  Future<void> sendMsgContent(String content, int type) async {

    print("check timmer status = ${controller.status}");

    Connectivity().checkConnectivity().then((connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        Fluttertoast.showToast(msg: "No internet connection available!");
      } else if(controller.isDismissed){
        Fluttertoast.showToast(msg: "You can only send message when time ticker is running!");
      } else {
        textEditingController.clear();

        var gcrDocumentReference =
            Firestore.instance.collection('messages').document(groupChatId);

        gcrDocumentReference.setData({
          'groupChatId': groupChatId,
        });

        var covDocumentReference = gcrDocumentReference
            .collection('conversations')
            .document(DateTime.now().millisecondsSinceEpoch.toString());

        var obj;

        if (type == 3) {
          obj = {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type,
            'isReviewAndRatingShowedUp': 0
          };
        } else if (type == 4) {
          obj = {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type,
            'isPaymentCompleteAfterFreeMinuteGone': 0
          };
        } else {
          obj = {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type,
            'isReviewAndRatingShowedUp': -1
          };
        }

        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(covDocumentReference, obj);
        });

        listScrollController.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void checkPaymentStatus(int id, bool isCalledFromTimerPeriodic) async {
    String url = serverBaseUrl + '/plan/check-payment-status';
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
      print("Transaction completion status = $code");

      // payment complete
      if (code == 200) {
        Navigator.pop(context);
        isPaymentComplete = true;
        Fluttertoast.showToast(
            msg: "You have successfully complete your payment, "
                "enjoy the conversation the expert!");

        if (!isCalledFromTimerPeriodic) {
          sendMsgContent(
              "I have successfully complete payment, let's chat.", 4);
        }

        // payment not complete
      } else {
        sendMsgContent("Customer payment unsuccessful!", 3);
        isReviewAndRatingShowedUp = true;
        Navigator.of(context).pop();
        controller.stop();
        reviewAndRatingPopUp();
      }
    } else {
      throw Exception('Failed to load post');
    }
  }

  actionAfterFreeMinutesGone(BuildContext context) {

    print("Id of cus leave after free minutes gone $idOfCusLeaveMsg");
    print("Id of cus payment success after free minute's gone"
        " $idOfCusSuccessPaymentMsg");

    if (idOfCusLeaveMsg != null &&
        !isReviewAndRatingShowedUp
        && plan.freeMinutesForNewCustomer != null) {
      Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection('conversations')
          .document(idOfCusLeaveMsg)
          .updateData(<String, dynamic>{'isReviewAndRatingShowedUp': 1});
      reviewAndRatingPopUp();
      controller.stop();
      isReviewAndRatingShowedUp = true;
    }

    if (idOfCusSuccessPaymentMsg != null && !isChargedMinutesStarted) {
      Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection('conversations')
          .document(idOfCusSuccessPaymentMsg)
          .updateData(
              <String, dynamic>{'isPaymentCompleteAfterFreeMinuteGone': 1});

      isChargedMinutesStarted = true;
      startTimeTicker(controller, chargedMinutes);
      reviewAndRatingShowDateTime =
          DateTime.now().add(Duration(minutes: chargedMinutes));
      print(
          "Changed review and rating show date time = $reviewAndRatingShowDateTime");
    }
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

  @override
  void dispose() {
    if (controller.status == AnimationStatus.reverse) {
      controller.dispose();
    }
    connectivitySubscription.cancel();
    super.dispose();
  }
}
