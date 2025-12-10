import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/rental_request.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Create a notification
  Future<void> createNotification(AppNotification notification) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final notificationWithId = AppNotification(
        id: docRef.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        relatedId: notification.relatedId,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
      );
      await docRef.set(notificationWithId.toMap());
    } catch (e) {
      throw 'Error creating notification: $e';
    }
  }

  // Get notifications for a user
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  // Get admin notifications (for all admins)
  Stream<List<AppNotification>> getAdminNotifications() {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: 'admin')
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  // Get unread count for a user
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get admin unread count
  Stream<int> getAdminUnreadCount() {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw 'Error marking notification as read: $e';
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw 'Error marking all notifications as read: $e';
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      throw 'Error deleting notification: $e';
    }
  }

  // Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw 'Error clearing notifications: $e';
    }
  }

  // ========== NOTIFICATION TRIGGERS ==========

  // Notify user when rental is approved
  Future<void> notifyRentalApproved(RentalRequest rental) async {
    await createNotification(AppNotification(
      id: '',
      userId: rental.renterId,
      type: NotificationType.rentalApproved,
      title: 'Rental Approved!',
      message: 'Your rental request for "${rental.itemName}" has been approved. Please pick it up on ${_formatDate(rental.startDate)}.',
      relatedId: rental.id,
      createdAt: DateTime.now(),
    ));
  }

  // Notify user when rental is rejected
  Future<void> notifyRentalRejected(RentalRequest rental, String? reason) async {
    await createNotification(AppNotification(
      id: '',
      userId: rental.renterId,
      type: NotificationType.rentalRejected,
      title: 'Rental Rejected',
      message: 'Your rental request for "${rental.itemName}" was rejected.${reason != null ? ' Reason: $reason' : ''}',
      relatedId: rental.id,
      createdAt: DateTime.now(),
    ));
  }

  // Notify admins about new rental request
  Future<void> notifyNewRentalRequest(RentalRequest rental) async {
    await createNotification(AppNotification(
      id: '',
      userId: 'admin',
      type: NotificationType.newRentalRequest,
      title: 'New Rental Request',
      message: '${rental.renterName} requested to rent "${rental.itemName}" from ${_formatDate(rental.startDate)} to ${_formatDate(rental.endDate)}.',
      relatedId: rental.id,
      createdAt: DateTime.now(),
    ));
  }

  // Notify user when return date is approaching (3 days before)
  Future<void> notifyReturnApproaching(RentalRequest rental) async {
    final daysLeft = rental.endDate.difference(DateTime.now()).inDays;
    await createNotification(AppNotification(
      id: '',
      userId: rental.renterId,
      type: NotificationType.rentalApproaching,
      title: 'Return Date Approaching',
      message: 'Your rental of "${rental.itemName}" is due in $daysLeft days (${_formatDate(rental.endDate)}). Please return it on time.',
      relatedId: rental.id,
      createdAt: DateTime.now(),
    ));
  }

  // Notify user and admin when rental is overdue
  Future<void> notifyRentalOverdue(RentalRequest rental) async {
    final daysOverdue = DateTime.now().difference(rental.endDate).inDays;
    
    // Notify user
    await createNotification(AppNotification(
      id: '',
      userId: rental.renterId,
      type: NotificationType.rentalOverdue,
      title: 'Rental Overdue!',
      message: 'Your rental of "${rental.itemName}" is $daysOverdue day(s) overdue. Please return it immediately.',
      relatedId: rental.id,
      createdAt: DateTime.now(),
    ));

    // Notify admins
    await createNotification(AppNotification(
      id: '',
      userId: 'admin',
      type: NotificationType.rentalOverdue,
      title: 'Overdue Rental Alert',
      message: '${rental.renterName}\'s rental of "${rental.itemName}" is $daysOverdue day(s) overdue.',
      relatedId: rental.id,
      createdAt: DateTime.now(),
    ));
  }

  // Notify admins about new donation submission
  Future<void> notifyNewDonation(String donorName, String itemName, String donationId) async {
    await createNotification(AppNotification(
      id: '',
      userId: 'admin',
      type: NotificationType.newDonation,
      title: 'New Donation Submitted',
      message: '$donorName has submitted a donation: "$itemName". Please review.',
      relatedId: donationId,
      createdAt: DateTime.now(),
    ));
  }

  // Notify donor when donation is approved
  Future<void> notifyDonationApproved(String donorId, String itemName) async {
    await createNotification(AppNotification(
      id: '',
      userId: donorId,
      type: NotificationType.donationApproved,
      title: 'Donation Approved!',
      message: 'Your donation "$itemName" has been approved and added to the inventory. Thank you for your generosity!',
      createdAt: DateTime.now(),
    ));
  }

  // Notify donor when donation is rejected
  Future<void> notifyDonationRejected(String donorId, String itemName, String? reason) async {
    await createNotification(AppNotification(
      id: '',
      userId: donorId,
      type: NotificationType.donationRejected,
      title: 'Donation Not Accepted',
      message: 'Unfortunately, your donation "$itemName" could not be accepted.${reason != null ? ' Reason: $reason' : ''}',
      createdAt: DateTime.now(),
    ));
  }

  // Notify admins about equipment requiring maintenance
  Future<void> notifyMaintenanceRequired(String itemName, String itemId) async {
    await createNotification(AppNotification(
      id: '',
      userId: 'admin',
      type: NotificationType.maintenanceRequired,
      title: 'Maintenance Required',
      message: '"$itemName" has been marked as requiring maintenance.',
      relatedId: itemId,
      createdAt: DateTime.now(),
    ));
  }

  // Check and create notifications for approaching/overdue rentals
  Future<void> checkRentalDueDates() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));

      // Get all checked out rentals
      final snapshot = await _firestore
          .collection('rentalRequests')
          .where('status', isEqualTo: RentalStatus.checkedOut.name)
          .get();

      for (final doc in snapshot.docs) {
        final rental = RentalRequest.fromMap(doc.data());
        final endDate = rental.endDate;

        // Check if overdue
        if (endDate.isBefore(now)) {
          // Check if we already sent an overdue notification today
          final existingNotification = await _firestore
              .collection(_collection)
              .where('relatedId', isEqualTo: rental.id)
              .where('type', isEqualTo: NotificationType.rentalOverdue.name)
              .get();

          if (existingNotification.docs.isEmpty) {
            await notifyRentalOverdue(rental);
          }
        }
        // Check if due within 3 days
        else if (endDate.isBefore(threeDaysFromNow) && endDate.isAfter(now)) {
          // Check if we already sent an approaching notification
          final existingNotification = await _firestore
              .collection(_collection)
              .where('relatedId', isEqualTo: rental.id)
              .where('type', isEqualTo: NotificationType.rentalApproaching.name)
              .get();

          if (existingNotification.docs.isEmpty) {
            await notifyReturnApproaching(rental);
          }
        }
      }
    } catch (e) {
      print('Error checking rental due dates: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
