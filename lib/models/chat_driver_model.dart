// lib/models/chat_driver_model.dart
class ChatDriver {
  final String id;
  final String driverUserId;
  final String fullName;
  final String? profileImageUrl;
  final bool isAvailable;
  final String? carModel;

  ChatDriver({
    required this.id,
    required this.driverUserId,
    required this.fullName,
    this.profileImageUrl,
    required this.isAvailable,
    this.carModel,
  });

  factory ChatDriver.fromJson(Map<String, dynamic> json) {
    return ChatDriver(
      id: json['_id'],
      driverUserId: json['driverUserId'].toString(),
      fullName: json['user']['fullName'],
      profileImageUrl: json['profileImageUrl'],
      isAvailable: json['isAvailable'] ?? false,
      carModel: json['carDetails']?['model'],
    );
  }
}