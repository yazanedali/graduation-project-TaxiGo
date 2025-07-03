import 'package:flutter/foundation.dart';
import 'package:taxi_app/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  int? _userId;
  String? _userType;

  void initialize(int userId, String userType) {
    _userId = userId;
    _userType = userType;
  }

  Future<void> fetchUnreadNotifications() async {
    try {
      _notifications =
          await NotificationService.getUnreadNotifications(_userId!);
      print('Fetched Notifications: $_notifications');
      _unreadCount = _notifications.length;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error fetching notifications: $e');
    }
  }

  Future<void> fetchAllNotifications(int userId) async {
    try {
      _notifications = await NotificationService.getAllNotifications(userId);
      _unreadCount =
          _notifications.where((n) => n['status'] == 'unread').length;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error fetching all notifications: $e');
    }
  }

  Future<void> markAsRead(int notificationId, int userid) async {
    try {
      print(notificationId);
      print(userid);
      bool success =
          await NotificationService.markAsRead(notificationId, userid);
      if (success) {
        await fetchAllNotifications(_userId!);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching notifications mark as read: $e');
    }
  }

  Future<void> fetchUnreadCount() async {
    if (_userId == null || _userType == null) return;
    try {
      _unreadCount =
          await NotificationService.getUnreadCount(_userId!, _userType!);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error fetching unread count: $e');
    }
  }
}
