class Message {
  final String id;
  final int sender;
  final int receiver;
  final String senderType;
  final String receiverType;
  final String message;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.senderType,
    required this.receiverType,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      sender: json['sender'] ?? 0,
      receiver: json['receiver'] ?? 0,
      senderType: json['senderType'] ?? '',
      receiverType: json['receiverType'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender,
      'receiver': receiver,
      'senderType': senderType,
      'receiverType': receiverType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 