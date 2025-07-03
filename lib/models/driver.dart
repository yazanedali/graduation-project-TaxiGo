class Driver {
  final String id; // MongoDB ID
  final int driverUserId;
  final String fullName;
  final String? profileImageUrl;
  final String carModel;
  final String carColor;
  final String carPlateNumber;
  final int? carYear;
  final double rating;
  final int numberOfRatings;
  bool isAvailable;
  final String taxiOfficeId;
  final String phone;
  final String email;
  final double earnings;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final DateTime joinedAt;

  Driver({
    required this.id,
    required this.driverUserId,
    required this.fullName,
    this.profileImageUrl,
    required this.carModel,
    required this.carColor,
    required this.carPlateNumber,
    this.carYear,
    required this.rating,
    required this.numberOfRatings,
    required this.taxiOfficeId,
    required this.phone,
    required this.email,
    required this.earnings,
    required this.isAvailable,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.joinedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final userDetails = json['user'] as Map<String, dynamic>? ?? {};
    final carDetails = json['carDetails'] as Map<String, dynamic>? ?? {};

    return Driver(
      id: json['_id'] ?? '',
      driverUserId: userDetails['userId'] ?? 0, // ✅ صح
      fullName: userDetails['fullName'] ?? 'Unknown',
      profileImageUrl: json['profileImageUrl'],
      carModel: carDetails['model'] ?? 'N/A',
      carColor: carDetails['color'] ?? 'N/A',
      carPlateNumber: carDetails['plateNumber'] ?? 'N/A',
      carYear: carDetails['year'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (json['numberOfRatings'] as num?)?.toInt() ?? 0,
      taxiOfficeId: json['office']?.toString() ?? '',
      isAvailable: json['isAvailable'] ?? false,
      phone: userDetails['phone'] ?? 'N/A',
      email: userDetails['email'] ?? 'N/A',
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      licenseNumber: json['licenseNumber'] ?? 'N/A',
      licenseExpiry:
          DateTime.tryParse(json['licenseExpiry'] ?? '') ?? DateTime(2000),
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime(2000),
    );
  }
}
