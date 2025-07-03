import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String assetPath;

  const SocialButton({
    Key? key,
    required this.assetPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
      ),
      child: Image.asset(assetPath, width: 30, height: 30),
    );
  }
}
