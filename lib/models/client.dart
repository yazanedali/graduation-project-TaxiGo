class Client {
  final int userId;
  final String? profileImageUrl;
  final int tripsNumber;
  final double totalSpending;
  bool isAvailable;
  final String fullName;
  final String phone;
  final String email;

  Client({
    required this.userId,
    this.profileImageUrl,
    required this.tripsNumber,
    required this.totalSpending,
    required this.isAvailable,
    required this.fullName,
    required this.phone,
    required this.email,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final userDetails = json['user'] as Map<String, dynamic>?;

    return Client(
      userId: userDetails?['userId'] ?? json['clientUserId'] ?? 0,
      profileImageUrl: json['profileImageUrl'] as String?,
      tripsNumber: json['tripsnumber'] as int? ?? 0,
      totalSpending: (json['totalSpending'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] ?? false,
      fullName:
          userDetails?['fullName'] ?? json['fullName'] ?? 'Unknown Client',
      phone: userDetails?['phone'] ?? json['phone'] ?? 'N/A',
      email: userDetails?['email'] ?? json['email'] ?? 'N/A',
    );
  }
}
