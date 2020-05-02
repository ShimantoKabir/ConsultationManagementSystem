import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class EditCustomerProfile extends StatefulWidget {
  final String uid;

  EditCustomerProfile({Key key, @required this.uid}) : super(key: key);

  @override
  EditCustomerProfileState createState() =>
      new EditCustomerProfileState(uid: uid);
}

class EditCustomerProfileState extends State<EditCustomerProfile> {

  EditCustomerProfileState({Key key, @required this.uid});

  TextEditingController displayNameTECtl = TextEditingController();
  TextEditingController shortDesTECtl = TextEditingController();
  TextEditingController longDesTECtl = TextEditingController();
  TextEditingController phoneNumberTECtl = TextEditingController();
  TextEditingController coronaExpTECtl = TextEditingController();

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
  int quality = 100;
  int maxHeight = 500;
  int maxWidth = 600;
  String tempDir;
  String filePath;
  String email;

  final flutterVideoCompress = FlutterVideoCompress();

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => tempDir = d.path);

    Firestore.instance
        .collection('userInfoList')
        .document(uid)
        .get()
        .then((doc) {

      email = (doc['email'] == null) ? '' : doc['email'];
      displayNameTECtl.text = doc['displayName'];
      phoneNumberTECtl.text = doc['phoneNumber'];
      shortDesTECtl.text = doc['shortDescription'];
      longDesTECtl.text = doc['longDescription'];
      coronaExpTECtl.text = doc['coronavirusExperience'];

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
                              Row(
                                children: <Widget>[
                                  Padding(
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
                                      )),
                                  InkWell(
                                    onTap: () {

                                      showAlertDialog(
                                          context, "Image uploading please wait...!");

                                      setState(() {
                                        fileType = 'image';
                                      });
                                      
                                      String uuid = new Uuid().v1();

                                      pickFile(context, uuid).then((imUrl) async {

                                        Firestore.instance.collection("userInfoList")
                                        .document(uid).updateData({
                                          'photoUrl' : imUrl
                                        }).then((im){
                                          MySharedPreferences.setStringValue('photoUrl', imUrl).then((sp){
                                            Navigator.of(context, rootNavigator: true).pop();
                                          });
                                        });

                                      });
                                      
                                    },
                                    child: Icon(Icons.camera_alt),
                                  )
                                ],
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                margin:
                                EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                                child: Text("Corona Virus Experience",
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
                                    controller: coronaExpTECtl,
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
                                    } else {

                                      showAlertDialog(context,"Saving information.");

                                      Firestore.instance
                                          .collection('userInfoList')
                                          .document(uid)
                                          .updateData({
                                        'displayName':
                                        displayNameTECtl.text.toString(),
                                        'phoneNumber': phoneNumberTECtl.text,
                                        'shortDescription': (shortDesTECtl.text
                                            .isEmpty)
                                            ? null
                                            : shortDesTECtl.text,
                                        'longDescription': (longDesTECtl.text
                                            .isEmpty)
                                            ? null
                                            : longDesTECtl.text,
                                        'coronavirusExperience': (coronaExpTECtl.text
                                            .isEmpty)
                                            ? null
                                            : coronaExpTECtl.text,
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
                      .orderBy('timeStamp', descending: true)
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
        futureFileUrl = uploadFile(file, fileName,uuid);
      }
      if (fileType == 'audio') {
        file = await FilePicker.getFile(type: FileType.audio);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName,uuid);
      }
      if (fileType == 'video') {
        file = await FilePicker.getFile(type: FileType.video);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName,uuid);
      }
      if (fileType == 'pdf') {
        file = await FilePicker.getFile(
            type: FileType.custom, fileExtension: 'pdf');
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName,uuid);
      }
      if (fileType == 'others') {
        file = await FilePicker.getFile(type: FileType.any);
        fileName = uuid + p.extension(file.path);
        setState(() {
          fileName = uuid + p.extension(file.path);
        });
        futureFileUrl = uploadFile(file, fileName,uuid);
      }
    } on Exception catch (e) {
      print(e.toString());
      futureFileUrl = null;
    }
    return futureFileUrl;
  }

  Future<String> uploadFile(File file, String filename, String uuid) async {

    MySharedPreferences.setBooleanValue("isUploadRunning", true);

    print("file type = $fileType");

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

    StreamSubscription<StorageTaskEvent> streamSubscription;

    if (fileType == 'video') {
      file.length().then((val) {
        print("file lenght = $val");

        streamSubscription = uploadTask.events.listen((event) {
          print('bytesTransferred = ${event.snapshot.bytesTransferred}');
          DocumentReference dr = Firestore.instance
              .collection('userInfoList')
              .document(uid)
              .collection("videoThumbnailUrlList")
              .document(uuid);

          double x = (event.snapshot.bytesTransferred / val) * 100;

          dr.get().then((doc) {
            if (doc.exists) {
              dr.updateData({'progress': x.round()});
              if (x.round() == 100) {
                MySharedPreferences.setBooleanValue("isUploadRunning", false);
              }
            }
          });
        });
      });
    }

    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());

    if (streamSubscription != null) {
      streamSubscription.cancel();
    }

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
            MySharedPreferences.getBooleanValue("isUploadRunning")
                .then((isUploadRunning) {
              print("on pressed => is upload running = $isUploadRunning");

              if (isUploadRunning) {
                Fluttertoast.showToast(
                    msg: "Video/Image upload running, please wait!");
              } else {
                if (ft == "vd") {
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

                      // step 1. pick video from device
                      FilePicker.getFile(type: FileType.video)
                          .then((pickedFile) {
                        if (pickedFile != null) {
                          String vdName = uuid + p.extension(pickedFile.path);

                          // step 2. set data in fireStore
                          cr.document(uuid).setData({
                            'uuid': uuid,
                            'videoPath': "videos/" + vdName,
                            'videoUrl': null,
                            'progress': null,
                            'thmUrl': null,
                            'thmPath': null,
                            'timeStamp' : DateTime.now().millisecondsSinceEpoch
                          }).then((data) {
                            // step 3. extract thumbnail from video
                            VideoThumbnail.thumbnailFile(
                                video: pickedFile.path,
                                thumbnailPath: tempDir,
                                imageFormat: format,
                                maxWidth: maxWidth,
                                maxHeight: maxHeight,
                                quality: quality)
                                .then((thmImg) {
                              setState(() {
                                fileType = 'image';
                              });

                              File thmFile = new File(thmImg);
                              String thmName = uuid + p.extension(thmFile.path);

                              // step 4. upload thumbnail to storage
                              uploadFile(File(thmImg), thmName, uuid)
                                  .then((thmUrl) {
                                // step 5. update doc by thm url and thm name
                                cr.document(uuid).updateData({
                                  'thmUrl': thmUrl,
                                  'thmPath': "images/" + thmName,
                                }).then((val) {
                                  print("thm uploaded. video upload started");

                                  // step 6. compress video
                                  flutterVideoCompress
                                      .compressVideo(pickedFile.path,
                                      quality: VideoQuality.HighestQuality,
                                      deleteOrigin: false)
                                      .then((compressVideo) {
                                    print(
                                        "compressed file = ${compressVideo.path}");

                                    setState(() {
                                      fileType = 'video';
                                    });

                                    // step 6. upload video
                                    uploadFile(compressVideo.file, vdName, uuid)
                                        .then((vdUrl) {
                                      // step 7. update doc by video url
                                      cr.document(uuid).get().then((val) {
                                        if (val.exists) {
                                          cr
                                              .document(uuid)
                                              .updateData({'videoUrl': vdUrl});
                                          print("Video upload successful");
                                        }
                                      });
                                    });
                                  });
                                });
                              });
                            });
                          });
                        } else {
                          Fluttertoast.showToast(
                              msg: "No file has been selected!");
                        }

                        print(pickedFile);
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
                          msg: "Image uploading limit has been finished!");
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
              }
            });

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
        child: Column(children: <Widget>[
          Container(
            margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
            child: Center(
                child: Visibility(
                  visible: ft == "vd" && document['videoUrl'] == null,
                  child: showImageUploadLoader(document),
                )),
            height: 300,
            width: MediaQuery.of(context).size.width - 20.0,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: getThmImg(imgUrl), fit: BoxFit.cover)),
          ),
          Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    )),
              ),
              child: ButtonBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Center(
                      child: InkWell(
                        child: Icon(Icons.touch_app, color: Colors.black),
                        onTap: () {},
                      )),
                  Center(
                      child: InkWell(
                        child: Icon(Icons.delete, color: Colors.black),
                        onTap: () {
                          showAlertDialog(context, alertMsg);
                          if (ft == "vd") {
                            FirebaseStorage.instance
                                .ref()
                                .child(document['videoPath'])
                                .getDownloadURL()
                                .then((url) {
                              print("url = $url");
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
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  });
                                });
                              });
                            }, onError: (err) {
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
                          } else {
                            FirebaseStorage.instance
                                .ref()
                                .child(document['path'])
                                .getDownloadURL()
                                .then((url) {
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
                            }, onError: (err) {
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
                      ))
                ],
              ))
        ])
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

  String getProgress(document) {
    if (document['progress'] == null) {
      return "0%";
    } else {
      return document['progress'].toString() + "%";
    }
  }

  getPercent(document) {
    if (document['progress'] == null) {
      print("progress = ${document['progress']}");

      return 0.0;
    } else {
      return document['progress'] / 100;
    }
  }

  getThmImg(String imgUrl) {

    if (imgUrl == null) {

      return AssetImage("assets/images/vid_tmp_img.jpg");

    }else {

      print("image url = $imgUrl");
      return NetworkImage(imgUrl);

    }

  }

  showImageUploadLoader(document) {

    if(document['progress'] == null){

      return CircularProgressIndicator();

    }else {
      return CircularPercentIndicator(
        radius: 50.0,
        lineWidth: 5.0,
        percent: getPercent(document),
        center: new Text(getProgress(document),
            style: TextStyle(color: Colors.white)),
        progressColor: Colors.green,
      );
    }

  }

}
