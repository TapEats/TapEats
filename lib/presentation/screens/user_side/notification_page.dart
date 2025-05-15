import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/order_history_page.dart';
import 'package:tapeats/presentation/screens/user_side/status_page.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = false;
  List<NotificationItem> notifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      // In a real app, you would fetch notifications from your database
      // For now, we'll create sample notifications
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate network delay

      setState(() {
        notifications = [
          NotificationItem(
            id: '1',
            title: 'Your order is ready for pickup!',
            message: 'Order #12345 is ready for pickup at TapEats restaurant.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            type: NotificationType.orderUpdate,
            isRead: false,
            orderId: '12345',
          ),
          NotificationItem(
            id: '2',
            title: 'Special discount for you!',
            message: 'Enjoy 20% off on your next order with code SPECIAL20.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            type: NotificationType.promotion,
            isRead: false,
          ),
          NotificationItem(
            id: '3',
            title: 'Order accepted by restaurant',
            message:
                'Your order #12346 has been accepted and is being prepared.',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            type: NotificationType.orderUpdate,
            isRead: true,
            orderId: '12346',
          ),
          NotificationItem(
            id: '4',
            title: 'Rate your last order',
            message:
                'How was your experience with order #12347? Tap to rate and review.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            type: NotificationType.feedback,
            isRead: true,
            orderId: '12347',
          ),
          NotificationItem(
            id: '5',
            title: 'New restaurant added!',
            message:
                'Check out the latest addition to TapEats - Spice Fusion is now available for orders.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            type: NotificationType.newFeature,
            isRead: true,
          ),
        ];

        // Calculate unread count
        unreadCount =
            notifications.where((notification) => !notification.isRead).length;
      });
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notifications: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
      unreadCount = 0;
    });

    // In a real app, you would update this in your database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _markAsRead(NotificationItem notification) {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
        unreadCount--;
      });

      // In a real app, you would update this in your database
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    _markAsRead(notification);

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.orderUpdate:
        if (notification.orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StatusPage(orderId: notification.orderId!),
            ),
          );
        }
        break;
      case NotificationType.feedback:
        if (notification.orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderHistoryPage(cartItems: {}, totalItems: 0),
            ),
          );
        }
        break;
      case NotificationType.promotion:
      case NotificationType.newFeature:
        // Show details in a dialog
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            notification.title,
            style: const TextStyle(
              color: Color(0xFFEEEFEF),
              fontFamily: 'Helvetica Neue',
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: const TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Received: ${_formatDate(notification.timestamp)}',
                style: const TextStyle(
                  color: Color(0xFF8F8F8F),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFFD0F0C0),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Notifications',
              headingIcon: Iconsax.notification,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),
            _buildNotificationHeader(),
            const SizedBox(height: 15),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD0F0C0),
                      ),
                    )
                  : notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You have $unreadCount unread ${unreadCount == 1 ? 'notification' : 'notifications'}',
            style: const TextStyle(
              color: Color(0xFFEEEFEF),
              fontFamily: 'Helvetica Neue',
              fontSize: 16,
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  color: Color(0xFFD0F0C0),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.notification,
            size: 60,
            color: Color(0xFF8F8F8F),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Color(0xFFEEEFEF),
              fontFamily: 'Helvetica Neue',
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'We\'ll notify you when there\'s something new!',
            style: TextStyle(
              color: Color(0xFF8F8F8F),
              fontFamily: 'Helvetica Neue',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _fetchNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F0C0),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.isRead
              ? const Color(0xFF1A1A1A)
              : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(15),
          border: notification.isRead
              ? null
              : Border.all(color: const Color(0xFFD0F0C0), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: const Color(0xFFD0F0C0),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: const Color(0xFFEEEFEF),
                            fontFamily: 'Helvetica Neue',
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD0F0C0),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontFamily: 'Helvetica Neue',
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.timestamp),
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontFamily: 'Helvetica Neue',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Iconsax.box;
      case NotificationType.promotion:
        return Iconsax.discount_shape;
      case NotificationType.feedback:
        return Iconsax.star;
      case NotificationType.newFeature:
        return Iconsax.info_circle;
    }
  }
}

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
