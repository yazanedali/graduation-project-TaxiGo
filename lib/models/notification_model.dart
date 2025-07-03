class NotificationModel {
  final int notificationId;
  final int recipient;
  final String recipientType;
  final String title;
  final String message;
  final String type;
  final NotificationData? data;
  final String status;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.recipient,
    required this.recipientType,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.status,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'],
      recipient: json['recipient'],
      recipientType: json['recipientType'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      data:
          json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class NotificationData {
  final int? tripId;
  final double? amount;

  NotificationData({this.tripId, this.amount});

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      tripId: json['tripId'],
      amount: json['amount']?.toDouble(),
    );
  }
}
