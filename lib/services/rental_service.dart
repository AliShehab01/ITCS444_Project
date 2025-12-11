import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/rental_request.dart';
import '../models/equipment_item.dart';
import '../models/app_notification.dart';
import 'equipment_service.dart';
import 'notification_service.dart';

class RentalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rentalRequests';
  final EquipmentService _equipmentService = EquipmentService();
  final NotificationService _notificationService = NotificationService();

  // Create rental request
  Future<String> createRentalRequest(RentalRequest request) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(request.toMap());
      await _firestore.collection(_collection).doc(docRef.id).update({
        'id': docRef.id,
      });

      // After creating rental, check if there are still available days in the next month
      // If fully booked, mark as reserved; otherwise keep available
      await _updateItemAvailabilityStatus(request.itemId);

      // Notify admins about new rental request
      final updatedRequest = request.copyWith(id: docRef.id);
      await _notificationService.notifyNewRentalRequest(updatedRequest);

      return docRef.id;
    } catch (e) {
      throw 'Error creating rental request: ${e.toString()}';
    }
  }

  // Check if item has available days in the next month and update status accordingly
  Future<void> _updateItemAvailabilityStatus(String itemId) async {
    try {
      final hasAvailableDays = await hasAvailableDaysInNextMonth(itemId);
      final item = await _equipmentService.getEquipmentById(itemId);
      
      if (item == null) return;
      
      // Only update if item is currently available or reserved (not rented/maintenance)
      if (item.status == ItemStatus.available || item.status == ItemStatus.reserved) {
        if (hasAvailableDays) {
          // There are still available days, keep/mark as available
          if (item.status != ItemStatus.available) {
            await _equipmentService.updateItemStatus(itemId, ItemStatus.available);
          }
        } else {
          // Fully booked for the next month, mark as reserved
          if (item.status != ItemStatus.reserved) {
            await _equipmentService.updateItemStatus(itemId, ItemStatus.reserved);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating item availability: $e');
    }
  }

  // Check if there are any available days in the next 30 days for an item
  Future<bool> hasAvailableDaysInNextMonth(String itemId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all reserved date ranges for this item
      final reservedRanges = await getReservedDatesForItem(itemId);
      
      // Check each day in the next 30 days
      for (int i = 0; i <= 30; i++) {
        final checkDate = today.add(Duration(days: i));
        bool isDayAvailable = true;
        
        for (var range in reservedRanges) {
          final rangeStart = DateTime(range.start.year, range.start.month, range.start.day);
          final rangeEnd = DateTime(range.end.year, range.end.month, range.end.day);
          
          // Check if this day falls within a reserved range
          if ((checkDate.isAtSameMomentAs(rangeStart) || checkDate.isAfter(rangeStart)) &&
              (checkDate.isAtSameMomentAs(rangeEnd) || checkDate.isBefore(rangeEnd))) {
            isDayAvailable = false;
            break;
          }
        }
        
        if (isDayAvailable) {
          return true; // Found at least one available day
        }
      }
      
      return false; // All days are reserved
    } catch (e) {
      debugPrint('Error checking available days: $e');
      return true; // Default to available on error
    }
  }

  // Update rental request
  Future<void> updateRentalRequest(RentalRequest request) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(request.id)
          .update(request.toMap());
    } catch (e) {
      throw 'Error updating rental request: ${e.toString()}';
    }
  }

  // Approve rental request
  Future<void> approveRentalRequest(String requestId) async {
    try {
      // Get the rental request first for notification
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      final rental = RentalRequest.fromMap(doc.data()!);

      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.approved.name,
        'approvedAt': Timestamp.now(),
      });

      // Notify the renter
      await _notificationService.notifyRentalApproved(rental);
    } catch (e) {
      throw 'Error approving rental request: ${e.toString()}';
    }
  }

  // Reject rental request
  Future<void> rejectRentalRequest(
    String requestId,
    String itemId,
    String? notes,
  ) async {
    try {
      // Get the rental request first for notification
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      final rental = RentalRequest.fromMap(doc.data()!);

      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.rejected.name,
        'adminNotes': notes,
      });

      // Re-check item availability after rejecting this rental
      await _updateItemAvailabilityStatus(itemId);

      // Notify the renter
      await _notificationService.notifyRentalRejected(rental, notes);
    } catch (e) {
      throw 'Error rejecting rental request: ${e.toString()}';
    }
  }

  // Check out item
  Future<void> checkOutItem(String requestId, String itemId) async {
    try {
      // Get the rental request for notification
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      final rental = RentalRequest.fromMap(doc.data()!);

      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.checkedOut.name,
        'checkedOutAt': Timestamp.now(),
      });

      // Update item status to rented
      await _equipmentService.updateItemStatus(itemId, ItemStatus.rented);

      // Notify the renter about pickup
      await _notificationService.createNotification(
        AppNotification(
          id: '',
          userId: rental.renterId,
          type: NotificationType.rentalApproved,
          title: 'Item Checked Out',
          message:
              'You have picked up "${rental.itemName}". Please return it by ${_formatDate(rental.endDate)}.',
          relatedId: rental.id,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw 'Error checking out item: ${e.toString()}';
    }
  }

  // Return item
  Future<void> returnItem(String requestId, String itemId) async {
    try {
      // Get the rental request for notification
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      final rental = RentalRequest.fromMap(doc.data()!);

      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.returned.name,
        'returnedAt': Timestamp.now(),
      });

      // Re-check item availability after return
      await _updateItemAvailabilityStatus(itemId);

      // Notify the renter about successful return
      await _notificationService.createNotification(
        AppNotification(
          id: '',
          userId: rental.renterId,
          type: NotificationType.rentalApproved,
          title: 'Item Returned',
          message:
              'You have successfully returned "${rental.itemName}". Thank you for using Complete Care Center!',
          relatedId: rental.id,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw 'Error returning item: ${e.toString()}';
    }
  }

  // Helper function to format date
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Check and update item statuses based on availability in the next month
  // Call this periodically to keep item statuses accurate
  Future<void> updateUpcomingReservationStatuses() async {
    try {
      // Get all items that are available or reserved
      final equipmentSnapshot = await _firestore.collection('equipment').get();
      
      for (var doc in equipmentSnapshot.docs) {
        final item = EquipmentItem.fromMap(doc.data());
        
        // Only check items that are available or reserved (not rented/maintenance)
        if (item.status == ItemStatus.available || item.status == ItemStatus.reserved) {
          await _updateItemAvailabilityStatus(item.id);
        }
      }
    } catch (e) {
      // Silently fail - this is a background task
      debugPrint('Error updating reservation statuses: $e');
    }
  }

  // Get rental requests by renter
  Stream<List<RentalRequest>> getRentalsByRenter(String renterId) {
    return _firestore
        .collection(_collection)
        .where('renterId', isEqualTo: renterId)
        .snapshots()
        .map((snapshot) {
          final rentals = snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList();
          rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rentals;
        });
  }

  // Get all rental requests
  Stream<List<RentalRequest>> getAllRentals() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get pending rental requests
  Stream<List<RentalRequest>> getPendingRentals() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: RentalStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final rentals = snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList();
          rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rentals;
        });
  }

  // Get active rentals (checked out)
  Stream<List<RentalRequest>> getActiveRentals() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: RentalStatus.checkedOut.name)
        .snapshots()
        .map((snapshot) {
          final rentals = snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList();
          rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rentals;
        });
  }

  // Get approved and active rentals (approved + checked out)
  Stream<List<RentalRequest>> getApprovedAndActiveRentals() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final rentals = snapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .where(
            (r) =>
                r.status == RentalStatus.approved ||
                r.status == RentalStatus.checkedOut,
          )
          .toList();
      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rentals;
    });
  }

  // Get overdue rentals
  Future<List<RentalRequest>> getOverdueRentals() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: RentalStatus.checkedOut.name)
          .get();

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .where((rental) => rental.endDate.isBefore(now))
          .toList();
    } catch (e) {
      throw 'Error getting overdue rentals: ${e.toString()}';
    }
  }

  // Get rental by ID
  Future<RentalRequest?> getRentalById(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (doc.exists) {
        return RentalRequest.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Error fetching rental: ${e.toString()}';
    }
  }

  // Cancel rental request
  Future<void> cancelRentalRequest(String requestId, String itemId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.cancelled.name,
      });

      // Re-check item availability after cancellation
      await _updateItemAvailabilityStatus(itemId);
    } catch (e) {
      throw 'Error cancelling rental request: ${e.toString()}';
    }
  }

  // Get rental statistics
  Future<Map<String, dynamic>> getRentalStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final rentals = snapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();

      int totalRentals = rentals.length;
      int activeRentals = rentals
          .where((r) => r.status == RentalStatus.checkedOut)
          .length;
      int pendingRentals = rentals
          .where((r) => r.status == RentalStatus.pending)
          .length;
      int completedRentals = rentals
          .where((r) => r.status == RentalStatus.returned)
          .length;

      final now = DateTime.now();
      int overdueRentals = rentals
          .where(
            (r) =>
                r.status == RentalStatus.checkedOut && r.endDate.isBefore(now),
          )
          .length;

      return {
        'total': totalRentals,
        'active': activeRentals,
        'pending': pendingRentals,
        'completed': completedRentals,
        'overdue': overdueRentals,
      };
    } catch (e) {
      throw 'Error getting rental statistics: ${e.toString()}';
    }
  }

  // Stream for rental statistics (real-time updates)
  Stream<Map<String, int>> getRentalStatisticsStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final rentals = snapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();

      final now = DateTime.now();
      return {
        'total': rentals.length,
        'active': rentals
            .where((r) => r.status == RentalStatus.checkedOut)
            .length,
        'pending': rentals
            .where((r) => r.status == RentalStatus.pending)
            .length,
        'completed': rentals
            .where((r) => r.status == RentalStatus.returned)
            .length,
        'overdue': rentals
            .where(
              (r) =>
                  r.status == RentalStatus.checkedOut &&
                  r.endDate.isBefore(now),
            )
            .length,
      };
    });
  }

  // Stream for user-specific rental statistics
  Stream<Map<String, int>> getUserRentalStatsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('renterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final rentals = snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList();

          return {
            'active': rentals
                .where(
                  (r) =>
                      r.status == RentalStatus.checkedOut ||
                      r.status == RentalStatus.approved ||
                      r.status == RentalStatus.pending,
                )
                .length,
            'completed': rentals
                .where((r) => r.status == RentalStatus.returned)
                .length,
          };
        });
  }

  // Get reserved date ranges for an item
  Future<List<DateTimeRange>> getReservedDatesForItem(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('itemId', isEqualTo: itemId)
          .get();

      final reservedRanges = <DateTimeRange>[];

      for (var doc in snapshot.docs) {
        final rental = RentalRequest.fromMap(doc.data());

        // Include pending, approved, and checked out rentals
        if (rental.status == RentalStatus.pending ||
            rental.status == RentalStatus.approved ||
            rental.status == RentalStatus.checkedOut) {
          reservedRanges.add(
            DateTimeRange(start: rental.startDate, end: rental.endDate),
          );
        }
      }

      return reservedRanges;
    } catch (e) {
      throw 'Error getting reserved dates: ${e.toString()}';
    }
  }

  // Check if date range conflicts with existing reservations
  Future<bool> isDateRangeAvailable(
    String itemId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final reservedDates = await getReservedDatesForItem(itemId);

      for (var reserved in reservedDates) {
        // Check for any overlap
        if (!(endDate.isBefore(reserved.start) ||
            startDate.isAfter(reserved.end))) {
          return false; // There's an overlap
        }
      }

      return true; // No conflicts
    } catch (e) {
      throw 'Error checking date availability: ${e.toString()}';
    }
  }

  // Get next available date for an item
  Future<DateTime> getNextAvailableDate(String itemId) async {
    try {
      final reservedDates = await getReservedDatesForItem(itemId);

      if (reservedDates.isEmpty) {
        return DateTime.now();
      }

      // Sort by start date
      reservedDates.sort((a, b) => a.start.compareTo(b.start));

      var nextDate = DateTime.now();

      for (var reserved in reservedDates) {
        if (nextDate.isBefore(reserved.start)) {
          return nextDate;
        }
        // Move to day after this reservation ends
        nextDate = reserved.end.add(const Duration(days: 1));
      }

      return nextDate;
    } catch (e) {
      throw 'Error getting next available date: ${e.toString()}';
    }
  }

  // Check for overdue and approaching rentals and send notifications
  // This should be called periodically (e.g., on app startup or daily)
  Future<void> checkAndSendRentalReminders() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: RentalStatus.checkedOut.name)
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var doc in snapshot.docs) {
        final rental = RentalRequest.fromMap(doc.data());
        final endDate = DateTime(
          rental.endDate.year,
          rental.endDate.month,
          rental.endDate.day,
        );

        final daysUntilDue = endDate.difference(today).inDays;

        if (daysUntilDue < 0) {
          // Overdue - notify both user and admin
          await _notificationService.notifyRentalOverdue(rental);
        } else if (daysUntilDue <= 3 && daysUntilDue >= 0) {
          // Approaching return date - notify user
          await _notificationService.notifyReturnApproaching(rental);
        }
      }
    } catch (e) {
      // Log error but don't throw - this is a background task
      debugPrint('Error checking rental reminders: $e');
    }
  }

  // Get overdue rentals stream (for real-time updates on admin dashboard)
  Stream<List<RentalRequest>> getOverdueRentalsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: RentalStatus.checkedOut.name)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          return snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .where((rental) {
                final endDate = DateTime(
                  rental.endDate.year,
                  rental.endDate.month,
                  rental.endDate.day,
                );
                return endDate.isBefore(today);
              })
              .toList();
        });
  }

  // Get rentals due soon (within 3 days)
  Stream<List<RentalRequest>> getRentalsDueSoon() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: RentalStatus.checkedOut.name)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final threeDaysFromNow = today.add(const Duration(days: 3));

          return snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .where((rental) {
                final endDate = DateTime(
                  rental.endDate.year,
                  rental.endDate.month,
                  rental.endDate.day,
                );
                return endDate.isAfter(
                      today.subtract(const Duration(days: 1)),
                    ) &&
                    endDate.isBefore(
                      threeDaysFromNow.add(const Duration(days: 1)),
                    );
              })
              .toList();
        });
  }
}
