import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text("Test Web View"),
        ),
        body: WebView(
          initialUrl: "",
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) async {
            _controller = _controller;
            await loadHtmlFromAssets('http://172.16.2.222/consultant/calendar.html?uid=1234', _controller);
          },
        ));



  }

  Future<void> loadHtmlFromAssets(String filename, controller) async {
    String fileText = await rootBundle.loadString(filename);
    controller.loadUrl(Uri.dataFromString(fileText, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString());
  }

//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//          backgroundColor: Colors.white,
//          centerTitle: true,
//          leading: Padding(
//            padding: EdgeInsets.all(10.0),
//            child: Container(
//              height: 10.0,
//              width: 10.0,
//              decoration: new BoxDecoration(
//                shape: BoxShape.circle,
//                image: new DecorationImage(
//                    fit: BoxFit.fill,
//                    image: new NetworkImage(
//                        "https://pbs.twimg.com/profile_images/916384996092448768/PF1TSFOE_400x400.jpg")),
//              ),
//            ),
//          ),
//          title: Text(
//            "Consultants",
//            style: TextStyle(
//                color: Colors.black,
//                fontFamily: 'Armata',
//                fontWeight: FontWeight.bold),
//          ),
//          actions: <Widget>[
//            IconButton(
//              icon: Icon(Icons.notification_important),
//              onPressed: null,
//            )
//          ]),
//      body: ListView.builder(
//          itemCount: 5,
//          itemBuilder: (context, index) =>
//              Container(
//                decoration: myBoxDecoration(),
//                child: Column(
//                  mainAxisAlignment: MainAxisAlignment.start,
//                  mainAxisSize: MainAxisSize.min,
//                  crossAxisAlignment: CrossAxisAlignment.stretch,
//                  children: <Widget>[
//                    Padding(
//                      padding: const EdgeInsets.all(5.0),
//                      child: Row(
//                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                        children: <Widget>[
//                          IconButton(
//                            icon: Icon(Icons.favorite, color: Colors.red),
//                            onPressed: () {},
//                          ),
//                          IconButton(
//                            icon: Icon(Icons.bookmark),
//                            onPressed: () {},
//                          )
//                        ],
//                      ),
//                    ),
//                    Divider(
//                      height: 0.0,
//                      thickness: 1.0,
//                    ),
//                    Padding(
//                      padding: const EdgeInsets.all(5.0),
//                      child: Row(
//                        children: <Widget>[
//                          Container(
//                            height: 100.0,
//                            width: 100.0,
//                            decoration: new BoxDecoration(
//                              shape: BoxShape.circle,
//                              image: new DecorationImage(
//                                  fit: BoxFit.fill,
//                                  image: new NetworkImage(
//                                      "https://pbs.twimg.com/profile_images/916384996092448768/PF1TSFOE_400x400.jpg")),
//                            ),
//                          ),
//                          Expanded(
//                            child: Column(
//                              children: <Widget>[
//                                Row(
//                                  mainAxisAlignment:
//                                  MainAxisAlignment.spaceAround,
//                                  children: <Widget>[
//                                    Column(
//                                      children: <Widget>[
//                                        IconButton(
//                                          icon: Icon(Icons.thumb_up),
//                                          onPressed: () {},
//                                        ),
//                                        Text('120',
//                                            style: TextStyle(
//                                              fontSize: 12.0,
//                                              fontWeight: FontWeight.w600,
//                                              fontFamily: 'Armata',
//                                            ))
//                                      ],
//                                    ),
//                                    Column(
//                                      children: <Widget>[
//                                        IconButton(
//                                          icon: Icon(Icons.star),
//                                          onPressed: () {},
//                                        ),
//                                        Text('81%',
//                                            style: TextStyle(
//                                                fontSize: 12.0,
//                                                fontFamily: 'Armata',
//                                                fontWeight: FontWeight.w600))
//                                      ],
//                                    ),
//                                    Column(
//                                      children: <Widget>[
//                                        IconButton(
//                                          icon: Icon(Icons.attach_money),
//                                          onPressed: () {},
//                                        ),
//                                        Text(r'5 $/H',
//                                            style: TextStyle(
//                                                fontSize: 12.0,
//                                                fontFamily: 'Armata',
//                                                fontWeight: FontWeight.w600))
//                                      ],
//                                    )
//                                  ],
//                                ),
//                                Padding(
//                                  padding: const EdgeInsets.all(10.0),
//                                  child: Text(
//                                    "[15 minute's free for new customer]",
//                                    style: TextStyle(
//                                      color: Colors.green,
//                                      fontFamily: "Armata"
//                                    ),
//                                  ),
//                                )
//                              ],
//                            ),
//                          )
//                        ],
//                      ),
//                    ),
//                    Padding(
//                      padding: const EdgeInsets.all(5.0),
//                      child: Column(
//                        mainAxisAlignment: MainAxisAlignment.start,
//                        mainAxisSize: MainAxisSize.min,
//                        crossAxisAlignment: CrossAxisAlignment.stretch,
//                        children: <Widget>[
//                          Text(
//                            "Shahariar kabir",
//                            textAlign: TextAlign.left,
//                            style: TextStyle(
//                              fontSize: 18.0,
//                              color: Colors.black,
//                              fontWeight: FontWeight.bold,
//                              fontFamily: 'Armata',
//                            ),
//                          ),
//                          SizedBox(
//                            height: 10.0,
//                          ),
//                          Text(
//                            "Lorem ipsum dolor sit amet, consectetur adipisicing elit.",
//                            style: TextStyle(
//                              fontSize: 15.0,
//                              color: Colors.black54,
//                              fontWeight: FontWeight.bold,
//                              fontFamily: 'Armata',
//                            ),
//                          ),
//                          SizedBox(
//                            height: 10.0,
//                          ),
//                          Text(
//                            "Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aspernatur cum cumque distinctio facilis quibusdam quod repellat saepe sapiente sunt! Illum itaque modi nesciunt officia perspiciatis, quia similique vel vero voluptatibus.",
//                            style: TextStyle(
//                              fontSize: 15.0,
//                              color: Colors.grey,
//                              fontWeight: FontWeight.bold,
//                              fontFamily: 'Armata',
//                            ),
//                          ),
//                          SizedBox(
//                            height: 10.0,
//                          )
//                        ],
//                      ),
//                    ),
//                    Divider(
//                      height: 0.0,
//                      thickness: 1.0,
//                    ),
//                    Padding(
//                      padding: const EdgeInsets.all(6.0),
//                      child: Row(
//                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                        children: <Widget>[
//                          RaisedButton(
//                            shape: new RoundedRectangleBorder(
//                                borderRadius: new BorderRadius.circular(8.0),
//                                side: BorderSide(color: Colors.red)),
//                            onPressed: () {},
//                            color: Colors.red,
//                            textColor: Colors.white,
//                            child: Text("Buy now".toUpperCase(),
//                                style: TextStyle(fontSize: 14)),
//                          ),
//                          RaisedButton(
//                            shape: new RoundedRectangleBorder(
//                                borderRadius: new BorderRadius.circular(8.0),
//                                side: BorderSide(color: Colors.red)),
//                            onPressed: () {},
//                            color: Colors.red,
//                            textColor: Colors.white,
//                            child: Text("Buy now".toUpperCase(),
//                                style: TextStyle(fontSize: 14)),
//                          )
//                        ],
//                      ),
//                    ),
//                  ],
//                ),
//              )
//      ),
//      bottomNavigationBar: Container(
//        color: Colors.white,
//        height: 50.0,
//        alignment: Alignment.center,
//        child: new BottomAppBar(
//          child: Row(
//            mainAxisAlignment: MainAxisAlignment.spaceAround,
//            children: <Widget>[
//              IconButton(icon: Icon(Icons.home), onPressed: null),
//              IconButton(icon: Icon(Icons.search), onPressed: null),
//              IconButton(icon: Icon(Icons.account_box), onPressed: null),
//              IconButton(icon: Icon(Icons.favorite), onPressed: null),
//              IconButton(icon: Icon(Icons.bookmark), onPressed: null)
//            ],
//          ),
//        ),
//      ),
//    );
//  }
//
//  BoxDecoration myBoxDecoration() {
//    return BoxDecoration(
//        border: Border.all(
//            color: Colors.grey,
//            width: 1.0)
//    );
//  }

}
