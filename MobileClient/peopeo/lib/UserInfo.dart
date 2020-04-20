class UserInfo {

  String uid;
  String displayName;
  String email;
  String hashTag;
  String token;
  int userType;
  String photoUrl;

  UserInfo({
    this.uid,
    this.displayName,
    this.email,
    this.hashTag,
    this.token,
    this.userType,
    this.photoUrl
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
        uid: json['uid'],
        displayName: json['displayName'],
        email: json['email'],
        hashTag: json['hashTag'],
        token: json['token'],
        userType: json['userType'],
        photoUrl: json['photoUrl']);
  }

}
