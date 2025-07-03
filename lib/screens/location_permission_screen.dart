import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'components/custom_dialog.dart';
import 'components/custom_auth_button.dart';
import 'auth_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  @override
  _LocationPermissionScreenState createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      CustomDialog.show(
        context,
        title: "Location Permission Required",
        content: "To continue, please enable location permission in settings.",
        buttonText: "OK",
        onPressed: () => Navigator.pop(context),
      );
    } else if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location Permission")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 100, color: Colors.yellow),
            SizedBox(height: 20),
            Text(
              "We need your location to find nearby rides.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            CustomAuthButton(
              text: "Allow Location",
              backgroundColor: Colors.amber,
              textColor: Colors.white,
              onPressed: _requestLocationPermission,
            ),
          ],
        ),
      ),
    );
  }
}
