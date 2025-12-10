import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationStatus { pending, approved, rejected }

extension DonationStatusExtension on DonationStatus {
  String get displayName {
    switch (this) {
      case DonationStatus.pending:
        return 'Pending Review';
      case DonationStatus.approved:
        return 'Approved';
      case DonationStatus.rejected:
        return 'Rejected';
    }
  }
}

class DonationSubmission {
  final String id;
  final String donorId;
  final String donorName;
  final String donorEmail;
  final String donorContact;
  final String itemType;
  final String itemName;
  final String description;
  final String condition;
  final List<String> imageUrls;
  final int quantity;
  final String location;
  final DonationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;

  DonationSubmission({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.donorEmail,
    required this.donorContact,
    required this.itemType,
    required this.itemName,
    required this.description,
    required this.condition,
    required this.imageUrls,
    required this.quantity,
    required this.location,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'donorEmail': donorEmail,
      'donorContact': donorContact,
      'itemType': itemType,
      'itemName': itemName,
      'description': description,
      'condition': condition,
      'imageUrls': imageUrls,
      'quantity': quantity,
      'location': location,
      'status': status.name,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'notes': notes,
    };
  }

  factory DonationSubmission.fromMap(Map<String, dynamic> map) {
    return DonationSubmission(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      donorEmail: map['donorEmail'] ?? '',
      donorContact: map['donorContact'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      description: map['description'] ?? '',
      condition: map['condition'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      quantity: map['quantity'] ?? 1,
      location: map['location'] ?? '',
      status: DonationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DonationStatus.pending,
      ),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: map['reviewedBy'],
      rejectionReason: map['rejectionReason'],
      notes: map['notes'],
    );
  }
}
