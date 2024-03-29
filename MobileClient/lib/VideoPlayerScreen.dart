import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  VideoPlayerScreen({Key key, @required this.url}) : super(key: key);
  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState(url: url);
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {

  VideoPlayerScreenState({Key key, @required this.url});

  final String url;
  VideoPlayerController controller;
  Future<void> initializeVideoPlayerFuture;

  @override
  void initState() {

    controller = VideoPlayerController.network(url);
    initializeVideoPlayerFuture = controller.initialize();
    controller.setLooping(true);

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: new Text(
            'Video',
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Armata',
                fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: <Widget>[
          Padding(
            child: Container(
              padding: const EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.all(Radius.circular(5.0) //
                  )),
              child: Center(
                child: InkWell(
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onTap: (){
                    setState(() {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    });
                  },
                )
              ),
            ),
            padding: EdgeInsets.all(5.0),
          )
        ],
      ),
      body: Center(
        child: FutureBuilder(
          future: initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      )
    );
  }
}
