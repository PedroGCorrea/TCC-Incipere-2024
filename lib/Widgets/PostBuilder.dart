import 'package:flutter/material.dart';
import 'package:incipere/App/AppControler.dart';
import 'package:incipere/Model/post.dart';

Widget buildPosts(BuildContext context, List<Post> posts) {
  return ListView.builder(
    itemCount: posts.length,
    itemBuilder: (context, index) {
      return Container(
        height: posts[index].height,
        width: posts[index].width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(posts[index].imagePath),
          ),
          shape: BoxShape.rectangle,
        ),
        margin: const EdgeInsets.only(top: 10.0),
      );
    },
  );
}
