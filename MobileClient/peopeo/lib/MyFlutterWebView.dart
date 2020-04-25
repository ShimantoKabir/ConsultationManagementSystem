import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class MyFlutterWebView extends StatefulWidget {
  final String title;
  final String url;

  MyFlutterWebView({
    Key key,
    @required this.title,
    @required this.url,
  });

  @override
  MyFlutterWebViewState createState() => MyFlutterWebViewState(title: title, url: url);
}

class MyFlutterWebViewState extends State<MyFlutterWebView> {

  MyFlutterWebViewState({Key key, @required this.title, @required this.url});

  String title;
  String url;

  final flutterWebViewPlugin = new FlutterWebviewPlugin();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    flutterWebViewPlugin.dispose(); // disposing the webview widget
  }

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
        url: url,
        withJavascript: true,
        withZoom: false,
        hidden: true,
        scrollBar: true,
        withLocalUrl: true,
        appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.black),
            backgroundColor: Colors.white,
            title: Text(title,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
            actions: <Widget>[
              Center(
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: InkWell(
                    child: Icon(Icons.refresh),
                    onTap: () {
                      flutterWebViewPlugin.reload();
                    },
                  ),
                ),
              )
            ]),
        initialChild: Container(
          color: Colors.white,
          child: const Center(
            child: Text('Please wait...'),
          ),
        ));
  }
}
