class Trip {
  final int tripId;
  final int userId;
  final int? driverId; // جعله اختياريًا
  final Location startLocation;
  final Location endLocation;
  final double distance;
  final double estimatedFare;
  final double actualFare; // تغيير من earnings إلى actualFare
  final String status;
  final DateTime requestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startTime; // جعله اختياريًا
  final DateTime? endTime; // جعله اختياريًا
  final DateTime? acceptedAt; // Added field for accepted time
  final String paymentMethod;
  final String? driverName;
  final String? userName;
  final DateTime? timeoutDuration; // 👈 الحقل الجديد

  Trip({
    required this.tripId,
    required this.userId,
    this.driverId,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.estimatedFare,
    required this.paymentMethod, // Initialize paymentMethod
    required this.actualFare,
    required this.status,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
    this.acceptedAt,
    this.driverName,
    this.userName,
    this.timeoutDuration, // 👈 إضافة الحقل هنا
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'] is int
          ? json['tripId']
          : int.tryParse(json['tripId']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      driverId: json['driverId'] is int
          ? json['driverId']
          : int.tryParse(json['driverId']?.toString() ?? ''),
      startLocation: Location.fromJson(
          json['startLocation'] is Map ? json['startLocation'] : {}),
      endLocation: Location.fromJson(
          json['endLocation'] is Map ? json['endLocation'] : {}),
      distance: (json['distance'] is num
              ? json['distance'].toDouble()
              : double.tryParse(json['distance']?.toString() ?? '0')) ??
          0.0,
      estimatedFare: (json['estimatedFare'] is num
              ? json['estimatedFare'].toDouble()
              : double.tryParse(json['estimatedFare']?.toString() ?? '0')) ??
          0.0,
      actualFare: (json['actualFare'] is num
              ? json['actualFare'].toDouble()
              : double.tryParse(json['actualFare']?.toString() ?? '0')) ??
          0.0,
      status: json['status']?.toString() ?? 'pending',
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime']?.toString() ?? '')
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime']?.toString() ?? '')
          : null,
      timeoutDuration: json['timeoutDuration'] != null
          ? DateTime.tryParse(json['timeoutDuration']?.toString() ?? '')
          : null, // 👈 معالجة الحقل الجديد
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      driverName: json['driverName']?.toString(),
      userName: json['userName']?.toString(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt']?.toString() ?? '')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'userId': userId,
      'driverId': driverId,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'distance': distance,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  // إذا كنت تفضل استخدام earnings كاسم بدلاً من actualFare
  double get earnings => actualFare;
}

class Location {
  final String address;
  final double longitude;
  final double latitude;

  Location({
    required this.address,
    required this.longitude,
    required this.latitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'],
      longitude: json['coordinates'][0],
      latitude: json['coordinates'][1],
    );
  }
}
