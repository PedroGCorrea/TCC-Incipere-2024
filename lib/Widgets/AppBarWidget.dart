import 'package:flutter/material.dart';
import 'package:incipere/Pages/ProfilePage.dart';
import 'package:incipere/Widgets/CustomSwitch.dart';
import 'package:incipere/Widgets/MenuProfileWidget.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    leading: const BackButton(),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: [CustomSwitch()],
  );
}

AppBar buildHomeAppBar(BuildContext context, String title) {
  return AppBar(
    leading: const BackButton(),
    title: Text(title),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: [
      CustomSwitch(),
      Container(
        margin: const EdgeInsets.only(right: 20.0),
      ),
      MenuProfileWidget(
        imagePath: "profile.png",
        onClicked: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        },
      ),
      Container(
        margin: const EdgeInsets.only(right: 20.0),
      ),
    ],
  );
}
