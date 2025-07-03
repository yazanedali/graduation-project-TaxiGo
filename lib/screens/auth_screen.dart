import 'package:flutter/material.dart';
import 'components/custom_auth_button.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In / Sign Up")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomAuthButton(
              text: "Create an Account",
              backgroundColor: Colors.yellow,
              textColor: Colors.black,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
              },
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignInScreen()));
              },
              child: Text("Login", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
