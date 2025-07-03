import 'package:flutter/material.dart';
import 'package:taxi_app/models/taxi_office.dart';

class OfficeMarker extends StatelessWidget {
  final TaxiOffice office;

  const OfficeMarker({Key? key, required this.office}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize:
          MainAxisSize.min, // Ensures Column takes minimal vertical space
      children: [
        // 1. Icon Container
        Container(
          padding: const EdgeInsets.all(4), // Reduced padding from 6 to 4
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi,
            color: Colors.blue,
            size: 24, // Reduced icon size from 30 to 24
          ),
        ),
        // Add a small SizedBox for spacing between icon and text (optional, but good practice)
        const SizedBox(height: 2), // Small vertical space

        // 2. Text Container
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical:
                  2), // Reduced vertical padding from 4 to 2, horizontal from 8 to 6
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            office.name,
            style: const TextStyle(
              fontSize: 10, // Reduced font size from 12 to 10
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center, // Center text within its container
            maxLines: 1, // Crucial: Ensures text doesn't wrap to multiple lines
            overflow: TextOverflow.ellipsis, // Adds "..." if text is too long
          ),
        ),
      ],
    );
  }
}
