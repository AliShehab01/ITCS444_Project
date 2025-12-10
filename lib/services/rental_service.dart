import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_request.dart';
import '../models/equipment_item.dart';
import 'equipment_service.dart';

class RentalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rentalRequests';
  final EquipmentService _equipmentService = EquipmentService();

  // Create rental request
  Future<String> createRentalRequest(RentalRequest request) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(request.toMap());
      await _firestore.collection(_collection).doc(docRef.id).update({
        'id': docRef.id,
      });

      // Update item status to reserved
      await _equipmentService.updateItemStatus(
        request.itemId,
        ItemStatus.reserved,
      );

      return docRef.id;
    } catch (e) {
      throw 'Error creating rental request: ${e.toString()}';
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
      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.approved.name,
        'approvedAt': Timestamp.now(),
      });
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
      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.rejected.name,
        'adminNotes': notes,
      });

      // Make item available again
      await _equipmentService.updateItemStatus(itemId, ItemStatus.available);
    } catch (e) {
      throw 'Error rejecting rental request: ${e.toString()}';
    }
  }

  // Check out item
  Future<void> checkOutItem(String requestId, String itemId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.checkedOut.name,
        'checkedOutAt': Timestamp.now(),
      });

      // Update item status to rented
      await _equipmentService.updateItemStatus(itemId, ItemStatus.rented);
    } catch (e) {
      throw 'Error checking out item: ${e.toString()}';
    }
  }

  // Return item
  Future<void> returnItem(String requestId, String itemId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': RentalStatus.returned.name,
        'returnedAt': Timestamp.now(),
      });

      // Update item status to available
      await _equipmentService.updateItemStatus(itemId, ItemStatus.available);
    } catch (e) {
      throw 'Error returning item: ${e.toString()}';
    }
  }

  // Get rental requests by renter
  Stream<List<RentalRequest>> getRentalsByRenter(String renterId) {
    return _firestore
        .collection(_collection)
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList(),
        );
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get active rentals (checked out)
  Stream<List<RentalRequest>> getActiveRentals() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: RentalStatus.checkedOut.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RentalRequest.fromMap(doc.data()))
              .toList(),
        );
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

      // Make item available again if it was reserved
      final rental = await getRentalById(requestId);
      if (rental?.status == RentalStatus.pending ||
          rental?.status == RentalStatus.approved) {
        await _equipmentService.updateItemStatus(itemId, ItemStatus.available);
      }
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
}
