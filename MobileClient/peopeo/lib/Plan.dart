import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Plan {
  int id;
  String topic;
  int calenderOid;
  String conUid;
  String cusUid;
  String startTime;
  String endTime;
  bool isAcceptByCon;
  String checkOutId;
  int freeMinutesForNewCustomer;
  int hourlyRate;
  int userType;
  int rating;
  String review;
  String fStartTime;
  String fEndTime;
  String timeZone;

  Plan(
      {this.id,
      this.topic,
      this.calenderOid,
      this.conUid,
      this.cusUid,
      this.startTime,
      this.endTime,
      this.isAcceptByCon,
      this.checkOutId,
      this.freeMinutesForNewCustomer,
      this.hourlyRate,
      this.userType,
      this.rating,
      this.review,
      this.fStartTime,
      this.fEndTime,
      this.timeZone});

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
        id: json['id'],
        topic: json['topic'],
        calenderOid: json['calenderOid'],
        conUid: json['conUid'],
        cusUid: json['cusUid'],
        startTime: json['startTime'],
        endTime: json['endTime'],
        isAcceptByCon: json['isAcceptByCon'],
        checkOutId: json['checkOutId'],
        freeMinutesForNewCustomer: json['freeMinutesForNewCustomer'],
        hourlyRate: json['hourlyRate'],
        userType: json['userType'],
        rating: json['rating'],
        review: json['review'],
        fStartTime: json['fStartTime'],
        fEndTime: json['fEndTime'],
        timeZone: json['timeZone']);
  }
}
