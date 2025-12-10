import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_submission.dart';
import '../models/equipment_item.dart';
import 'notification_service.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'donations';
  final NotificationService _notificationService = NotificationService();

  // Submit a new donation
  Future<String> submitDonation(DonationSubmission donation) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(donation.id)
          .set(donation.toMap());

      // Notify admins about new donation
      await _notificationService.notifyNewDonation(
        donation.donorName,
        donation.itemName,
        donation.id,
      );

      return donation.id;
    } catch (e) {
      throw Exception('Failed to submit donation: $e');
    }
  }

  // Get all donations stream
  Stream<List<DonationSubmission>> getAllDonationsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DonationSubmission.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get pending donations stream
  Stream<List<DonationSubmission>> getPendingDonationsStream() {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: DonationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final donations = snapshot.docs
              .map((doc) => DonationSubmission.fromMap(doc.data()))
              .toList();
          // Sort in memory to avoid composite index requirement
          donations.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return donations;
        });
  }

  // Get donations by donor
  Stream<List<DonationSubmission>> getDonationsByDonor(String donorId) {
    return _firestore
        .collection(_collectionName)
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) {
          final donations = snapshot.docs
              .map((doc) => DonationSubmission.fromMap(doc.data()))
              .toList();
          // Sort in memory to avoid composite index requirement
          donations.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return donations;
        });
  }

  // Get donation by ID
  Future<DonationSubmission?> getDonationById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return DonationSubmission.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get donation: $e');
    }
  }

  // Approve donation and add to inventory
  Future<void> approveDonation(
    String donationId,
    String reviewerId,
    EquipmentItem equipment,
  ) async {
    try {
      // Get the donation first for notification
      final donationDoc = await _firestore.collection(_collectionName).doc(donationId).get();
      final donation = DonationSubmission.fromMap(donationDoc.data()!);

      final batch = _firestore.batch();

      // Update donation status
      batch.update(_firestore.collection(_collectionName).doc(donationId), {
        'status': DonationStatus.approved.name,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewerId,
      });

      // Add equipment to inventory
      batch.set(
        _firestore.collection('equipment').doc(equipment.id),
        equipment.toMap(),
      );

      await batch.commit();

      // Notify the donor
      await _notificationService.notifyDonationApproved(
        donation.donorId,
        donation.itemName,
      );
    } catch (e) {
      throw Exception('Failed to approve donation: $e');
    }
  }

  // Reject donation
  Future<void> rejectDonation(
    String donationId,
    String reviewerId,
    String reason,
  ) async {
    try {
      // Get the donation first for notification
      final donationDoc = await _firestore.collection(_collectionName).doc(donationId).get();
      final donation = DonationSubmission.fromMap(donationDoc.data()!);

      await _firestore.collection(_collectionName).doc(donationId).update({
        'status': DonationStatus.rejected.name,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewerId,
        'rejectionReason': reason,
      });

      // Notify the donor
      await _notificationService.notifyDonationRejected(
        donation.donorId,
        donation.itemName,
        reason,
      );
    } catch (e) {
      throw Exception('Failed to reject donation: $e');
    }
  }

  // Get donation statistics
  Future<Map<String, int>> getDonationStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();

      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        if (status == DonationStatus.pending.name) {
          pending++;
        } else if (status == DonationStatus.approved.name) {
          approved++;
        } else if (status == DonationStatus.rejected.name) {
          rejected++;
        }
      }

      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get donation statistics: $e');
    }
  }
}
