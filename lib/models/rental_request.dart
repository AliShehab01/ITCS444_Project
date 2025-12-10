import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus {
  pending,
  approved,
  rejected,
  checkedOut,
  returned,
  overdue,
  cancelled,
}

class RentalRequest {
  final String id;
  final String itemId;
  final String itemName;
  final String renterId;
  final String renterName;
  final String renterContact;
  final DateTime startDate;
  final DateTime endDate;
  final RentalStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? checkedOutAt;
  final DateTime? returnedAt;
  final String? adminNotes;
  final String? renterNotes;
  final double? totalCost;
  final int durationDays;

  RentalRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.renterId,
    required this.renterName,
    required this.renterContact,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.checkedOutAt,
    this.returnedAt,
    this.adminNotes,
    this.renterNotes,
    this.totalCost,
    required this.durationDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'renterId': renterId,
      'renterName': renterName,
      'renterContact': renterContact,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'checkedOutAt': checkedOutAt != null
          ? Timestamp.fromDate(checkedOutAt!)
          : null,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'adminNotes': adminNotes,
      'renterNotes': renterNotes,
      'totalCost': totalCost,
      'durationDays': durationDays,
    };
  }

  factory RentalRequest.fromMap(Map<String, dynamic> map) {
    return RentalRequest(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      renterId: map['renterId'] ?? '',
      renterName: map['renterName'] ?? '',
      renterContact: map['renterContact'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: RentalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RentalStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      checkedOutAt: map['checkedOutAt'] != null
          ? (map['checkedOutAt'] as Timestamp).toDate()
          : null,
      returnedAt: map['returnedAt'] != null
          ? (map['returnedAt'] as Timestamp).toDate()
          : null,
      adminNotes: map['adminNotes'],
      renterNotes: map['renterNotes'],
      totalCost: map['totalCost']?.toDouble(),
      durationDays: map['durationDays'] ?? 0,
    );
  }

  RentalRequest copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? renterId,
    String? renterName,
    String? renterContact,
    DateTime? startDate,
    DateTime? endDate,
    RentalStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? checkedOutAt,
    DateTime? returnedAt,
    String? adminNotes,
    String? renterNotes,
    double? totalCost,
    int? durationDays,
  }) {
    return RentalRequest(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      renterContact: renterContact ?? this.renterContact,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      returnedAt: returnedAt ?? this.returnedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      renterNotes: renterNotes ?? this.renterNotes,
      totalCost: totalCost ?? this.totalCost,
      durationDays: durationDays ?? this.durationDays,
    );
  }

  bool get isOverdue {
    if (status == RentalStatus.checkedOut) {
      return DateTime.now().isAfter(endDate);
    }
    return false;
  }

  int get daysRemaining {
    if (status == RentalStatus.checkedOut) {
      return endDate.difference(DateTime.now()).inDays;
    }
    return 0;
  }
}

extension RentalStatusExtension on RentalStatus {
  String get displayName {
    switch (this) {
      case RentalStatus.pending:
        return 'Pending';
      case RentalStatus.approved:
        return 'Approved';
      case RentalStatus.rejected:
        return 'Rejected';
      case RentalStatus.checkedOut:
        return 'Checked Out';
      case RentalStatus.returned:
        return 'Returned';
      case RentalStatus.overdue:
        return 'Overdue';
      case RentalStatus.cancelled:
        return 'Cancelled';
    }
  }
}
