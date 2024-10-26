import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:incipere/App/AppControler.dart';
import 'package:incipere/Pages/HomePage.dart';
import 'package:incipere/Pages/ProfilePage.dart';
import 'package:incipere/Widgets/ButtonWidget.dart';
import 'package:incipere/Widgets/CustomSwitch.dart';
import 'package:incipere/theme.dart';
import 'package:incipere/utils/userpreferences.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    leading: BackButton(),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: [CustomSwitch()],
  );
}

AppBar buildHomeAppBar(BuildContext context, String title) {
  return AppBar(
    leading: BackButton(),
    title: Text(title),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: [
      CustomSwitch(),
      ButtonWidget(
          text: "Perfil",
          onClicked: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => ProfilePage()));
          })
    ],
  );
}
