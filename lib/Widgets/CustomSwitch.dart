import 'package:flutter/material.dart';
import 'package:incipere/App/AppControler.dart';

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
