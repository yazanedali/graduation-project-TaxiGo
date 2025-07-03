import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: SelectTransportScreen(),
    );
  }
}

// class SelectLocationScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Select Address')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 labelText: 'Enter address',
//                 labelStyle: TextStyle(color: Colors.black),
//                 border: OutlineInputBorder(),
//                 filled: true,
//                 fillColor: Colors.yellow[50],
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.black, backgroundColor: Colors.yellow,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
//                 elevation: 5,
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => SelectTransportScreen(),
//                   ),
//                 );
//               },
//               child: Text('Confirm Location', style: TextStyle(fontSize: 16)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class SelectTransportScreen extends StatelessWidget {
  final List<Map<String, String>> transportOptions = [
    {'name': 'Bike', 'icon': '🚲'},
    {'name': 'Cab', 'icon': '🚖'},
    {'name': 'Luxury', 'icon': '🚘'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Your Transport')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // For Web: Use Grid
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1,
              ),
              itemCount: transportOptions.length,
              itemBuilder: (context, index) {
                return TransportCard(
                  name: transportOptions[index]['name']!,
                  icon: transportOptions[index]['icon']!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleListScreen(),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            // For Mobile: Use ListView
            return ListView.builder(
              itemCount: transportOptions.length,
              itemBuilder: (context, index) {
                return TransportCard(
                  name: transportOptions[index]['name']!,
                  icon: transportOptions[index]['icon']!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleListScreen(),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class TransportCard extends StatelessWidget {
  final String name;
  final String icon;
  final VoidCallback onTap;

  TransportCard({required this.name, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.yellow[100],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleListScreen extends StatelessWidget {
  final List<Map<String, String>> vehicles = [
    {'name': 'Basic Cab', 'price': '\$10'},
    {'name': 'Mustang Shelby GT', 'price': '\$25'},
    {'name': 'Jaguar Silver', 'price': '\$30'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Available Cars for Ride')),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(vehicles[index]['name']!),
              subtitle: Text('Price: ${vehicles[index]['price']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(),
                    ),
                  );
                },
                child: Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.yellow,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BookingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirm Booking')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text('Thank You! Your ride is confirmed.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Colors.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
