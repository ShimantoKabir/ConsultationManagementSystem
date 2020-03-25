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
        title: Text('Video Player'),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          });
        },
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
