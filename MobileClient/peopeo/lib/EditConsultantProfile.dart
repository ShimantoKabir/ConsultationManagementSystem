import 'dart:io';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class EditConsultantProfile extends StatefulWidget {
  final String uid;

  EditConsultantProfile({Key key, @required this.uid}) : super(key: key);

  @override
  EditConsultantProfileState createState() =>
      new EditConsultantProfileState(uid: uid);
}

class EditConsultantProfileState extends State<EditConsultantProfile> {

  EditConsultantProfileState({Key key, @required this.uid});

  TextEditingController displayNameTECtl = TextEditingController();
  TextEditingController shortDesTECtl = TextEditingController();
  TextEditingController longDesTECtl = TextEditingController();
  TextEditingController phoneNumberTECtl = TextEditingController();

  String uid;
  String fileType;
  File file;
  String fileName;
  String operationText;
  bool isUploaded = true;
  String result;

  // variable for convert
  // video url to image
  ImageFormat format = ImageFormat.JPEG;
  int quality = 10;
  int maxHeight = 250;
  int maxWidth = 250;
  String tempDir;
  String filePath;
  String hourlyRate;
  String freeMinutesForNewCustomer;
  String email;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => tempDir = d.path);

    Firestore.instance
        .collection('userInfoList')
        .document(uid)
        .get()
        .then((doc) {
      int hr = (doc['hourlyRate'] == null) ? null : doc['hourlyRate'];
      int fm = (doc['freeMinutesForNewCustomer'] == null)
          ? null
          : doc['freeMinutesForNewCustomer'];

      email = (doc['email'] == null) ? '' : doc['email'];

      setState(() {
        hourlyRate = (hr == null) ? '0' : hr.toString();
        freeMinutesForNewCustomer = (fm == null) ? '0' : fm.toString();
      });

      displayNameTECtl.text = doc['displayName'];
      phoneNumberTECtl.text = doc['phoneNumber'];
      shortDesTECtl.text = doc['shortDescription'];
      longDesTECtl.text = doc['longDescription'];

    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.person_outline, color: Colors.black)),
                    Tab(icon: Icon(Icons.camera, color: Colors.black)),
                    Tab(icon: Icon(Icons.video_library, color: Colors.black)),
                  ],
                ),
                iconTheme: IconThemeData(color: Colors.black),
                backgroundColor: Colors.white,
                title: Text("Edit Profile",
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Armata',
                        fontWeight: FontWeight.bold)),
                centerTitle: true),
            body: TabBarView(
              children: [
                SingleChildScrollView(
                  child: StreamBuilder(
                      stream: Firestore.instance
                          .collection('userInfoList')
                          .where('uid', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Column(
                            children: <Widget>[
                              Center(
                                child: Badge(
                                  badgeContent: Icon(Icons.notifications, color: Colors.grey),
                                  child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Container(
                                        height: 150.0,
                                        width: 150.0,
                                        decoration: new BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: new DecorationImage(
                                              fit: BoxFit.fill,
                                              image: NetworkImage(snapshot.data
                                                  .documents[0]['photoUrl'])),
                                        ),
                                      )
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Display Name",
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Armata',
                                    )),
                              ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: TextField(
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.fromLTRB(
                                            15.0, 5.0, 5.0, 5.0),
                                        border: OutlineInputBorder()),
                                    controller: displayNameTECtl,
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Phone Number(Optional)",
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Armata',
                                    )),
                              ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: TextField(
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.fromLTRB(
                                            15.0, 5.0, 5.0, 5.0),
                                        border: OutlineInputBorder()),
                                    controller: phoneNumberTECtl,
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Hourly Rate(\$/Hour)",
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Armata',
                                    )),
                              ),
                              Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  margin: EdgeInsets.all(10.0),
                                  padding:
                                      EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                                  width: MediaQuery.of(context).size.width,
                                  child: DropdownButton<String>(
                                    value: hourlyRate,
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    onChanged: (String newValue) {
                                      setState(() {
                                        hourlyRate = newValue;
                                      });
                                    },
                                    items: <String>['0', '5', '10', '15', '20']
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  )),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Free minute's for new customer",
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Armata',
                                    )),
                              ),
                              Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  margin: EdgeInsets.all(10.0),
                                  padding:
                                      EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                                  width: MediaQuery.of(context).size.width,
                                  child: DropdownButton<String>(
                                    value: freeMinutesForNewCustomer,
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    onChanged: (String newValue) {
                                      setState(() {
                                        freeMinutesForNewCustomer = newValue;
                                      });
                                    },
                                    items: <String>['0', '5', '10', '15', '20']
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  )),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Short Description",
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Armata',
                                    )),
                              ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: TextField(
                                    maxLines: 4,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.fromLTRB(
                                            15.0, 15.0, 15.0, 15.0),
                                        border: OutlineInputBorder()),
                                    controller: shortDesTECtl,
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Long Description",
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Armata',
                                    )),
                              ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: TextField(
                                    maxLines: 8,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.fromLTRB(
                                            15.0, 15.0, 15.0, 15.0),
                                        border: OutlineInputBorder()),
                                    controller: longDesTECtl,
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.all(10.0),
                                child: RaisedButton(
                                  color: Colors.red,
                                  textColor: Colors.white,
                                  child: Text("SAVE",
                                      style: TextStyle(fontSize: 14)),
                                  shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(8.0),
                                      side: BorderSide(color: Colors.red)),
                                  onPressed: () {
                                    if (displayNameTECtl.text
                                        .toString()
                                        .isEmpty) {
                                      Fluttertoast.showToast(
                                          msg: "Display name required!");
                                    } else if (hourlyRate == null) {
                                      Fluttertoast.showToast(
                                          msg: "Select your hourly rate!");
                                    } else if (freeMinutesForNewCustomer ==
                                        null) {
                                      Fluttertoast.showToast(
                                          msg:
                                              "Select free minute for new customer!");
                                    } else {

                                      showAlertDialog(context,"Saving information.");

                                      Firestore.instance
                                          .collection('userInfoList')
                                          .document(uid)
                                          .updateData({
                                        'displayName':
                                            displayNameTECtl.text.toString(),
                                        'hourlyRate': int.tryParse(hourlyRate),
                                        'freeMinutesForNewCustomer':
                                            int.tryParse(
                                                freeMinutesForNewCustomer),
                                        'phoneNumber': phoneNumberTECtl.text,
                                        'shortDescription': (shortDesTECtl.text
                                                .toString()
                                                .isEmpty)
                                            ? null
                                            : shortDesTECtl.text.toString(),
                                        'longDescription': (longDesTECtl.text
                                                .toString()
                                                .isEmpty)
                                            ? null
                                            : longDesTECtl.text.toString(),
                                        'hashTag': getHashTag()
                                      }).then((val){

                                        Navigator.of(context, rootNavigator: true).pop();
                                        Fluttertoast.showToast(msg: "Information save successfully!");

                                      }).catchError((err){

                                        print(err);
                                        Navigator.of(context, rootNavigator: true).pop();
                                        Fluttertoast.showToast(msg: "Some thing went wrong!");

                                      });
                                    }
                                  },
                                ),
                              )
                            ],
                          );
                        } else {
                          return Text('No user info found');
                        }
                      }),
                ),
                StreamBuilder(
                  stream: Firestore.instance
                      .collection('userInfoList')
                      .document(uid)
                      .collection("imageUrlList")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) => buildItem(
                            context, snapshot.data.documents, 'im', index),
                        itemCount: snapshot.data.documents.length + 1,
                      );
                    }
                  },
                ),
                StreamBuilder(
                  stream: Firestore.instance
                      .collection('userInfoList')
                      .document(uid)
                      .collection("videoThumbnailUrlList")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      );
                    } else {
                      return Column(
                        children: <Widget>[
                          ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) => buildItem(
                                context, snapshot.data.documents, 'vd', index),
                            itemCount: snapshot.data.documents.length + 1,
                          )
                        ],
                      );
                    }
                  },
                )
              ],
            )),
      ),
    );
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

  Future<String> pickFile(BuildContext context, String uuid) async {
    Future<String> futureFileUrl;
    try {
      if (fileType == 'image') {
        file = await FilePicker.getFile(type: FileType.image);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName);
      }
      if (fileType == 'audio') {
        file = await FilePicker.getFile(type: FileType.audio);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName);
      }
      if (fileType == 'video') {
        file = await FilePicker.getFile(type: FileType.video);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName);
      }
      if (fileType == 'pdf') {
        file = await FilePicker.getFile(
            type: FileType.custom, fileExtension: 'pdf');
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName);
      }
      if (fileType == 'others') {
        file = await FilePicker.getFile(type: FileType.any);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName);
      }
    } on Exception catch (e) {
      print(e.toString());
      futureFileUrl = null;
    }
    return futureFileUrl;
  }

  Future<String> uploadFile(File file, String filename) async {
    print(fileType);

    StorageReference storageReference;
    if (fileType == 'image') {
      storageReference =
          FirebaseStorage.instance.ref().child("images/$filename");
    }
    if (fileType == 'audio') {
      storageReference =
          FirebaseStorage.instance.ref().child("audio/$filename");
    }
    if (fileType == 'video') {
      storageReference =
          FirebaseStorage.instance.ref().child("videos/$filename");
    }
    if (fileType == 'pdf') {
      storageReference = FirebaseStorage.instance.ref().child("pdf/$filename");
    }
    if (fileType == 'others') {
      storageReference =
          FirebaseStorage.instance.ref().child("others/$filename");
    }
    final StorageUploadTask uploadTask = storageReference.putFile(file);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());
    return url;
  }

  Widget buildItem(BuildContext context, documents, String ft, int i) {
    String imgUrl;
    String collectionName;
    String alertMsg;
    String btnText;

    if (i == 0) {
      btnText = (ft == "vd") ? "Upload Video" : "Upload Image";

      return Padding(
        padding: EdgeInsets.all(16.0),
        child: RaisedButton(
          color: Colors.red,
          textColor: Colors.white,
          child: Text(btnText, style: TextStyle(fontSize: 14)),
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.red)),
          onPressed: () {
            // upload video
            if (ft == "vd") {

              showAlertDialog(context, "Video uploading please wait...!");

              CollectionReference cr = Firestore.instance
                  .collection('userInfoList')
                  .document(uid)
                  .collection("videoThumbnailUrlList");

              cr.getDocuments().then((im) {
                if (im.documents.length > 4) {
                  Fluttertoast.showToast(
                      msg: "Video uploading limit has been finished!");
                } else {
                  String uuid = new Uuid().v1();
                  // get video from device
                  FilePicker.getFile(type: FileType.video).then((pickedFile) {
                    // upload the video
                    setState(() {
                      fileType = 'video';
                    });

                    String vdName = uuid + p.extension(pickedFile.path);

                    uploadFile(pickedFile, vdName).then((vdUrl) {
                      // get thumbnail img
                      // form video url
                      VideoThumbnail.thumbnailFile(
                              video: vdUrl,
                              thumbnailPath: tempDir,
                              imageFormat: format,
                              maxHeight: maxHeight,
                              maxWidth: maxWidth,
                              quality: quality)
                          .then((thmImg) {
                        setState(() {
                          fileType = 'image';
                        });

                        File thmFile = new File(thmImg);
                        String thmName = uuid + p.extension(thmFile.path);
                        // upload thumbnail img
                        uploadFile(File(thmImg), thmName).then((thmUrl) {
                          cr.document(uuid).setData({
                            'uuid': uuid,
                            'videoPath': "videos/" + vdName,
                            'videoUrl': vdUrl,
                            'thmUrl': thmUrl,
                            'thmPath': "images/" + thmName,
                          });
                          print("Time to close loading");
                          Navigator.of(context, rootNavigator: true).pop();
                        });
                      });
                    });
                  });
                }
              });

              // upload image
            } else {

              setState(() {
                fileType = 'image';
              });

              CollectionReference cr = Firestore.instance
                  .collection('userInfoList')
                  .document(uid)
                  .collection("imageUrlList");

              cr.getDocuments().then((im) {
                if (im.documents.length > 8) {
                  Fluttertoast.showToast(
                      msg:
                      "Image uploading limit has been finished!");
                } else {

                  showAlertDialog(
                      context, "Image uploading please wait...!");

                  String uuid = new Uuid().v1();

                  pickFile(context, uuid).then((imUrl) {
                    cr.document(uuid).setData({
                      'uuid': uuid,
                      'path': "images/" + fileName,
                      'imageUrl': imUrl,
                    });
                    print("Time to close loading");
                    Navigator.of(context, rootNavigator: true).pop();
                  });
                }
              });

            }
          },
        ),
      );
    } else {
      var document = documents[i - 1];

      if (ft == "vd") {
        imgUrl = document['thmUrl'];
        collectionName = "videoThumbnailUrlList";
        alertMsg = "Video deleting please wait...!";
      } else {
        imgUrl = document['imageUrl'];
        collectionName = "imageUrlList";
        alertMsg = "Image deleting please wait...!";
      }

      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.network(imgUrl, fit: BoxFit.cover),
            ButtonBar(
              buttonHeight: 10.0,
              children: <Widget>[
                FlatButton(
                  child: Icon(Icons.delete),
                  onPressed: () {

                    showAlertDialog(context, alertMsg);

                    if (ft == "vd") {
                      FirebaseStorage.instance
                          .ref()
                          .child(document['videoPath'])
                          .delete()
                          .then((v) {
                        FirebaseStorage.instance
                            .ref()
                            .child(document['thmPath'])
                            .delete()
                            .then((t) {
                          Firestore.instance
                              .collection('userInfoList')
                              .document(uid)
                              .collection(collectionName)
                              .document(document['uuid'])
                              .delete()
                              .then((du) {
                            Navigator.of(context, rootNavigator: true).pop();
                          });
                        });
                      });
                    } else {
                      FirebaseStorage.instance
                          .ref()
                          .child(document['path'])
                          .delete()
                          .then((df) {
                        Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection(collectionName)
                            .document(document['uuid'])
                            .delete()
                            .then((du) {
                          Navigator.of(context, rootNavigator: true).pop();
                        });
                      });
                    }

                  },
                )
              ],
            ),
          ],
        ),
      );
    }
  }

  String getHashTag() {
    String hashTag = '';

    if (shortDesTECtl.text.toString().isNotEmpty) {
      String text = shortDesTECtl.text.toString();
      RegExp exp = new RegExp(r"\B#\w\w+");
      exp.allMatches(text).forEach((match) {
        String res = match.group(0).replaceAll("#", "");
        if (res != null) {
          print(res);
          hashTag = hashTag + res;
        }
      });
    }

    if (longDesTECtl.text.toString().isNotEmpty) {
      String text = longDesTECtl.text.toString();
      RegExp exp = new RegExp(r"\B#\w\w+");
      exp.allMatches(text).forEach((match) {
        String res = match.group(0).replaceAll("#", "");
        if (res != null) {
          print(res);
          hashTag = hashTag + res;
        }
      });
    }

    hashTag = hashTag + displayNameTECtl.text.toString() + email;
    hashTag = hashTag.replaceAll(' ', '');
    return hashTag;
  }

}
