import 'package:flutter/foundation.dart';

enum NotificationType {
  orderUpdate,
  promotion,
  feedback,
  newFeature,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final String? orderId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.orderId,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void initialize() {
    // In a real app, you would fetch this from a database or backend service
    _notifications.clear();

    // Add sample notifications
    _addNotification(
      title: 'Your order is ready for pickup!',
      message: 'Order #12345 is ready for pickup at TapEats restaurant.',
      type: NotificationType.orderUpdate,
      isRead: false,
      orderId: '12345',
    );

    _addNotification(
      title: 'Special discount for you!',
      message: 'Enjoy 20% off on your next order with code SPECIAL20.',
      type: NotificationType.promotion,
      isRead: false,
    );

    _addNotification(
      title: 'Order accepted by restaurant',
      message: 'Your order #12346 has been accepted and is being prepared.',
      type: NotificationType.orderUpdate,
      isRead: true,
      orderId: '12346',
    );

    _addNotification(
      title: 'Rate your last order',
      message:
          'How was your experience with order #12347? Tap to rate and review.',
      type: NotificationType.feedback,
      isRead: true,
      orderId: '12347',
    );

    _addNotification(
      title: 'New restaurant added!',
      message:
          'Check out the latest addition to TapEats - Spice Fusion is now available for orders.',
      type: NotificationType.newFeature,
      isRead: true,
    );

    _calculateUnreadCount();
    notifyListeners();
  }

  void _addNotification({
    required String title,
    required String message,
    required NotificationType type,
    required bool isRead,
    String? orderId,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _notifications.add(
      NotificationItem(
        id: id,
        title: title,
        message: message,
        timestamp: DateTime.now()
            .subtract(Duration(minutes: _notifications.length * 30)),
        type: type,
        isRead: isRead,
        orderId: orderId,
      ),
    );

    if (!isRead) {
      _unreadCount++;
    }
  }

  void addNewNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
  }) {
    _addNotification(
      title: title,
      message: message,
      type: type,
      isRead: false,
      orderId: orderId,
    );

    _calculateUnreadCount();
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index =
        _notifications.indexWhere((item) => item.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _calculateUnreadCount();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool updated = false;

    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        updated = true;
      }
    }

    if (updated) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((item) => !item.isRead).length;
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}
