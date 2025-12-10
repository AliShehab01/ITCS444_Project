import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCondition { excellent, good, fair, needsRepair }

enum ItemStatus { available, rented, donated, underMaintenance, reserved }

enum EquipmentType {
  wheelchair,
  walker,
  crutches,
  hospitalBed,
  oxygenMachine,
  commode,
  bathChair,
  ramp,
  liftChair,
  other,
}

class EquipmentItem {
  final String id;
  final String name;
  final EquipmentType type;
  final String description;
  final List<String> imageUrls;
  final ItemCondition condition;
  final int quantity;
  final String location;
  final List<String> tags;
  final ItemStatus status;
  final double? rentalPricePerDay;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDonated;

  EquipmentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.imageUrls,
    required this.condition,
    required this.quantity,
    required this.location,
    required this.tags,
    required this.status,
    this.rentalPricePerDay,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.updatedAt,
    this.isDonated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'imageUrls': imageUrls,
      'condition': condition.name,
      'quantity': quantity,
      'location': location,
      'tags': tags,
      'status': status.name,
      'rentalPricePerDay': rentalPricePerDay,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isDonated': isDonated,
    };
  }

  factory EquipmentItem.fromMap(Map<String, dynamic> map) {
    return EquipmentItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: EquipmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EquipmentType.other,
      ),
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      condition: ItemCondition.values.firstWhere(
        (e) => e.name == map['condition'],
        orElse: () => ItemCondition.good,
      ),
      quantity: map['quantity'] ?? 0,
      location: map['location'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.available,
      ),
      rentalPricePerDay: map['rentalPricePerDay']?.toDouble(),
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isDonated: map['isDonated'] ?? false,
    );
  }

  EquipmentItem copyWith({
    String? id,
    String? name,
    EquipmentType? type,
    String? description,
    List<String>? imageUrls,
    ItemCondition? condition,
    int? quantity,
    String? location,
    List<String>? tags,
    ItemStatus? status,
    double? rentalPricePerDay,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDonated,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      rentalPricePerDay: rentalPricePerDay ?? this.rentalPricePerDay,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDonated: isDonated ?? this.isDonated,
    );
  }
}

extension EquipmentTypeExtension on EquipmentType {
  String get displayName {
    switch (this) {
      case EquipmentType.wheelchair:
        return 'Wheelchair';
      case EquipmentType.walker:
        return 'Walker';
      case EquipmentType.crutches:
        return 'Crutches';
      case EquipmentType.hospitalBed:
        return 'Hospital Bed';
      case EquipmentType.oxygenMachine:
        return 'Oxygen Machine';
      case EquipmentType.commode:
        return 'Commode';
      case EquipmentType.bathChair:
        return 'Bath Chair';
      case EquipmentType.ramp:
        return 'Ramp';
      case EquipmentType.liftChair:
        return 'Lift Chair';
      case EquipmentType.other:
        return 'Other';
    }
  }
}

extension ItemConditionExtension on ItemCondition {
  String get displayName {
    switch (this) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.needsRepair:
        return 'Needs Repair';
    }
  }
}

extension ItemStatusExtension on ItemStatus {
  String get displayName {
    switch (this) {
      case ItemStatus.available:
        return 'Available';
      case ItemStatus.rented:
        return 'Rented';
      case ItemStatus.donated:
        return 'Donated';
      case ItemStatus.underMaintenance:
        return 'Under Maintenance';
      case ItemStatus.reserved:
        return 'Reserved';
    }
  }
}
