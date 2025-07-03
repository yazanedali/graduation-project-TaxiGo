// import 'package:flutter/material.dart';
// import 'package:taxi_app/screens/Driver/driver_trips.dart';
// import 'package:url_launcher/url_launcher.dart';

// class DriverDetailsPage extends StatelessWidget {
//   final Map<String, String> driver;

//   const DriverDetailsPage({super.key, required this.driver});

//   void _callDriver(String phoneNumber) async {
//     final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
//     if (await canLaunchUrl(phoneUri)) {
//       await launchUrl(phoneUri);
//     } else {
//       print("❌ لا يمكن إجراء المكالمة");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool isWeb = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(driver["name"]!),
//         backgroundColor: Colors.yellow.shade700,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
//       ),
//     );
//   }

//   // 🎨 تصميم الويب
//   Widget _buildWebLayout(BuildContext context) {
//     return Center(
//       child: Card(
//         elevation: 10,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Container(
//           width: 900,
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               // 👤 صورة السائق
//               CircleAvatar(
//                 radius: 80,
//                 backgroundColor: Colors.yellow.shade700,
//                 child: Text(driver["name"]![0],
//                     style: const TextStyle(fontSize: 50, color: Colors.white)),
//               ),
//               const SizedBox(width: 30),

//               // 📋 معلومات السائق
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildDetailRow(
//                         Icons.phone, "رقم الهاتف", driver["phone"]!),
//                     _buildDetailRow(
//                         Icons.directions_car, "عدد الرحلات", driver["trips"]!),
//                     _buildDetailRow(Icons.attach_money, "إجمالي الأرباح",
//                         driver["earnings"]!),
//                     _buildDetailRow(Icons.star, "التقييم", "4.8 ⭐"),
//                     _buildDetailRow(
//                         Icons.access_time, "آخر رحلة", "قبل 2 ساعة"),
//                     _buildDetailRow(Icons.location_on, "الموقع الحالي",
//                         "رام الله - فلسطين"),
//                     _buildDetailRow(Icons.wifi, "حالة الإنترنت", "متصل ✅"),

//                     const SizedBox(height: 20),

//                     // 🔘 أزرار العمليات
//                     Row(
//                       children: [
//                         _buildButton(Icons.phone, "اتصل بالسائق", Colors.green,
//                             () => _callDriver(driver["phone"]!)),
//                         const SizedBox(width: 15),
//                         _buildButton(Icons.history, "سجل الرحلات",
//                             Colors.blueAccent, () => _navigateToTrips(context)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // 🎨 تصميم الموبايل
//   Widget _buildMobileLayout(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Center(
//           child: CircleAvatar(
//             radius: 50,
//             backgroundColor: Colors.yellow.shade700,
//             child: Text(driver["name"]![0],
//                 style: const TextStyle(fontSize: 30, color: Colors.white)),
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildDetailRow(Icons.phone, "رقم الهاتف", driver["phone"]!),
//         _buildDetailRow(Icons.directions_car, "عدد الرحلات", driver["trips"]!),
//         _buildDetailRow(
//             Icons.attach_money, "إجمالي الأرباح", driver["earnings"]!),
//         _buildDetailRow(Icons.star, "التقييم", "4.8 ⭐"),
//         _buildDetailRow(Icons.access_time, "آخر رحلة", "قبل 2 ساعة"),
//         _buildDetailRow(
//             Icons.location_on, "الموقع الحالي", "رام الله - فلسطين"),
//         _buildDetailRow(Icons.wifi, "حالة الإنترنت", "متصل ✅"),
//         const SizedBox(height: 20),
//         Center(
//           child: Column(
//             children: [
//               _buildButton(Icons.phone, "اتصل بالسائق", Colors.green,
//                   () => _callDriver(driver["phone"]!)),
//               const SizedBox(height: 10),
//               _buildButton(Icons.history, "سجل الرحلات", Colors.blueAccent,
//                   () => _navigateToTrips(context)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // 🎨 زر موحد
//   Widget _buildButton(
//       IconData icon, String text, Color color, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         textStyle: const TextStyle(fontSize: 18),
//       ),
//     );
//   }

//   // 🎨 دالة لإنشاء صف التفاصيل
//   Widget _buildDetailRow(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.yellow.shade700, size: 28),
//           const SizedBox(width: 10),
//           Text(title,
//               style:
//                   const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           const Spacer(),
//           Text(value,
//               style: const TextStyle(fontSize: 16, color: Colors.black54)),
//         ],
//       ),
//     );
//   }

//   // 📂 التنقل إلى سجل الرحلات
//   void _navigateToTrips(BuildContext context) {
//     List<Map<String, String>> sampleTrips = [
//       {
//         "date": "22-03-2025",
//         "distance": "12",
//         "duration": "20 دقيقة",
//         "fare": "15",
//         "status": "مدفوع",
//         "rating": "5⭐"
//       },
//       {
//         "date": "21-03-2025",
//         "distance": "8",
//         "duration": "15 دقيقة",
//         "fare": "10",
//         "status": "غير مدفوع",
//         "rating": "4.5⭐"
//       },
//       {
//         "date": "20-03-2025",
//         "distance": "20",
//         "duration": "30 دقيقة",
//         "fare": "25",
//         "status": "مدفوع",
//         "rating": "4⭐"
//       },
//     ];

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DriverTripsPage(driverId: 1),
//       ),
//     );
//   }
// }
