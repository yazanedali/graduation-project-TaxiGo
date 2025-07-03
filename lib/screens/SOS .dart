import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _isLoading = false;
  String? _currentLocation;

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getLocationAndShare();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permission is required for SOS.")),
      );
    }
  }

  Future<void> _getLocationAndShare() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLocation = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
      _showContactSelection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location. Please try again.")),
      );
    }
    setState(() => _isLoading = false);
  }

  void _showContactSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Contact to Share Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.person),
                title: Text("Emergency Contact 1"),
                onTap: () => _shareLocation("Emergency Contact 1"),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text("Emergency Contact 2"),
                onTap: () => _shareLocation("Emergency Contact 2"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              )
            ],
          ),
        );
      },
    );
  }

  void _shareLocation(String contact) {
    if (_currentLocation != null) {
      Share.share("Emergency! My live location: $_currentLocation \nSending to: $contact");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Assistance"),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Press SOS in case of emergency", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(50),
                    ),
                    onPressed: _requestLocationPermission,
                    child: Icon(Icons.sos, size: 50, color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }
}
