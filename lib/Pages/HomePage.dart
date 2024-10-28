import 'package:flutter/material.dart';
import 'package:incipere/Model/post.dart';
import 'package:incipere/Widgets/AppBarWidget.dart';
import 'package:incipere/Widgets/PostBuilder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  final posts = List<Post>.filled(
      10, const Post(imagePath: 'photoTest.jpg', width: 200, height: 200),
      growable: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildHomeAppBar(context, "Incipere"),
      body: buildPosts(context, posts),
    );
  }
}
