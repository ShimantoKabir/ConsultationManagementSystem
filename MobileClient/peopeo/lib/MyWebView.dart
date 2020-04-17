import 'dart:async';
import 'package:flutter/material.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/MySharedPreferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebView extends StatefulWidget {
  final String title;
  final String url;

  MyWebView({
    Key key,
    @required this.title,
    @required this.url,
  });

  @override
  MyWebViewState createState() => new MyWebViewState(title: title, url: url);
}

class MyWebViewState extends State<MyWebView> {
  MyWebViewState({Key key, @required this.title, @required this.url});

  String title;
  String url;
  bool isPaymentSuccessful = false;

  final Completer<WebViewController> controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.black),
            backgroundColor: Colors.white,
            title: Text(title,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Armata',
                    fontWeight: FontWeight.bold)),
          ),
          body: WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                controller.complete(webViewController);
              },
              navigationDelegate: (NavigationRequest request) {
                if (request.url.startsWith(webClientBaseUrl + "/index.html")) {
                  print('blocking navigation to $request}');

                  String paymentStatus = request.url.split("/").last.split("=").last;
                  print("Payment status = $paymentStatus");
                  isPaymentSuccessful =
                      (paymentStatus == 'true') ? true : false;

                  MySharedPreferences.setBooleanValue(
                          'isPaymentSuccessful', isPaymentSuccessful)
                      .then((val) {
                    Navigator.of(context).pop(true);
                  });

                  // request.url
                  return NavigationDecision.prevent;
                }
                print('allowing navigation to $request');
                return NavigationDecision.navigate;
              })),
    );
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
            content: new Text('Do you want to leave?',
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
                    MySharedPreferences.setBooleanValue(
                            'isPaymentSuccessful', isPaymentSuccessful)
                        .then((val) {
                      Navigator.of(context).pop(true);
                    });
                  })
            ],
          ),
        ) ??
        false;
  }
}
