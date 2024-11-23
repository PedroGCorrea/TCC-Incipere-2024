// ignore: file_names
import 'package:flutter/material.dart';
import 'package:incipere/Utils/UserPreferences.dart';

class AppControler extends ChangeNotifier {
  bool darkTheme = UserPreferences.myUser.isDarkMode;

  static AppControler instace = AppControler();

  changeTheme() {
    darkTheme = !darkTheme;
    notifyListeners();
  }
}
