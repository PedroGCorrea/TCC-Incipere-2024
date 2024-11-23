import 'package:flutter/material.dart';
import 'package:incipere/App/AppWidget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  //Supabase setup

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://hmedlzrprzpgnnmqyfyz.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtZWRsenJwcnpwZ25ubXF5Znl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIzODc3MzgsImV4cCI6MjA0Nzk2MzczOH0.6YcFtN9Cg4cyXX27E7hd6MQXMZY2NRkNmQN4CzLgHTY",
  );

  //RunApp

  runApp(const AppWidget());
}
