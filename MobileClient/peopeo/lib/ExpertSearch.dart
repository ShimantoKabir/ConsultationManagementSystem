import 'dart:core';

import 'package:peopeo/ConsultantProfile.dart';
import 'package:peopeo/UserInfo.dart';
import 'package:flutter/material.dart';

class ExpertSearch extends SearchDelegate<String> {

  final List<UserInfo> userInfoList;

  ExpertSearch(this.userInfoList);

  @override
  List<Widget> buildActions(BuildContext context) {
    //Actions for app bar
    return [IconButton(icon: Icon(Icons.clear), onPressed: () {
      query = '';
    })];
  }

  @override
  Widget buildLeading(BuildContext context) {
    //leading icon on the left of the app bar
    return IconButton(
        icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        ),
        onPressed: () {
          close(context, null);
        });
  }

  @override
  Widget buildResults(BuildContext context) {
    // show some result based on the selection
    final suggestionList = userInfoList;

    return ListView.builder(itemBuilder: (context, index) => ListTile(

      title: Text(userInfoList[index].displayName),
      subtitle: Text(userInfoList[index].email),
    ),
      itemCount: suggestionList.length,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // show when someone searches for something

    final suggestionList = query.isEmpty
        ? userInfoList
        : userInfoList.where((p) => p.displayName.contains(RegExp(query, caseSensitive: false))).toList();

    return ListView.builder(itemBuilder: (context, index) => ListTile(
      onTap: () {

        print(suggestionList[index].uid);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ConsultantProfile(uid: suggestionList[index].uid);
            },
          ),
        );

      },
      trailing: Icon(Icons.arrow_right),
      title: RichText(
        text: TextSpan(
            text: suggestionList[index].displayName.substring(0, query.length),
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                  text: suggestionList[index].displayName.substring(query.length),
                  style: TextStyle(color: Colors.grey)),
            ]),
      ),
    ),
      itemCount: suggestionList.length,
    );
  }
}