import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  rentalApproaching, // Return date approaching (3 days before)
  rentalOverdue, // Rental is overdue
  rentalApproved, // Rental request approved
  rentalRejected, // Rental request rejected
  newDonation, // New donation submitted (for admins)
  donationApproved, // Donation approved (for donor)
  donationRejected, // Donation rejected (for donor)
  maintenanceRequired, // Equipment needs maintenance (for admins)
  newRentalRequest, // New rental request (for admins)
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.rentalApproaching:
        return 'Return Date Approaching';
      case NotificationType.rentalOverdue:
        return 'Rental Overdue';
      case NotificationType.rentalApproved:
        return 'Rental Approved';
      case NotificationType.rentalRejected:
        return 'Rental Rejected';
      case NotificationType.newDonation:
        return 'New Donation';
      case NotificationType.donationApproved:
        return 'Donation Approved';
      case NotificationType.donationRejected:
        return 'Donation Rejected';
      case NotificationType.maintenanceRequired:
        return 'Maintenance Required';
      case NotificationType.newRentalRequest:
        return 'New Rental Request';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.rentalApproaching:
        return 'schedule';
      case NotificationType.rentalOverdue:
        return 'warning';
      case NotificationType.rentalApproved:
        return 'check_circle';
      case NotificationType.rentalRejected:
        return 'cancel';
      case NotificationType.newDonation:
        return 'volunteer_activism';
      case NotificationType.donationApproved:
        return 'thumb_up';
      case NotificationType.donationRejected:
        return 'thumb_down';
      case NotificationType.maintenanceRequired:
        return 'build';
      case NotificationType.newRentalRequest:
        return 'shopping_cart';
    }
  }
}

class AppNotification {
  final String id;
  final String userId; // Target user (or 'admin' for all admins)
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedId; // Related rental/donation/equipment ID
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.rentalApproaching,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
