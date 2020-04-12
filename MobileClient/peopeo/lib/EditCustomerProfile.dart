import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => tempDir = d.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          title: Text("Edit Profile",
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Armata',
                  fontWeight: FontWeight.bold)),
          centerTitle: true),
      body: SingleChildScrollView(
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
                      child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Container(
                            height: 150.0,
                            width: 150.0,
                            decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              image: new DecorationImage(
                                  fit: BoxFit.fill,
                                  image: NetworkImage(
                                      snapshot.data.documents[0]['photoUrl'])),
                            ),
                          )),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                          decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.fromLTRB(15.0, 5.0, 5.0, 5.0),
                              border: OutlineInputBorder(),
                              labelText:
                                  getDisplayName(snapshot.data.documents[0])),
                          controller: displayNameTECtl,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                          decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.fromLTRB(15.0, 5.0, 5.0, 5.0),
                              border: OutlineInputBorder(),
                              labelText:
                                  getPhoneNumber(snapshot.data.documents[0])),
                          controller: phoneNumberTECtl,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                          decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.fromLTRB(15.0, 5.0, 5.0, 5.0),
                              border: OutlineInputBorder(),
                              labelText: getShortDescription(
                                  snapshot.data.documents[0])),
                          controller: shortDesTECtl,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                          decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.fromLTRB(15.0, 5.0, 5.0, 5.0),
                              border: OutlineInputBorder(),
                              labelText: getLongDescription(
                                  snapshot.data.documents[0])),
                          controller: longDesTECtl,
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.all(10.0),
                      child: OutlineButton(
                        child: Text("SAVE",
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Armata',
                            )),
                        onPressed: () {
                          if (displayNameTECtl.text.isEmpty) {
                            Fluttertoast.showToast(
                                msg: "Display name required!");
                          } else {
                            Firestore.instance
                                .collection('userInfoList')
                                .document(uid)
                                .updateData({
                              'displayName': (displayNameTECtl.text.toString().isEmpty) ? null : displayNameTECtl.text.toString(),
                              'phoneNumber': (phoneNumberTECtl.text.toString().isEmpty) ? null : phoneNumberTECtl.text.toString(),
                              'shortDescription': (shortDesTECtl.text.toString().isEmpty) ? null : shortDesTECtl.text.toString(),
                              'longDescription': (longDesTECtl.text.toString().isEmpty) ? null : longDesTECtl.text.toString(),
                            });
                          }
                        },
                      ),
                    ),
                    Container(
                      height: 200,
                      child: StreamBuilder(
                        stream: Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection("imageUrlList")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                            );
                          } else {
                            return ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemBuilder: (context, index) => buildItem(
                                  context,
                                  snapshot.data.documents[index],
                                  'im'),
                              itemCount: snapshot.data.documents.length,
                            );
                          }
                        },
                      ),
                    ),
                    Center(
                      child: OutlineButton(
                        child: Text('Pick Image To Upload'),
                        onPressed: () {
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

                                Navigator.pop(context);
                              });
                            }
                          });
                        },
                      ),
                    ),
                    Container(
                      height: 200,
                      child: StreamBuilder(
                        stream: Firestore.instance
                            .collection('userInfoList')
                            .document(uid)
                            .collection("videoThumbnailUrlList")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                            );
                          } else {
                            return ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemBuilder: (context, index) => buildItem(
                                  context,
                                  snapshot.data.documents[index],
                                  'vd'),
                              itemCount: snapshot.data.documents.length,
                            );
                          }
                        },
                      ),
                    ),
                    Center(
                      child: OutlineButton(
                        child: Text('Pick Video To Upload'),
                        onPressed: () {
                          showAlertDialog(
                              context, "Video uploading please wait...!");

                          CollectionReference cr = Firestore.instance
                              .collection('userInfoList')
                              .document(uid)
                              .collection("videoThumbnailUrlList");

                          cr.getDocuments().then((im) {
                            if (im.documents.length > 4) {
                              Fluttertoast.showToast(
                                  msg:
                                      "Video uploading limit has been finished!");
                            } else {
                              String uuid = new Uuid().v1();

                              // get video from device
                              FilePicker.getFile(type: FileType.video)
                                  .then((pickedFile) {
                                // upload the video
                                setState(() {
                                  fileType = 'video';
                                });
                                String vdName =
                                    uuid + p.extension(pickedFile.path);
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
                                    String thmName =
                                        uuid + p.extension(thmFile.path);
                                    // upload thumbnail img
                                    uploadFile(File(thmImg), thmName)
                                        .then((thmUrl) {
                                      cr.document(uuid).setData({
                                        'uuid': uuid,
                                        'videoPath': "videos/" + vdName,
                                        'videoUrl': vdUrl,
                                        'thmUrl': thmUrl,
                                        'thmPath': "images/" + thmName,
                                      });

                                      Navigator.pop(context);
                                    });
                                  });
                                });
                              });
                            }
                          });
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

  getDisplayName(document) {
    if (document['displayName'] == null) {
      return "Display Name Not Set Yet";
    } else {
      displayNameTECtl.text = document['displayName'].toString();
      return "Display Name";
    }
  }

  getShortDescription(document) {
    if (document['shortDescription'] == null) {
      return "Short Description";
    } else {
      shortDesTECtl.text = document['shortDescription'].toString();
      return "Short Description";
    }
  }

  getLongDescription(document) {
    if (document['longDescription'] == null) {
      return "Long Discription";
    } else {
      longDesTECtl.text = document['longDescription'].toString();
      return "Long Discription";
    }
  }

  getPhoneNumber(document) {
    if (document['phoneNumber'] == null) {
      return "Phone Number Not Set Yet (Optional)";
    } else {
      phoneNumberTECtl.text = document['phoneNumber'].toString();
      return "Phone Number";
    }
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

  Widget buildItem(BuildContext context, document, String fileType) {

    String imgUrl;
    String collectionName;
    String alertMsg;

    if (fileType == "vd") {
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
          Image.network(
              imgUrl,
              fit:BoxFit.cover
          ),
          ButtonBar(
            buttonHeight: 10.0,
            children: <Widget>[
              FlatButton(
                child: const Text('BUY TICKETS'),
                onPressed: () { /* ... */ },
              ),
              FlatButton(
                child: const Text('LISTEN'),
                onPressed: () { /* ... */ },
              ),
            ],
          ),
        ],
      ),
    );

//    return ListTile(
//      leading: Image.network(
//          imgUrl,
//          fit:BoxFit.cover
//      ),
//      trailing: IconButton(
//        icon: Icon(Icons.delete),
//        onPressed: () {
//          showAlertDialog(context, alertMsg);
//          if (fileType == "vd") {
//            FirebaseStorage.instance
//                .ref()
//                .child(document['videoPath'])
//                .delete()
//                .then((v) {
//              FirebaseStorage.instance
//                  .ref()
//                  .child(document['thmPath'])
//                  .delete()
//                  .then((t) {
//                Firestore.instance
//                    .collection('userInfoList')
//                    .document(uid)
//                    .collection(collectionName)
//                    .document(document['uuid'])
//                    .delete()
//                    .then((du) {
//                  Navigator.pop(context);
//                });
//              });
//            });
//          } else {
//            FirebaseStorage.instance
//                .ref()
//                .child(document['path'])
//                .delete()
//                .then((df) {
//              Firestore.instance
//                  .collection('userInfoList')
//                  .document(uid)
//                  .collection(collectionName)
//                  .document(document['uuid'])
//                  .delete()
//                  .then((du) {
//                Navigator.pop(context);
//              });
//            });
//          }
//        },
//      ),
//    );

  }
}
