import 'package:flutter/material.dart';
import 'package:incipere/AppControler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incipere"),
        backgroundColor: Colors.pinkAccent,
        actions: [CustomSwitch()],
      ),
    );
  }
}

class CustomSwitch extends StatelessWidget {
  const CustomSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: AppControler.instace.darkTheme,
      onChanged: (value) {
        AppControler.instace.changeTheme();
      },
      activeThumbImage: const AssetImage("darkTheme.png"),
      inactiveThumbImage: const AssetImage("ligthTheme.png"),
      activeColor: Colors.black,
      inactiveThumbColor: Colors.white,
      activeTrackColor: Colors.black,
      inactiveTrackColor: Colors.white,
    );
  }
}