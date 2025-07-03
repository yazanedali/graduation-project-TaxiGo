import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Taxi App with Google Maps',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: TaxiMapScreen(),
//     );
//   }
// }

class MapScreen extends StatefulWidget {
  @override
  _TaxiMapScreenState createState() => _TaxiMapScreenState();
}

class _TaxiMapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Location _location = Location();
  LatLng _currentLocation = LatLng(0, 0);
  LatLng _destination = LatLng(37.7749, -122.4194); // مثال: سان فرانسيسكو
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  PolylinePoints _polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
    });
    _addMarker(_currentLocation, 'موقعك الحالي');
    _addMarker(_destination, 'الوجهة');
    _getRoute();
  }

  void _addMarker(LatLng position, String title) {
    _markers.add(Marker(
      markerId: MarkerId(title),
      position: position,
      infoWindow: InfoWindow(title: title),
    ));
  }

  Future<void> _getRoute() async {
    String url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=AIzaSyAiI9plG4Q_kvQ5n6YLSWVY0867lLlOywc&start=${_currentLocation.longitude},${_currentLocation.latitude}&end=${_destination.longitude},${_destination.latitude}';
    
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body);
    var route = data['features'][0]['geometry']['coordinates'];
    
    List<LatLng> polylineCoordinates = [];
    for (var point in route) {
      polylineCoordinates.add(LatLng(point[1], point[0]));
    }

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Taxi Map with Google Maps')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 14.0,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}
