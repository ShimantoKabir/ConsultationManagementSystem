import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:peopeo/AuthManager.dart';
import 'package:peopeo/Const.dart';
import 'package:peopeo/HttpResponse.dart';
import 'package:peopeo/Plan.dart';

class PlanManager{

  static Future<List<Plan>> getPlanList(Map<String, dynamic> userInfo) async {

    List<Plan> reviewAndRatingList = [];


    String authId = await AuthManager.init();

    print("go");

    if(authId == null){

      Fluttertoast.showToast(msg: "Auth initialization error.");

    }else {

      String url = serverBaseUrl + '/plan/get-review-and-rating';
      Map<String, String> headers = {"Content-type": "application/json"};

      var request;

      if(userInfo['userType'] == 1){

        request = {
          'plan': {
            'cusUid': userInfo['uid'],
            'userType': 1
          },
          'authId' : authId,
          'uid' : userInfo['uid']
        };

      }else {

        request = {
          'plan': {
            'conUid': userInfo['uid'],
            'userType': 2
          },
          'authId' : authId,
          'uid' : userInfo['uid']
        };

      }

      Response response =
      await post(url, headers: headers, body: json.encode(request));

      print("review and rating response = ${response.body}");

      if (response.statusCode == 200) {

        var body = json.decode(response.body);

        if (body['code'] == 200) {
          reviewAndRatingList = HttpResponse.fromJson(body).planList;
        }

      } else {
        Fluttertoast.showToast(msg: "Plan list getting error!");
      }

    }

    return reviewAndRatingList;

  }

}