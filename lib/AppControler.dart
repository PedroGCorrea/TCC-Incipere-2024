// ignore: file_names
import 'package:flutter/material.dart';

class AppControler extends ChangeNotifier {
  bool darkTheme = false;

  static AppControler instace = AppControler();

  changeTheme() {
    darkTheme = !darkTheme;
    notifyListeners();
  }
}
