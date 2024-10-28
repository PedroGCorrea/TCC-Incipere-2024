import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MenuProfileWidget extends StatelessWidget {
  final String imagePath;
  final bool isEdit;
  final VoidCallback onClicked;

  const MenuProfileWidget({
    super.key,
    required this.imagePath,
    this.isEdit = false,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          buildImage(),
        ],
      ),
    );
  }

  Widget buildImage() {
    final image = AssetImage(imagePath);

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          width: 45,
          height: 45,
          child: InkWell(onTap: onClicked),
        ),
      ),
    );
  }
}
