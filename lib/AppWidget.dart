import 'package:flutter/material.dart';
import 'package:incipere/AppControler.dart';
import 'package:incipere/CreateAccountPage.dart';
import 'package:incipere/HomePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incipere/LoginPage.dart';

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
              fontFamily: GoogleFonts.montserrat().fontFamily,
              primarySwatch: Colors.red,
              brightness: AppControler.instace.darkTheme
                  ? Brightness.dark
                  : Brightness.light),
          home: LoginPage(),
        );
      },
    );
  }
}
