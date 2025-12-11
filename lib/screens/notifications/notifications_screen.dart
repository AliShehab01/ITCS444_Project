import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  final bool isAdmin;

  const NotificationsScreen({
    super.key,
    required this.userId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: isAdmin ? Colors.purple[400] : Colors.green[400],
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.grey[850],
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await notificationService.markAllAsRead(
                  isAdmin ? 'admin' : userId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All marked as read')),
                  );
                }
              } else if (value == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text(
                      'Clear All Notifications?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This will delete all your notifications.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notificationService.clearAllNotifications(
                    isAdmin ? 'admin' : userId,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mark all as read',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Clear all', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: isAdmin
            ? notificationService.getAdminNotifications()
            : notificationService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          final unread = notifications.where((n) => !n.isRead).toList();
          final read = notifications.where((n) => n.isRead).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (unread.isNotEmpty) ...[
                _buildSectionHeader('New', unread.length),
                ...unread.map(
                  (n) => _NotificationCard(
                    notification: n,
                    onTap: () => _handleNotificationTap(context, n),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (read.isNotEmpty) ...[
                _buildSectionHeader('Earlier', read.length),
                ...read.map(
                  (n) => _NotificationCard(
                    notification: n,
                    onTap: () => _handleNotificationTap(context, n),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    final notificationService = NotificationService();

    // Mark as read
    if (!notification.isRead) {
      await notificationService.markAsRead(notification.id);
    }

    // TODO: Navigate to related screen based on notification type
    // For now, just show the full message
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            notification.title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            notification.message,
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? Colors.grey[850] : Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                              color: Colors.white,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.rentalApproaching:
        return Icons.schedule;
      case NotificationType.rentalOverdue:
        return Icons.warning;
      case NotificationType.rentalApproved:
        return Icons.check_circle;
      case NotificationType.rentalRejected:
        return Icons.cancel;
      case NotificationType.newDonation:
        return Icons.volunteer_activism;
      case NotificationType.donationApproved:
        return Icons.thumb_up;
      case NotificationType.donationRejected:
        return Icons.thumb_down;
      case NotificationType.maintenanceRequired:
        return Icons.build;
      case NotificationType.newRentalRequest:
        return Icons.shopping_cart;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.rentalApproaching:
        return Colors.orange;
      case NotificationType.rentalOverdue:
        return Colors.red;
      case NotificationType.rentalApproved:
        return Colors.green;
      case NotificationType.rentalRejected:
        return Colors.red;
      case NotificationType.newDonation:
        return Colors.orange;
      case NotificationType.donationApproved:
        return Colors.green;
      case NotificationType.donationRejected:
        return Colors.red;
      case NotificationType.maintenanceRequired:
        return Colors.yellow;
      case NotificationType.newRentalRequest:
        return Colors.blue;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
