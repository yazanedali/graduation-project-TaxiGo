import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  OnboardingPage({required this.image, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 250),
        SizedBox(height: 20),
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(description, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
