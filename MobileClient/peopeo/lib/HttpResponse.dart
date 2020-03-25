import 'package:peopeo/Plan.dart';

class HttpResponse {
  final int code;
  final String msg;
  final String aid;
  final String uid;
  final String clientToken;
  final List<Plan> planList;

  HttpResponse(
      {this.code,
      this.msg,
      this.aid,
      this.uid,
      this.clientToken,
      this.planList});

  factory HttpResponse.fromJson(Map<String, dynamic> json) {
    var list = json['planList'] as List;
    print(list.runtimeType);
    List<Plan> planList = list.map((i) => Plan.fromJson(i)).toList();

    return HttpResponse(
        code: json['code'],
        msg: json['msg'],
        aid: json['aid'],
        uid: json['uid'],
        clientToken: json['clientToken'],
        planList: planList);
  }
}
