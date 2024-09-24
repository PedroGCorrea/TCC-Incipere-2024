import 'package:flutter/material.dart';
import 'package:incipere/AppControler.dart';
import 'package:incipere/HomePage.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppControler.instace,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              primarySwatch: Colors.red,
              brightness: AppControler.instace.darkTheme
                  ? Brightness.dark
                  : Brightness.light),
          home: HomePage(),
        );
      },
    );
  }
}
